/// PrepUp AI — remote storage for bookmarked STEM careers (Phase 09).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/saved_career.dart';

/// Cloud write surface for saved careers.
///
/// Kept behind an interface so the sync queue can be tested without a live
/// Supabase project.
abstract class CareerRemoteStore {
  /// Inserts or updates the row for [career], scoped to [userId].
  Future<void> upsert({required String userId, required SavedCareer career});

  /// Removes the row for [careerTitle], scoped to [userId].
  Future<void> delete({required String userId, required String careerTitle});
}

/// Supabase-backed [CareerRemoteStore].
///
/// Writes to `public.saved_careers` (migration 0003). `career_requests` is the
/// AI career-advisor rate limiter and is deliberately not used here.
class SupabaseCareerStore implements CareerRemoteStore {
  SupabaseCareerStore({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Table created by `supabase/migrations/0003_saved_careers.sql`.
  static const String table = 'saved_careers';

  @override
  Future<void> upsert({
    required String userId,
    required SavedCareer career,
  }) async {
    await _client.from(table).upsert({
      'user_id': userId,
      'career_title': career.careerTitle,
      'summary': career.summary,
      'required_subjects': career.requiredSubjects,
      'match_percentage': career.matchPercentage,
      'saved_at': career.savedAt.toUtc().toIso8601String(),
    }, onConflict: 'user_id,career_title');
  }

  @override
  Future<void> delete({
    required String userId,
    required String careerTitle,
  }) async {
    await _client
        .from(table)
        .delete()
        .eq('user_id', userId)
        .eq('career_title', careerTitle);
  }
}
