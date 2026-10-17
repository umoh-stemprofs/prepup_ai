import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/pending_career_sync.dart';
import '../../models/quiz_session.dart';
import '../../models/saved_career.dart';
import '../../models/weak_area.dart';

/// Singleton SQLite helper for the local offline cache.
///
/// This class is intentionally kept on the data side only; it knows how to
/// create the offline schema and seed from the asset SSOT, but it does not
/// import UI or service-layer code.
class DatabaseHelper {
  DatabaseHelper._();

  static DatabaseHelper? _instance;
  static Database? _database;

  /// The canonical asset path for the question SSOT.
  static const _questionsAssetPath = 'assets/questions.json';

  /// Overrides the on-disk database filename.
  ///
  /// `flutter test` runs test files concurrently, and every file that opens
  /// this helper would otherwise share one SQLite file, which surfaces as
  /// `SqliteException(5): database is locked`. Each test file sets a unique
  /// name here so parallel suites never contend for the same file.
  static String? debugDatabaseFileName;

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// The open database, lazily created on first access.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Disposes the cached database instance.
  ///
  /// Mostly useful in tests; in production the database normally lives for
  /// the lifetime of the app.
  Future<void> dispose() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await db.close();
    }
  }

  /// Opens the SQLite database, creating the offline schema on first launch.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, debugDatabaseFileName ?? 'prepup_ai_local.db');

    return openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Current offline schema version.
  ///
  /// v1 introduced the question/session/weak-area cache; v2 added saved
  /// career bookmarks; v3 added the career sync queue; v4 scoped that queue to
  /// a user account.
  static const int _schemaVersion = 4;

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSavedCareersTable(db);
    }
    if (oldVersion < 3) {
      await _createPendingCareerSyncTable(db);
    }
    if (oldVersion < 4) {
      await _scopePendingCareerSyncToUser(db);
      await _addResultQueueOwner(db);
    }
  }

  /// Records who a queued result belongs to (schema v4).
  ///
  /// Existing rows keep an empty owner: they were written before accounts were
  /// tracked, so they are treated as unsyncable rather than risk uploading a
  /// guest attempt into the next account that signs in.
  Future<void> _addResultQueueOwner(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(pending_sync_results)',
    );
    final hasUserId = columns.any((column) => column['name'] == 'user_id');
    if (!hasUserId) {
      await db.execute(
        "ALTER TABLE pending_sync_results "
        "ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Keep foreign keys enabled inside the local cache, even though we do
    // not currently model every FK at the SQLite level.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_questions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        syllabus_topic TEXT NOT NULL,
        question_text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_option_index INTEGER NOT NULL,
        explanation TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_quiz_sessions (
        session_uuid TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        score_percentage REAL NOT NULL,
        is_pass INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_weak_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_uuid TEXT NOT NULL,
        subject TEXT NOT NULL,
        syllabus_topic TEXT NOT NULL,
        incorrect_count INTEGER NOT NULL,
        total_count INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sync_results (
        session_uuid TEXT PRIMARY KEY,
        user_id TEXT NOT NULL DEFAULT '',
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createSavedCareersTable(db);
    await _createPendingCareerSyncTable(db);
  }

  /// Saved career bookmarks (schema v2).
  ///
  /// [career_title] is UNIQUE so re-saving the same role refreshes the row
  /// instead of piling up duplicates.
  Future<void> _createSavedCareersTable(Database db) async {
    await db.execute('''
      CREATE TABLE saved_careers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        career_title TEXT NOT NULL UNIQUE,
        summary TEXT NOT NULL,
        required_subjects TEXT NOT NULL,
        match_percentage INTEGER NOT NULL,
        saved_at TEXT NOT NULL
      )
    ''');
  }

  /// If [local_questions] is empty, read the asset SSOT and batch-insert all
  /// seed questions.
  ///
  /// This keeps the local cache consistent with [assets/questions.json]
  /// without requiring network access or the Supabase schema to exist.
  Future<void> seedQuestionsFromAssetsIfEmpty() async {
    final db = await database;

    final existing = await db.rawQuery(
      'SELECT id FROM local_questions LIMIT 1',
    );
    if (existing.isNotEmpty) {
      return;
    }

    final jsonText = await rootBundle.loadString(_questionsAssetPath);
    final parsed = jsonDecode(jsonText) as List<dynamic>;
    if (parsed.isEmpty) {
      return;
    }

    final batch = db.batch();
    for (final item in parsed) {
      final map = item as Map<dynamic, dynamic>;
      batch.insert('local_questions', {
        'id': map['id'],
        'subject': map['subject'],
        'syllabus_topic': map['syllabus_topic'],
        'question_text': map['question_text'],
        'options': jsonEncode(map['options']),
        'correct_option_index': map['correct_option_index'],
        'explanation': map['explanation'],
      });
    }
    await batch.commit(noResult: true);
  }

  /// Returns the number of cached questions.
  Future<int> getQuestionCount() async {
    final db = await database;
    final row = await db.rawQuery('SELECT COUNT(*) AS c FROM local_questions');
    return (row.first['c'] as int?) ?? 0;
  }

  /// Persists a completed [QuizSession] row into [local_quiz_sessions].
  ///
  /// Uses `INSERT OR REPLACE` so re-enqueuing the same session UUID upserts
  /// instead of throwing a primary-key conflict.
  ///
  /// sqflite does not accept Dart [bool] values, so [isPass] is stored as
  /// 1/0 to match the INTEGER column.
  Future<void> saveQuizSession(QuizSession session) async {
    final db = await database;
    await db.insert('local_quiz_sessions', {
      ...session.toMap(),
      'is_pass': session.isPass ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Persists [areas] as the weak areas of [sessionUuid].
  Future<void> saveWeakAreas(String sessionUuid, List<WeakArea> areas) async {
    final db = await database;
    final batch = db.batch();
    for (final area in areas) {
      batch.insert('local_weak_areas', {
        ...area.toMap(),
        'session_uuid': sessionUuid,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Returns all recorded weak-area rows, most recent first.
  Future<List<WeakArea>> getWeakAreas() async {
    final db = await database;
    final rows = await db.query('local_weak_areas', orderBy: 'id DESC');
    return rows.map((row) => WeakArea.fromMap(row)).toList();
  }

  /// Persists a bookmarked career, replacing any earlier bookmark for the
  /// same role so a re-save just refreshes its score and timestamp.
  Future<void> saveSavedCareer(SavedCareer career) async {
    final db = await database;
    await db.insert(
      'saved_careers',
      career.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns bookmarked careers, newest first.
  Future<List<SavedCareer>> getSavedCareers() async {
    final db = await database;
    final rows = await db.query('saved_careers', orderBy: 'saved_at DESC');
    return rows.map((row) => SavedCareer.fromMap(row)).toList();
  }

  /// Removes a bookmark by its row id.
  Future<void> deleteSavedCareer(int id) async {
    final db = await database;
    await db.delete('saved_careers', where: 'id = ?', whereArgs: [id]);
  }

  /// Queued cloud writes for bookmarks (schema v3, user-scoped in v4).
  ///
  /// ([user_id], `career_title`) is the primary key: queuing the same role
  /// again replaces the earlier operation, coalescing save/delete churn into
  /// one write, while separate accounts never share a row.
  Future<void> _createPendingCareerSyncTable(Database db) async {
    await db.execute('''
      CREATE TABLE pending_career_sync (
        user_id TEXT NOT NULL,
        career_title TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        queued_at TEXT NOT NULL,
        PRIMARY KEY (user_id, career_title)
      )
    ''');
  }

  /// Adds `user_id` to the career queue (schema v4).
  ///
  /// Rows written before v4 carry no account, so they cannot be attributed
  /// safely: flushing one could write a guest's bookmark into whoever signs in
  /// next. They are dropped. Nothing user-visible is lost — the bookmark itself
  /// still lives in `saved_careers`, and the next edit re-queues it against the
  /// account that made the change.
  Future<void> _scopePendingCareerSyncToUser(Database db) async {
    final rows = await db.query('pending_career_sync');
    await db.execute('DROP TABLE IF EXISTS pending_career_sync');
    await _createPendingCareerSyncTable(db);

    for (final row in rows) {
      final userId = row['user_id'] as String?;
      if (userId == null || userId.isEmpty) continue;
      await db.insert('pending_career_sync', <String, Object?>{
        ...row,
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Queues a cloud write, replacing any pending operation for the same role
  /// in the same account's queue.
  Future<void> queueCareerSync(PendingCareerSync operation) async {
    if (operation.userId.isEmpty) {
      // A queue row with no account would be flushed to whoever signs in next.
      throw ArgumentError.value(
        operation.userId,
        'userId',
        'Queued career writes must belong to a signed-in user.',
      );
    }
    final db = await database;
    await db.insert(
      'pending_career_sync',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns [userId]'s queued cloud writes, oldest first.
  Future<List<PendingCareerSync>> getPendingCareerSync({
    required String userId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'pending_career_sync',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'queued_at ASC',
    );
    return rows.map((row) => PendingCareerSync.fromMap(row)).toList();
  }

  /// Removes one of [userId]'s queued operations once the cloud accepted it.
  Future<void> clearPendingCareerSync(
    String careerTitle, {
    required String userId,
  }) async {
    final db = await database;
    await db.delete(
      'pending_career_sync',
      where: 'user_id = ? AND career_title = ?',
      whereArgs: [userId, careerTitle],
    );
  }

  /// Number of cloud writes still waiting to be flushed.
  ///
  /// Pass [userId] to count one account's queue; omit it for the whole device.
  Future<int> pendingCareerSyncCount({String? userId}) async {
    final db = await database;
    final row = userId == null
        ? await db.rawQuery('SELECT COUNT(*) AS c FROM pending_career_sync')
        : await db.rawQuery(
            'SELECT COUNT(*) AS c FROM pending_career_sync WHERE user_id = ?',
            [userId],
          );
    return (row.first['c'] as int?) ?? 0;
  }

  /// Enqueues the sync envelope for a finished attempt (Phase 10.4 / AM-3).
  ///
  /// The payload is self-contained — session plus its weak areas — so the
  /// future flusher never needs to re-query anything. [sessionUuid] is the
  /// primary key, so re-enqueueing the same attempt upserts instead of
  /// duplicating it (AM-3).
  ///
  /// Guest attempts are not queued: a row with no owner would be uploaded under
  /// whoever signs in next. They stay in [local_quiz_sessions] for history.
  Future<void> enqueuePendingSyncResult(
    QuizSession session, {
    required List<WeakArea> weakAreas,
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      return;
    }

    final db = await database;
    await db.insert('pending_sync_results', <String, Object?>{
      'session_uuid': session.sessionUuid,
      'user_id': userId,
      'payload': jsonEncode(<String, Object?>{
        'session': session.toJson(),
        'weak_areas': weakAreas.map((area) => area.toJson()).toList(),
      }),
      'created_at': session.completedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns queued result envelopes, oldest first, optionally for one account.
  Future<List<Map<String, Object?>>> getPendingSyncResults({
    String? userId,
  }) async {
    final db = await database;
    return db.query(
      'pending_sync_results',
      where: userId == null ? null : 'user_id = ?',
      whereArgs: userId == null ? null : [userId],
      orderBy: 'created_at ASC',
    );
  }

  /// Number of result envelopes still waiting to be uploaded.
  Future<int> pendingSyncResultCount({String? userId}) async {
    final db = await database;
    final row = userId == null
        ? await db.rawQuery('SELECT COUNT(*) AS c FROM pending_sync_results')
        : await db.rawQuery(
            'SELECT COUNT(*) AS c FROM pending_sync_results WHERE user_id = ?',
            [userId],
          );
    return (row.first['c'] as int?) ?? 0;
  }

  /// Local quiz history, newest first — the results screen's read path.
  Future<List<QuizSession>> getRecentSessions({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'local_quiz_sessions',
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return rows.map((row) => QuizSession.fromMap(row)).toList();
  }

  /// Aggregates weak-area rows into per-syllabus-topic summaries.
  ///
  /// Groups by [syllabus_topic] and sums incorrect/total counts so the UI can
  /// categorize each topic without showing every raw session row.
  Future<List<WeakArea>> getAggregatedWeakAreas() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        subject,
        syllabus_topic,
        SUM(incorrect_count) AS incorrect_count,
        SUM(total_count) AS total_count
      FROM local_weak_areas
      GROUP BY subject, syllabus_topic
      ORDER BY
        CAST(SUM(incorrect_count) AS REAL) /
          NULLIF(SUM(total_count), 0) DESC
    ''');
    return rows.map((row) => WeakArea.fromMap(row)).toList();
  }
}
