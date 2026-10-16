import 'package:flutter/foundation.dart';

/// Guest-first auth state (Phase 02 foundation, fleshed out in Phase 07).
///
/// The app boots as a guest: no Supabase keys and no sign-in are required to
/// reach the home screen. [requireSignIn] is the single hook future features
/// (Sync, Cloud History, AI Advisor) call to escalate into a real account.
class AuthProvider extends ChangeNotifier {
  /// Creates the app in guest mode — the default boot state.
  AuthProvider.guest() : _isGuest = true;

  bool _isGuest;
  String? _userId;
  String? _displayName;

  /// True when nobody is signed in (app boots in this state).
  bool get isGuest => _isGuest;

  /// True when a real Supabase session exists.
  bool get isSignedIn => !_isGuest;

  /// Supabase user id, null for guests.
  String? get userId => _userId;

  /// Display name, null for guests.
  String? get displayName => _displayName;

  /// Guests never block app usage: returns `false` today and will launch the
  /// auth flow in Phase 07. Features must fall back to local-only behaviour.
  bool requireSignIn(String reason) {
    debugPrint('requireSignIn ignored while guest-first (reason: $reason)');
    return false;
  }

  /// Leaves any signed-in session and returns to guest mode.
  void signOut() {
    _isGuest = true;
    _userId = null;
    _displayName = null;
    notifyListeners();
  }
}
