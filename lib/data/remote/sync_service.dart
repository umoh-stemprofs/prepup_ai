import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/connectivity_helper.dart';
import '../../data/local/database_helper.dart';

import '../../models/quiz_session.dart';
import '../../models/weak_area.dart';
import 'question_remote_repository.dart';
import 'session_remote_repository.dart';

/// Orchestrates offline-to-cloud sync for quiz results and question bank updates.
///
/// Phase 13.2 — flushPending():
///   - Runs only when authenticated AND online.
///   - For each queued result: insert quiz_sessions (id = session_uuid, ON CONFLICT
///     DO NOTHING), replace weak_area rows (delete-then-insert), remove local row
///     only after confirmed success.
///   - user_id attached at flush time from the current Supabase session.
///
/// Phase 12.1 — question bank sync:
///   - Fetches cloud questions and inserts any missing ones into local SQLite
///     (insert-missing-only, never overwrites local rows).
///
/// Guest rows stay queued — they are safe on-device (D6).

class SyncService extends ChangeNotifier {
  SyncService({
    SupabaseClient? client,
    DatabaseHelper? databaseHelper,
    ConnectivityHelper? connectivityHelper,
  }) : _client = client ?? Supabase.instance.client,
       _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       _connectivityHelper = connectivityHelper ?? ConnectivityHelper() {
    _questionRepo = QuestionRemoteRepository(_client);
    _sessionRepo = SessionRemoteRepository(_client);
    _init();
  }

  final SupabaseClient _client;
  final DatabaseHelper _databaseHelper;
  final ConnectivityHelper _connectivityHelper;

  late QuestionRemoteRepository _questionRepo;
  late SessionRemoteRepository _sessionRepo;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _lastError;
  String? get lastError => _lastError;

  bool get busy => _isSyncing;

  Future<bool> _isOnline() => _connectivityHelper.isOnline;

  String? get _userId => _client.auth.currentUser?.id;

  void _init() {
    _connectivityHelper.isOnlineStream.listen((online) {
      if (online && _userId != null) {
        flushPendingResults();
        syncQuestionBank();
      }
    });
  }

  /// Flushes all pending quiz result envelopes to the cloud.
  Future<void> flushPendingResults() async {
    if (_isSyncing) return;
    if (_userId == null) return;

    final online = await _isOnline();
    if (!online) return;

    _setSyncing(true);
    _clearError();

    try {
      final pending = await _databaseHelper.getPendingSyncResults(
        userId: _userId,
      );

      for (final envelope in pending) {
        final sessionUuid = envelope['session_uuid'] as String;
        final payloadRaw = envelope['payload'] as String;
        final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
        final session = QuizSession.fromJson(
          payload['session'] as Map<String, dynamic>,
        );
        final weakAreas = (payload['weak_areas'] as List<dynamic>?)
                ?.map((item) =>
                    WeakArea.fromJson(item as Map<String, dynamic>))
                .toList() ??
            <WeakArea>[];

        // Insert session (idempotent — upsert by id).
        final sessionOk = await _sessionRepo.insertSession(session, _userId!);
        if (!sessionOk) continue;

        // Replace weak areas (delete-then-insert for idempotent retry).
        final areasOk =
            await _sessionRepo.insertWeakAreas(sessionUuid, _userId!, weakAreas);
        if (!areasOk) continue;

        // Only remove the local queue row after confirmed cloud success.
        final db = await _databaseHelper.database;
        await db.delete(
          'pending_sync_results',
          where: 'session_uuid = ? AND user_id = ?',
          whereArgs: [sessionUuid, _userId],
        );
      }
    } catch (e) {
      _setError('Sync failed: ${e.toString()}');
    } finally {
      _setSyncing(false);
    }
  }

  /// Fetches cloud questions and inserts any missing ones into local SQLite.
  Future<void> syncQuestionBank() async {
    if (_isSyncing) return;
    if (_userId == null) return;

    final online = await _isOnline();
    if (!online) return;

    _setSyncing(true);
    _clearError();

    try {
      // Get the set of ids already cached locally.
      final db = await _databaseHelper.database;
      final localRows = await db.rawQuery('SELECT id FROM local_questions');
      final localIds = localRows.map((row) => row['id'] as String).toSet();

      // Fetch all cloud questions.
      final cloudQuestions = await _questionRepo.fetchAll();

      // Filter to questions not already cached.
      final newQuestions = cloudQuestions
          .where((q) => !localIds.contains(q.id))
          .toList();

      if (newQuestions.isEmpty) return;

      // Insert new questions into local SQLite in one batch.
      final batch = db.batch();
      for (final question in newQuestions) {
        batch.insert('local_questions', {
          'id': question.id,
          'subject': question.subject,
          'syllabus_topic': question.syllabusTopic,
          'question_text': question.questionText,
          'options': jsonEncode(question.options),
          'correct_option_index': question.correctOptionIndex,
          'explanation': question.explanation,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      _setError('Question sync failed: ${e.toString()}');
    } finally {
      _setSyncing(false);
    }
  }

  /// For use after sign-in — flushes pending results.
  Future<void> flushOnSignIn() => flushPendingResults();

  void _setSyncing(bool value) {
    if (_isSyncing == value) return;
    _isSyncing = value;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  void _setError(String message) {
    _lastError = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivityHelper.dispose();
    super.dispose();
  }
}
