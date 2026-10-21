import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote profile repository (Phase 12.3).
///
/// Fetches and updates the signed-in user's `profiles` row.
/// All operations are user-scoped via RLS + explicit user_id filtering.

class ProfileRemoteRepository {
  ProfileRemoteRepository(this._client);

  final SupabaseClient _client;

  /// Returns the current user's profile row, or null if none exists.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      return response as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Updates the current user's profile fields.
  /// [data] is a partial map — only supplied keys are updated.
  Future<bool> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _client.from('profiles').update(data).eq('id', userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
