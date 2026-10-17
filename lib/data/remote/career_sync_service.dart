/// PrepUp AI — offline-first sync for bookmarked careers (Phase 09).
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../models/pending_career_sync.dart';
import '../../models/saved_career.dart';
import '../local/database_helper.dart';
import 'career_remote_store.dart';

/// Why a flush could not push the queue.
enum CareerSyncSkip {
  /// No Supabase session: the queue waits for a sign-in.
  notSignedIn,

  /// The device reports no connectivity.
  offline,

  /// Supabase is not configured in this build.
  noRemote,
}

/// Result of one [CareerSyncService.flush] attempt.
class CareerSyncReport {
  const CareerSyncReport({
    this.synced = 0,
    this.pending = 0,
    this.skipped,
    this.error,
  });

  /// How many queued operations the cloud accepted.
  final int synced;

  /// How many operations are still queued afterwards.
  final int pending;

  /// Set when the flush stopped before trying anything.
  final CareerSyncSkip? skipped;

  /// Set when a remote write failed; the operation stays queued.
  final String? error;

  /// True when nothing is left waiting to be pushed.
  bool get isComplete => pending == 0;

  @override
  String toString() =>
      'CareerSyncReport(synced: $synced, pending: $pending, '
      'skipped: ${skipped?.name}, error: $error)';
}

/// Local-first sync for saved careers.
///
/// Every bookmark change is written to SQLite and queued. [flush] drains the
/// queue to Supabase when a session exists and the device is online; otherwise
/// the queue survives until the next opportunity.
class CareerSyncService {
  CareerSyncService({
    required DatabaseHelper databaseHelper,
    CareerRemoteStore? remote,
    CareerRemoteStore? Function()? remoteFactory,
    String? Function()? userIdProvider,
    Future<bool> Function()? isOnline,
  }) : _databaseHelper = databaseHelper,
       _remote = remote,
       _remoteFactory = remoteFactory,
       _userIdProvider = userIdProvider,
       _isOnline = isOnline;

  final DatabaseHelper _databaseHelper;
  final CareerRemoteStore? _remote;
  final CareerRemoteStore? Function()? _remoteFactory;
  final String? Function()? _userIdProvider;
  final Future<bool> Function()? _isOnline;

  CareerRemoteStore? _resolvedRemote;
  Future<CareerSyncReport>? _inFlight;
  String? _lastError;

  /// Last remote failure, cleared on the next successful flush.
  String? get lastError => _lastError;

  // ---------------------------------------------------------------------------
  // Queueing
  // ---------------------------------------------------------------------------

  /// True when this build could ever reach a cloud store.
  ///
  /// Guest-only builds without Supabase keys skip queueing entirely, so the UI
  /// never shows "waiting to sync" for something that has nowhere to go.
  bool get canSync =>
      _remote != null ||
      _remoteFactory != null ||
      AppConstants.hasSupabaseConfig;

  Future<void> queueUpsert(SavedCareer career) async {
    if (!canSync) {
      return;
    }
    await _databaseHelper.queueCareerSync(PendingCareerSync.upsert(career));
  }

  Future<void> queueDelete(String careerTitle) async {
    if (!canSync) {
      return;
    }
    await _databaseHelper.queueCareerSync(
      PendingCareerSync.delete(careerTitle),
    );
  }

  Future<int> pendingCount() async {
    if (!canSync) {
      return 0;
    }
    return _databaseHelper.pendingCareerSyncCount();
  }

  // ---------------------------------------------------------------------------
  // Flushing
  // ---------------------------------------------------------------------------

  /// Pushes queued writes to the cloud, oldest first.
  ///
  /// Stops at the first failure so ordering is preserved and the remaining
  /// operations stay queued. Never throws: failures are reported.
  Future<CareerSyncReport> flush() {
    // Coalesce concurrent callers onto one in-flight flush.
    return _inFlight ??= _flush().whenComplete(() => _inFlight = null);
  }

  Future<CareerSyncReport> _flush() async {
    if (!canSync) {
      // Guest-only build: nothing queued, nothing to flush, no DB touch.
      return const CareerSyncReport(skipped: CareerSyncSkip.noRemote);
    }

    final pending = await _databaseHelper.getPendingCareerSync();
    if (pending.isEmpty) {
      _lastError = null;
      return const CareerSyncReport();
    }

    final userId = _resolveUserId();
    if (userId == null) {
      return CareerSyncReport(
        pending: pending.length,
        skipped: CareerSyncSkip.notSignedIn,
      );
    }

    // Pick the checker first, then invoke it. Calling `??` directly would
    // yield a Future and try to invoke that.
    final onlineCheck = _isOnline ?? _defaultIsOnline;
    final online = await onlineCheck();
    if (!online) {
      return CareerSyncReport(
        pending: pending.length,
        skipped: CareerSyncSkip.offline,
      );
    }

    final remote = _resolveRemote();
    if (remote == null) {
      return CareerSyncReport(
        pending: pending.length,
        skipped: CareerSyncSkip.noRemote,
      );
    }

    var synced = 0;
    _lastError = null;

    for (final operation in pending) {
      try {
        switch (operation.operation) {
          case CareerSyncOperation.upsert:
            final career = operation.career;
            if (career != null) {
              await remote.upsert(userId: userId, career: career);
            }
          case CareerSyncOperation.delete:
            await remote.delete(
              userId: userId,
              careerTitle: operation.careerTitle,
            );
        }
        await _databaseHelper.clearPendingCareerSync(operation.careerTitle);
        synced++;
      } catch (error) {
        _lastError = _describe(error);
        break;
      }
    }

    return CareerSyncReport(
      synced: synced,
      pending: await _databaseHelper.pendingCareerSyncCount(),
      error: _lastError,
    );
  }

  /// Drops a queued write that can never be pushed (e.g. after sign-out).
  Future<void> discardQueue() async {
    final pending = await _databaseHelper.getPendingCareerSync();
    for (final operation in pending) {
      await _databaseHelper.clearPendingCareerSync(operation.careerTitle);
    }
  }

  // ---------------------------------------------------------------------------
  // Defaults
  // ---------------------------------------------------------------------------

  String? _resolveUserId() {
    if (_userIdProvider != null) {
      return _userIdProvider();
    }
    if (!AppConstants.hasSupabaseConfig) {
      return null;
    }
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // Supabase was never initialised in this build.
      return null;
    }
  }

  CareerRemoteStore? _resolveRemote() {
    if (_resolvedRemote != null) {
      return _resolvedRemote;
    }
    if (_remote != null) {
      return _resolvedRemote = _remote;
    }
    if (_remoteFactory != null) {
      return _resolvedRemote = _remoteFactory();
    }
    if (!AppConstants.hasSupabaseConfig) {
      return null;
    }
    try {
      return _resolvedRemote = SupabaseCareerStore();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _defaultIsOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      // Unknown platform state: let the remote call decide instead of
      // silently dropping the queue.
      return true;
    }
  }

  String _describe(Object error) {
    final text = error.toString().split('\n').first.trim();
    if (text.isEmpty) {
      return 'Sync failed.';
    }
    return text.length > 160 ? '${text.substring(0, 160)}…' : text;
  }
}
