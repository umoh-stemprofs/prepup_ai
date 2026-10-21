import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/question.dart';

/// Remote question repository (Phase 12.1).
///
/// Fetches the cloud question bank and merges it into the local SQLite cache
/// using insert-missing-only semantics: rows that already exist locally (by id)
/// are never overwritten, so a device's local edits or seed data are preserved.
///
/// No pagination is specified in the plan; the cloud table is small (≤ 100
/// questions) so a single select is fine. If the bank grows, add limit/offset
/// here.

class QuestionRemoteRepository {
  QuestionRemoteRepository(this._client);

  final SupabaseClient _client;

  /// Fetches all questions from the cloud and returns them as [Question] objects.
  ///
  /// Returns an empty list when the client is not authenticated or the network
  /// is unavailable — the caller (sync service) handles retry.
  Future<List<Question>> fetchAll() async {
    try {
      final response = await _client
          .from('questions')
          .select('id, subject, syllabus_topic, question_text, options, correct_option_index, explanation')
          .order('subject, syllabus_topic');

      if (response.isEmpty) return const <Question>[];

      return (response as List<Map<String, dynamic>>)
          .map((map) => Question.fromJson(_coerceJson(map)))
          .toList();
    } catch (e) {
      // Network or auth failure — caller retries later.
      return const <Question>[];
    }
  }



  /// Coerces a Supabase row map into the shape [Question.fromJson] expects.
  ///
  /// Supabase returns `options` as a List`dynamic` already decoded from jsonb,
  /// but [Question.fromJson] expects a List`String`. This adapter normalises.
  static Map<String, dynamic> _coerceJson(Map<String, dynamic> map) {
    final options = map['options'];
    if (options is! List) return map;

    return {
      ...map,
      'options': options.cast<String>(),
    };
  }

  /// Returns the question ids present in [questionsJson] (the cloud bank).
  ///
  /// Used by the sync service to filter out questions already cached locally.
  static Set<String> cloudQuestionIds(List<Map<String, dynamic>> questionsJson) {
    return questionsJson.map((row) => row['id'] as String).toSet();
  }
}
