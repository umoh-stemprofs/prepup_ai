import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guest-first authentication state for PrepUp AI.
///
/// The app boots as a guest. Real account features only escalate to a Supabase
/// session when the user explicitly signs in or signs up, and network or credential
/// failures never crash the local offline features.
enum AuthState {
  /// Guest mode: no Supabase session, local SQLite features active.
  unauthenticated,

  /// A sign-in / sign-up attempt is in flight.
  authenticating,

  /// A real Supabase session exists.
  authenticated,

  /// A recoverable auth error occurred; the UI can surface it.
  error,
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

/// Manages the guest-first auth flow.
///
/// Guest and signed-in users share the same Dashboard shell. [AuthState]
/// only reflects whether a Supabase session is active so the app knows local
/// SQLite offline mode is in use.
class AuthProvider extends ChangeNotifier {
  AuthProvider.guest() : _state = AuthState.unauthenticated;

  AuthState _state;
  AuthState get state => _state;

  String? get userId => _currentUser?.id;
  String? get email => _currentUser?.email;
  String? get displayName => _displayName;

  String? _lastError;
  String? get lastError => _lastError;

  bool get isGuest => _state == AuthState.unauthenticated;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isAuthenticating => _state == AuthState.authenticating;

  /// Explicitly enter guest mode without attempting a network call.
  void continueAsGuest() {
    _clearSessionState();
    _setState(AuthState.unauthenticated);
  }

  /// Sign in with email and password.
  ///
  /// Gracefully returns an [AuthException] on failure without crashing local
  /// features. Offline and server errors are treated the same way: the app
  /// remains usable in guest mode.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (isAuthenticating) {
      throw const AuthException('A sign-in attempt is already in progress.');
    }

    _setState(AuthState.authenticating);
    _clearUserInfo();
    _clearError();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        _setState(AuthState.error);
        _setError('Sign-in did not return a user.');
        return;
      }

      _currentUser = user;
      _displayName = _extractDisplayName(user);
      _setState(AuthState.authenticated);
    } on AuthException {
      rethrow;
    } catch (e) {
      _setState(AuthState.error);
      _setError(_normalizeErrorMessage(e));
    }
  }

  /// Sign up with email, password, and full name.
  ///
  /// Sends [fullName] through user metadata so the server-side signup trigger
  /// can populate [public.profiles] if configured.
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (isAuthenticating) {
      throw const AuthException('An account creation attempt is already in progress.');
    }

    _setState(AuthState.authenticating);
    _clearUserInfo();
    _clearError();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user;
      if (user == null) {
        // signUp can return a session/url for email confirmation without a
        // local user on some flows. Treat the lack of a user as informational,
        // not fatal, but still report the current state to the UI.
        _setState(AuthState.error);
        _setError('Account created request was sent, but no session was returned yet.');
        return;
      }

      _currentUser = user;
      _displayName = fullName;
      _setState(AuthState.authenticated);
    } on AuthException {
      rethrow;
    } catch (e) {
      _setState(AuthState.error);
      _setError(_normalizeErrorMessage(e));
    }
  }

  /// Sign out and return to guest mode.
  Future<void> signOut() async {
    _setState(AuthState.authenticating);

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Best-effort sign out. If the network is down or the session is already
      // gone, fall back to guest mode instead of failing.
    } finally {
      _clearSessionState();
      _setState(AuthState.unauthenticated);
    }
  }

  void _setState(AuthState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  User? _currentUser;
  String? _displayName;

  void _clearUserInfo() {
    _currentUser = null;
    _displayName = null;
  }

  void _clearSessionState() {
    _clearUserInfo();
    _clearError();
  }

  void _clearError() {
    _lastError = null;
  }

  void _setError(String message) {
    _lastError = message;
  }

  String? _extractDisplayName(User user) {
    final metadata = user.userMetadata;
    if (metadata != null && metadata.containsKey('full_name')) {
      final value = metadata['full_name'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _normalizeErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('network') || text.contains('NetworkError')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (text.contains('invalid_login') || text.contains('Invalid login')) {
      return 'Wrong email or password. Try again.';
    }
    if (text.contains('invalid_email') || text.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    }
    // Fall back to a readable message stripped of internal noise.
    return _stripStackTrace(text);
  }

  String _stripStackTrace(String text) {
    final lines = text.split('\n');
    // Keep the first meaningful line and drop stack traces.
    final first = lines.first.trim();
    if (first.isNotEmpty) {
      return first;
    }
    return 'An authentication error occurred. Please try again.';
  }
}
