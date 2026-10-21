import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/quiz_session.dart';
import '../../models/weak_area.dart';

/// Remote session repository (Phase 12.2).
///
/// Persists completed quiz sessions and their weak-area rows to the cloud
/// `quiz_sessions`/`session_weak_areas` tables, using the client-generated
/// `session_uuid` as the cloud `quiz_sessions.id` (idempotent — re-pushing
/// the same session is a no-op thanks to ON CONFLICT DO NOTHING).
///
/// All queries are user-scoped: [userId] comes from the current Supabase
/// session, never from UI input (D6 + RLS).

class SessionRemoteRepository {
  SessionRemoteRepository(this._client);

  final SupabaseClient _client;

  /// Inserts [session] into the cloud `quiz_sessions` table.
  ///
  /// Uses the session's `sessionUuid` as the cloud row `id`, so the same
  /// attempt pushed twice does not duplicate (ON CONFLICT DO NOTHING).
  /// [userId] must be the authenticated caller's Supabase user id.
  Future<bool> insertSession(QuizSession session, String userId) async {
    try {
      await _client.from('quiz_sessions').upsert(
        {
          'id': session.sessionUuid,
          'user_id': userId,
          'subject': session.subject,
          'score': session.score,
          'total_questions': session.totalQuestions,
          'score_percentage': session.scorePercentage,
          'is_pass': session.isPass,
          'time_spent_seconds': session.timeSpentSeconds,
          'completed_at': session.completedAt.toIso8601String(),
        },
        onConflict: 'id',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Inserts [areas] as `session_weak_areas` rows linked to [sessionUuid].
  ///
  /// Deletes existing rows for the same session first, then re-inserts — this
  /// makes the operation idempotent: pushing the same weak areas twice yields
  /// exactly the same rows (Phase 13.2 requirement).
  Future<bool> insertWeakAreas(
    String sessionUuid,
    String userId,
    List<WeakArea> areas,
  ) async {
    try {
      // Delete-then-insert for idempotent retry.
      await _client
          .from('session_weak_areas')
          .delete()
          .match({'session_id': sessionUuid, 'user_id': userId});

      if (areas.isEmpty) return true;

      await _client.from('session_weak_areas').insert(
        areas.map((area) => {
          'session_id': sessionUuid,
          'user_id': userId,
          'subject': area.subject,
          'syllabus_topic': area.syllabusTopic,
          'incorrect_count': area.incorrectCount,
          'total_count': area.totalCount,
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the cloud quiz_sessions for [userId], newest first.
  ///
  /// Used by the cloud history feature (future phase).
  Future<List<Map<String, dynamic>>> getSessionsForUser(String userId) async {
    try {
      return await _client
          .from('quiz_sessions')
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }
}
