import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/local/database_helper.dart';
import '../data/local/questions_local_service.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/weak_area.dart';

/// How a quiz is timed (Phase 08, task 9.2).
enum QuizMode {
  /// Real exam conditions: a wall-clock countdown that never pauses and
  /// auto-submits when it reaches zero.
  timed,

  /// Untimed drilling: no countdown, the student submits manually when ready.
  practice,
}

/// Manages a single CBT practice quiz: question fetch, option shuffling,
/// answer capture, countdown timer, scoring, and local persistence.
///
/// The provider is stateless until [startQuiz] is called. After [finishQuiz]
/// it holds the completed [lastSession] and can be reused for another attempt.
class QuizProvider extends ChangeNotifier {
  QuizProvider({
    DatabaseHelper? databaseHelper,
    QuestionsLocalService? questionsLocalService,
    String? Function()? userIdProvider,
    DateTime Function()? now,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       _userIdProvider = userIdProvider,
       _now = now ?? DateTime.now {
    _questionsLocalService =
        questionsLocalService ?? QuestionsLocalService(_databaseHelper);
  }

  late final DatabaseHelper _databaseHelper;
  late final QuestionsLocalService _questionsLocalService;

  /// Resolves the signed-in account, so a finished attempt is queued for the
  /// student who actually practised. Null means guest: local history only.
  final String? Function()? _userIdProvider;

  /// Clock source, injectable so tests can drive the wall-clock deadline
  /// without real waiting.
  final DateTime Function() _now;

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  /// Questions currently in the quiz, in presentation order, each with
  /// independently shuffled options.
  List<Question> _questions = <Question>[];
  List<Question> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  /// Maps presentation-position index -> selected option index (0-3).
  /// Absent entries mean the question has not been answered yet.
  final Map<int, int> _userAnswers = <int, int>{};
  Map<int, int> get userAnswers => Map<int, int>.unmodifiable(_userAnswers);

  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  /// Full length of the attempt in seconds (15 or 30 minutes).
  int get originalDurationSeconds => _originalDurationSeconds;

  /// Seconds elapsed since the attempt started — what the practice badge
  /// shows, since untimed drills count up instead of down.
  int get elapsedSeconds {
    final startedAt = _startedAt;
    if (startedAt == null) return 0;
    final elapsed = _now().difference(startedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  QuizMode _mode = QuizMode.timed;
  QuizMode get mode => _mode;

  /// Wall-clock instant the exam ends (Phase 08, D7).
  ///
  /// Fixed once [startQuiz] is called. [remainingSeconds] is always derived
  /// from this rather than a counter, so backgrounding the app or navigating
  /// away cannot pause or drift the clock.
  DateTime? _examEndsAt;
  DateTime? get examEndsAt => _examEndsAt;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  /// True when the last completion came from the deadline (timer or resume),
  /// not a manual submit.
  ///
  /// The exam screen uses this to decide whether it should navigate itself to
  /// the results screen (auto-submit) or leave navigation to the submit dialog.
  bool _autoSubmitted = false;
  bool get autoSubmitted => _autoSubmitted;

  /// When the current attempt started, for practice-mode elapsed time.
  DateTime? _startedAt;

  QuizSession? _lastSession;
  QuizSession? get lastSession => _lastSession;

  // ---------------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------------

  bool get isLoading => _questions.isEmpty && !_isCompleted;

  Question? get currentQuestion =>
      (_questions.isEmpty || _isCompleted) ? null : _questions[_currentIndex];

  int? get currentSelectedOption => _userAnswers[_currentIndex];

  int get totalQuestions => _questions.length;

  int get correctCount {
    var count = 0;
    for (int i = 0; i < _questions.length; i++) {
      final selected = _userAnswers[i];
      if (selected == null) continue;
      if (selected == _questions[i].correctOptionIndex) count++;
    }
    return count;
  }

  int get wrongCount => answeredCount - correctCount;

  int get answeredCount => _userAnswers.length;

  double get scorePercentage {
    if (_questions.isEmpty) return 0;
    return (correctCount / _questions.length) * 100;
  }

  bool get isPass => AppConstants.isPass(scorePercentage);

  bool get canGoBack => _currentIndex > 0;
  bool get canGoForward => _currentIndex < _questions.length - 1;

  // ---------------------------------------------------------------------------
  // Quiz lifecycle
  // ---------------------------------------------------------------------------

  /// Start a new quiz for [subject] with [questionCount] questions.
  ///
  /// When [syllabusTopic] is given the question pool is narrowed to that
  /// sub-topic, which is what "practice red topics" needs: drilling the topic
  /// that was missed instead of the whole subject. A topic-scoped request that
  /// finds no cached questions returns an empty quiz rather than silently
  /// widening back to the subject.
  ///
  /// [mode] decides timing: [QuizMode.timed] sets a wall-clock deadline that
  /// auto-submits, [QuizMode.practice] has no deadline and relies on a manual
  /// submit. Both produce the same scoring and analytics.
  ///
  /// Fetches questions from the local cache, shuffles options independently
  /// for each question.
  Future<void> startQuiz({
    required String subject,
    required int questionCount,
    String? syllabusTopic,
    QuizMode mode = QuizMode.timed,
  }) async {
    _resetState();
    _mode = mode;
    _startedAt = _now();

    // Duration: 15 minutes for 10 questions, 30 minutes for 20 questions.
    final durationMinutes = questionCount <= 10 ? 15 : 30;
    _originalDurationSeconds = durationMinutes * 60;

    if (_mode == QuizMode.timed) {
      // D7: the deadline is a fixed instant, never a countdown counter.
      _examEndsAt = _now().add(Duration(seconds: _originalDurationSeconds));
      _remainingSeconds = _originalDurationSeconds;
    } else {
      // Practice mode is untimed; the badge shows elapsed time instead.
      _examEndsAt = null;
      _remainingSeconds = _originalDurationSeconds;
    }

    // Fetch questions from the local cache, narrowed to one sub-topic when
    // the caller asked for one.
    final bool scopedToTopic =
        syllabusTopic != null && syllabusTopic.trim().isNotEmpty;
    final rows = scopedToTopic
        ? await _questionsLocalService.getQuestionsByTopic(
            subject,
            syllabusTopic,
            limit: questionCount,
          )
        : await _questionsLocalService.getQuestionsBySubject(
            subject,
            limit: questionCount,
          );

    // Convert DB rows to Question objects, then shuffle options independently.
    _questions = rows
        .map((Map<String, dynamic> row) {
          return Question.fromMap(row).shuffleOptions();
        })
        .toList(growable: false);

    _startCountdownTimer();
    notifyListeners();
  }

  /// Record the user's choice for the current question.
  void selectOption(int questionIndex, int optionIndex) {
    if (_isCompleted) return;
    if (questionIndex < 0 || questionIndex >= _questions.length) return;
    if (optionIndex < 0 || optionIndex > 3) return;

    _userAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  /// Move to the previous question.
  void previousQuestion() {
    if (!_canNavigate) return;
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// Move to the next question.
  void nextQuestion() {
    if (!_canNavigate) return;
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  /// Finish the quiz: cancel the timer, score, persist, and mark completed.
  Future<void> finishQuiz() async {
    if (_isCompleted) return;

    _freezeRemainingOnCompletion();
    _cancelCountdownTimer();
    _isCompleted = true;

    final session = _buildSession();
    _lastSession = session;

    // Persist to local SQLite and enqueue the cloud envelope (Phase 10.4).
    final areas = _buildWeakAreas();
    try {
      await _databaseHelper.saveQuizSession(session);
      await _databaseHelper.saveWeakAreas(session.sessionUuid, areas);
      await _databaseHelper.enqueuePendingSyncResult(
        session,
        weakAreas: areas,
        userId: _userIdProvider?.call(),
      );
    } catch (_) {
      // Best-effort persistence. The in-memory result is still available via
      // [lastSession] even if the write fails.
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  Timer? _countdownTimer;

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    // Practice mode has no deadline (9.2); it only ticks so the elapsed-time
    // badge updates once a second, and never auto-submits.
    if (_mode == QuizMode.practice) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
      });
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemainingFromClock();
      if (_remainingSeconds <= 0) {
        _countdownTimer?.cancel();
        _autoSubmitted = true;
        finishQuiz();
        return;
      }
      notifyListeners();
    });
  }

  /// Recomputes [remainingSeconds] from the wall-clock deadline (D7).
  ///
  /// Called on every tick and on every app resume, so the clock keeps running
  /// while backgrounded. Returns true when the deadline has passed.
  bool _syncRemainingFromClock() {
    final endsAt = _examEndsAt;
    if (endsAt == null) return false;

    final remaining = endsAt.difference(_now()).inSeconds;
    _remainingSeconds = remaining > 0 ? remaining : 0;
    return remaining <= 0;
  }

  /// Re-derives the remaining time and auto-submits if the deadline passed
  /// while the app was backgrounded or the screen was closed.
  ///
  /// Wired to `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` on
  /// the exam screen. A practice-mode quiz is unaffected.
  void handleAppResume() {
    if (_isCompleted) return;
    if (_mode == QuizMode.practice) {
      notifyListeners();
      return;
    }
    if (_syncRemainingFromClock()) {
      _countdownTimer?.cancel();
      _autoSubmitted = true;
      finishQuiz();
    } else {
      notifyListeners();
    }
  }

  /// Abandons the in-progress attempt without scoring or persisting it (8.6).
  ///
  /// The timer is cancelled and every trace of the attempt is dropped, so a
  /// quit can never show up in history or the sync queue.
  void quitAttempt() {
    _resetState();
    notifyListeners();
  }

  void _cancelCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Scoring & persistence
  // ---------------------------------------------------------------------------

  QuizSession _buildSession() {
    final now = DateTime.now();
    final uuid = _generateUuid();
    return QuizSession(
      sessionUuid: uuid,
      subject: _questions.isNotEmpty
          ? _questions.first.subject
          : 'All Subjects',
      score: correctCount,
      totalQuestions: _questions.length,
      scorePercentage: scorePercentage,
      isPass: isPass,
      timeSpentSeconds: _timeSpentSeconds,
      completedAt: now,
    );
  }

  /// Weak areas for the attempt just finished, built from the in-memory
  /// questions and answers — never re-queried from the database.
  List<WeakArea> get currentWeakAreas => _buildWeakAreas();

  List<WeakArea> _buildWeakAreas() {
    final Map<String, WeakArea> byTopic = <String, WeakArea>{};

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final selected = _userAnswers[i];
      if (selected == null) continue;

      final key = '${question.subject}|${question.syllabusTopic}';
      final existing = byTopic[key];
      if (existing == null) {
        byTopic[key] = WeakArea(
          subject: question.subject,
          syllabusTopic: question.syllabusTopic,
          incorrectCount: selected == question.correctOptionIndex ? 0 : 1,
          totalCount: 1,
        );
      } else {
        byTopic[key] = WeakArea(
          subject: existing.subject,
          syllabusTopic: existing.syllabusTopic,
          incorrectCount:
              existing.incorrectCount +
              (selected == question.correctOptionIndex ? 0 : 1),
          totalCount: existing.totalCount + 1,
        );
      }
    }

    return byTopic.values.toList()..sort((a, b) {
      // Deterministic order: by subject, then syllabus topic.
      final cmp = a.subject.compareTo(b.subject);
      return cmp != 0 ? cmp : a.syllabusTopic.compareTo(b.syllabusTopic);
    });
  }

  int get _timeSpentSeconds {
    // Untimed drills report wall-clock time spent, not the unused countdown.
    if (_mode == QuizMode.practice) {
      return elapsedSeconds;
    }
    if (_isCompleted) {
      return _originalDurationSeconds - _frozenRemainingAtCompletion;
    }
    return _originalDurationSeconds - _remainingSeconds;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  int _originalDurationSeconds = 0;
  int _frozenRemainingAtCompletion = 0;

  void _resetState() {
    _cancelCountdownTimer();
    _questions = <Question>[];
    _currentIndex = 0;
    _userAnswers.clear();
    _remainingSeconds = 0;
    _mode = QuizMode.timed;
    _examEndsAt = null;
    _startedAt = null;
    _autoSubmitted = false;
    _isCompleted = false;
    _lastSession = null;
    _originalDurationSeconds = 0;
    _frozenRemainingAtCompletion = 0;
  }

  bool get _canNavigate => !_isCompleted && _questions.isNotEmpty;

  void _freezeRemainingOnCompletion() {
    _frozenRemainingAtCompletion = _remainingSeconds;
  }

  static String _generateUuid() {
    final Random rng = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _cancelCountdownTimer();
    super.dispose();
  }
}
