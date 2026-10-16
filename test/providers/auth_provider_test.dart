import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/providers/auth_provider.dart';

Matcher isNonEmptyString = isA<String>().having((s) => s.length, 'length', greaterThan(0));

void main() {
  group('AuthProvider', () {
    test('default boot state is guest / AuthState.unauthenticated', () {
      final provider = AuthProvider.guest();

      expect(provider.state, AuthState.unauthenticated);
      expect(provider.isGuest, isTrue);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isAuthenticating, isFalse);
      expect(provider.userId, isNull);
      expect(provider.email, isNull);
      expect(provider.displayName, isNull);
      expect(provider.lastError, isNull);
    });

    test('continueAsGuest leaves the provider in guest state', () {
      final provider = AuthProvider.guest();

      provider.continueAsGuest();

      expect(provider.state, AuthState.unauthenticated);
      expect(provider.isGuest, isTrue);
      expect(provider.lastError, isNull);
    });

    test('auth failure path surfaces AuthState.error with a readable message '
        'without crashing', () async {
      final provider = AuthProvider.guest();

      // Attempt a sign-in when no Supabase client is configured. The provider
      // must never crash local features: it should move through
      // AuthState.authenticating and land on AuthState.error with a readable
      // message instead of throwing.
      await expectLater(
        provider.signInWithEmailAndPassword(
          email: 'test@student.com',
          password: 'password',
        ),
        completes,
      );

      expect(provider.state, AuthState.error);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isAuthenticating, isFalse);
      expect(provider.lastError, isNotNull);
      expect(provider.lastError!, isNonEmptyString);
    });
  });

  group('AuthException', () {
    test('carries a readable message', () {
      const exception = AuthException('Wrong email or password. Try again.');

      expect(exception.message, isNonEmptyString);
      expect(exception.toString(), contains('AuthException'));
      expect(exception.toString(), contains('Wrong email or password'));
    });
  });
}
