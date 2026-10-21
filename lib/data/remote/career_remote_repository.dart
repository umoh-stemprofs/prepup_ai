import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote career repository (Phase 12.4).
///
/// Invokes the `career-advisor` Supabase Edge Function (deployed in Phase 15)
/// to get AI-powered career recommendations based on the student's preferences.
///
/// Maps 401 (unauthenticated), 429 (rate limited), and 5xx (server error) to
/// friendly error states. The function itself is deployed separately.

class CareerRemoteRepository {
  CareerRemoteRepository(this._client);

  final SupabaseClient _client;

  /// Invokes the `career-advisor` Edge Function with the student's preferences.
  ///
  /// Returns the parsed JSON result, or throws [CareerApiException] on failure.
  ///
  /// [preferences] is a map of the 5 preference inputs:
  ///   - workEnvironment: 'indoor' | 'outdoor'
  ///   - activityPreference: 'solvingMath' | 'building' | ...
  ///   - favoriteSubjects: List(string)
  ///   - (any other fields the function expects)
  Future<Map<String, dynamic>> getCareerMatch(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'career-advisor',
        body: preferences,
      );
      return response as Map<String, dynamic>;
    } on Exception catch (e) {
      final message = e.toString();
      if (message.contains('401')) {
        throw CareerApiException(
          'Sign in to use the AI Career Advisor.',
          isUnauthorized: true,
        );
      }
      if (message.contains('429')) {
        throw CareerApiException(
          'You have reached the daily limit for career recommendations. '
          'Try again tomorrow.',
          isRateLimited: true,
        );
      }
      if (message.contains('502') || message.contains('500')) {
        throw CareerApiException(
          'The career advisor is temporarily unavailable. Please try again.',
        );
      }
      throw CareerApiException(
        'Could not get career recommendations. Please try again.',
      );
    }
  }
}

class CareerApiException implements Exception {
  const CareerApiException(
    this.message, {
    this.isUnauthorized = false,
    this.isRateLimited = false,
  });

  final String message;
  final bool isUnauthorized;
  final bool isRateLimited;

  @override
  String toString() => 'CareerApiException: $message';
}
