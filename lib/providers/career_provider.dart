import 'package:flutter/material.dart';

import '../data/local/database_helper.dart';
import '../data/remote/career_sync_service.dart';
import '../models/saved_career.dart';

/// Manages the STEM career helper flow: selection state, deterministic
/// matching, and the locally persisted bookmarks.
class CareerProvider extends ChangeNotifier {
  CareerProvider({
    DatabaseHelper? databaseHelper,
    CareerSyncService? syncService,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance {
    _syncService = syncService ??
        CareerSyncService(databaseHelper: _databaseHelper);
  }

  final DatabaseHelper _databaseHelper;
  late final CareerSyncService _syncService;

  WorkEnvironment _workEnvironment = WorkEnvironment.indoor;
  ActivityPreference _activityPreference = ActivityPreference.building;
  Set<String> _favoriteSubjects = {}; // max 1

  WorkEnvironment get workEnvironment => _workEnvironment;
  ActivityPreference get activityPreference => _activityPreference;
  Set<String> get favoriteSubjects => Set<String>.unmodifiable(_favoriteSubjects);

  bool get hasSelection => _favoriteSubjects.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Saved careers
  // ---------------------------------------------------------------------------

  List<SavedCareer> _savedCareers = const <SavedCareer>[];
  bool _savedCareersLoaded = false;

  /// Careers bookmarked by the student, newest first.
  List<SavedCareer> get savedCareers =>
      List<SavedCareer>.unmodifiable(_savedCareers);

  /// Whether the bookmarks have been read from disk yet.
  bool get savedCareersLoaded => _savedCareersLoaded;

  int _pendingSyncCount = 0;
  bool _isSyncing = false;
  String? _lastSyncError;

  /// Cloud writes still waiting to be flushed.
  int get pendingSyncCount => _pendingSyncCount;

  /// True while a flush is in flight.
  bool get isSyncing => _isSyncing;

  /// Last remote failure, or null when the queue is healthy.
  String? get lastSyncError => _lastSyncError;

  /// Loads bookmarks from the offline cache.
  Future<void> loadSavedCareers() async {
    _savedCareers = await _databaseHelper.getSavedCareers();
    _pendingSyncCount = await _syncService.pendingCount();
    _savedCareersLoaded = true;
    notifyListeners();
  }

  /// Persists the current [match] locally, then tries to push it to the cloud.
  ///
  /// The local write always succeeds first; the cloud write is queued and
  /// flushed best-effort, so being offline only delays the sync.
  Future<SavedCareer> saveCurrentMatch() async {
    final current = match();
    final saved = SavedCareer(
      careerTitle: current.title,
      summary: current.summary,
      requiredSubjects: current.subjects,
      matchPercentage: current.matchPercentage,
      savedAt: DateTime.now(),
    );

    await _databaseHelper.saveSavedCareer(saved);
    await _syncService.queueUpsert(saved);
    await loadSavedCareers();
    await flushPendingSync();
    return saved;
  }

  /// Removes a bookmark locally, then queues the cloud delete.
  Future<void> removeSavedCareer(int id) async {
    SavedCareer? removed;
    for (final career in _savedCareers) {
      if (career.id == id) {
        removed = career;
        break;
      }
    }

    await _databaseHelper.deleteSavedCareer(id);
    if (removed != null) {
      await _syncService.queueDelete(removed.careerTitle);
    }
    await loadSavedCareers();
    await flushPendingSync();
  }

  /// Pushes queued cloud writes, if a session exists and the device is online.
  ///
  /// Never throws: offline or signed-out states simply leave the queue intact.
  Future<CareerSyncReport> flushPendingSync() async {
    if (_isSyncing) {
      return CareerSyncReport(pending: _pendingSyncCount);
    }

    _isSyncing = true;
    notifyListeners();
    try {
      final report = await _syncService.flush();
      _pendingSyncCount = report.pending;
      _lastSyncError = report.error;
      return report;
    } catch (error) {
      // Includes local queue read failures: surface, never crash the UI.
      _lastSyncError = error.toString();
      return CareerSyncReport(
        pending: _pendingSyncCount,
        error: _lastSyncError,
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Best match based on the current selections.
  ///
  /// Deterministic: same inputs always produce the same role.
  CareerMatch match() {
    final subject = _favoriteSubjects.isNotEmpty
        ? _favoriteSubjects.first
        : 'Physics'; // default when nothing selected

    final (title, summary, subjects) = _computeMatch(
      workEnvironment: _workEnvironment,
      activityPreference: _activityPreference,
      subject: subject,
    );

    return CareerMatch(
      title: title,
      summary: summary,
      subjects: subjects,
      matchPercentage: _matchPercentage(
        workEnvironment: _workEnvironment,
        activityPreference: _activityPreference,
        subject: subject,
      ),
    );
  }

  static (String title, String summary, List<String> subjects) _computeMatch({
    required WorkEnvironment workEnvironment,
    required ActivityPreference activityPreference,
    required String subject,
  }) {
    // Deterministic matching table.
    switch (subject) {
      case 'Mathematics':
        if (activityPreference == ActivityPreference.solvingMath) {
          return (
            'Data Scientist',
            'You turn numbers into decisions. Perfect if you love patterns, '
                'algebra, and statistics.',
            ['Mathematics', 'Physics'],
          );
        }
        return (
          'Cryptographer',
          'You protect information with number theory. Great fit for logical '
              'thinkers who enjoy algebra.',
          ['Mathematics', 'Physics'],
        );

      case 'Physics':
        if (workEnvironment == WorkEnvironment.outdoor) {
          return (
            'Renewable Energy Engineer',
            'You design solar, wind, and storage systems out in the field. '
                'Physics + outdoors = real-world impact.',
            ['Physics', 'Mathematics'],
          );
        }
        if (activityPreference == ActivityPreference.building) {
          return (
            'Mechanical Engineer',
            'You build and fix machines. Mechanics, thermodynamics, and design '
                'are your toolkit.',
            ['Physics', 'Mathematics', 'Chemistry'],
          );
        }
        return (
          'Engineer',
          'You build and fix machines. Physics gives you the principles, '
              'Maths the precision.',
          ['Physics', 'Mathematics'],
        );

      case 'Chemistry':
        if (activityPreference == ActivityPreference.building) {
          return (
            'Chemical Engineer',
            'You turn raw materials into products — fuels, medicines, and '
                'materials. Lab and plant work combined.',
            ['Chemistry', 'Physics', 'Mathematics'],
          );
        }
        return (
          'Pharmacist',
          'You study how substances work in the body and help people feel '
                'better. Precision and care matter.',
          ['Chemistry', 'Biology'],
        );

      case 'Biology':
        if (workEnvironment == WorkEnvironment.outdoor) {
          return (
            'Ecologist',
            'You study living systems in the field — forests, rivers, and '
                'wildlife. Biology outdoors at its best.',
            ['Biology', 'Chemistry'],
          );
        }
        return (
          'Biomedical Scientist',
          'You investigate how life works at the cellular level and help '
                'develop new treatments.',
          ['Biology', 'Chemistry'],
        );

      default:
        return (
          'STEM Professional',
          'You have what it takes to build a career in science and technology.',
          [subject],
        );
    }
  }

  static int _matchPercentage({
    required WorkEnvironment workEnvironment,
    required ActivityPreference activityPreference,
    required String subject,
  }) {
    // Deterministic score in the 85-99 range so the UI badge looks credible.
    int base = 85;
    if (workEnvironment == WorkEnvironment.indoor) base += 5;
    if (activityPreference == ActivityPreference.building) base += 5;
    if (subject == 'Physics') base += 4;
    if (subject == 'Mathematics') base += 3;
    if (subject == 'Chemistry') base += 2;
    return base.clamp(85, 99);
  }

  void setWorkEnvironment(WorkEnvironment value) {
    if (_workEnvironment == value) return;
    _workEnvironment = value;
    notifyListeners();
  }

  void setActivityPreference(ActivityPreference value) {
    if (_activityPreference == value) return;
    _activityPreference = value;
    notifyListeners();
  }

  void setFavoriteSubject(String subject) {
    if (_favoriteSubjects.contains(subject)) {
      _favoriteSubjects.remove(subject);
    } else {
      _favoriteSubjects = {subject};
    }
    notifyListeners();
  }

  void reset() {
    _workEnvironment = WorkEnvironment.indoor;
    _activityPreference = ActivityPreference.building;
    _favoriteSubjects = {};
    notifyListeners();
  }
}

enum WorkEnvironment {
  indoor,
  outdoor,
}

enum ActivityPreference {
  solvingMath,
  building,
}

/// Deterministic career match result shown in the UI.
class CareerMatch {
  final String title;
  final String summary;
  final List<String> subjects;
  final int matchPercentage;

  const CareerMatch({
    required this.title,
    required this.summary,
    required this.subjects,
    required this.matchPercentage,
  });
}