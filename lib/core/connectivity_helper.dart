import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [connectivity_plus] to expose an [isOnline] stream.
///
/// Treated as a hint, not a guarantee — a "connected" state does not promise
/// that a particular API call will succeed, and a "disconnected" state does not
/// prevent retries that may succeed later. The sync service falls through to
/// retry on failure regardless (Phase 13.2).

class ConnectivityHelper {
  ConnectivityHelper() {
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  final _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Stream<bool> get isOnlineStream => _controller.stream;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    _controller.add(!result.contains(ConnectivityResult.none));
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
