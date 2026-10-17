import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/career_provider.dart';
import 'constants.dart';

/// Retries queued career saves when the device comes back online or the app
/// returns to the foreground.
///
/// Deliberately does not flush on init: that first frame is a hot path, and a
/// pending queue is only ever created by an explicit save.
class CareerSyncLifecycle extends StatefulWidget {
  const CareerSyncLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<CareerSyncLifecycle> createState() => _CareerSyncLifecycleState();
}

class _CareerSyncLifecycleState extends State<CareerSyncLifecycle>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForConnectivity();
  }

  void _listenForConnectivity() {
    // No Supabase keys means no cloud to sync to, so don't touch the
    // connectivity plugin at all (keeps guest-only builds and tests clean).
    if (!AppConstants.hasSupabaseConfig) {
      return;
    }
    try {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        (results) {
          final isOnline = results.any(
            (result) => result != ConnectivityResult.none,
          );
          // Only act on the offline -> online edge.
          if (isOnline && _wasOffline) {
            unawaited(_flush());
          }
          _wasOffline = !isOnline;
        },
        onError: (Object _) {
          // Connectivity is unavailable on this platform; the queue simply
          // waits for the next app resume.
        },
      );
    } catch (_) {
      // Same reasoning: sync retry is best-effort, never fatal.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_flush());
    }
  }

  Future<void> _flush() async {
    if (!mounted) {
      return;
    }
    try {
      // The provider turns offline / signed-out states into a no-op and keeps
      // the queue, so a throw here would be unexpected.
      await context.read<CareerProvider>().flushPendingSync();
    } catch (_) {
      // Swallow: a failed retry must never surface as a crash.
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
