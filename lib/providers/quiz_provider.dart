import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/local/database_helper.dart';
import '../data/local/questions_local_service.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/weak_area.dart';

/// Manages a single CBT practice quiz: question fetch, option shuffling,
/// answer capture, countdown timer, scoring, and local persistence.
///
/// The provider is stateless until [startQuiz] is called. After [finishQuiz]
/// it holds the completed [lastSession] and can be reused for another attempt.
class QuizProvider extends ChangeNotifier {
  QuizProvider({
    DatabaseHelper? databaseHelper,
    QuestionsLocalService? questionsLocalService,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance {
    _questionsLocalService = questionsLocalService ?? QuestionsLocalService(_databaseHelper);
  }

  late final DatabaseHelper _databaseHelper;
  late final QuestionsLocalService _questionsLocalService;

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

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

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
  /// Fetches questions from the local cache, shuffles options independently
  /// for each question, and starts a countdown timer. The timer auto-finishes
  /// the quiz when it reaches zero.
  Future<void> startQuiz({
    required String subject,
    required int questionCount,
  }) async {
    _resetState();

    // Duration: 15 minutes for 10 questions, 30 minutes for 20 questions.
    final durationMinutes =
        questionCount <= 10 ? 15 : 30;
    _originalDurationSeconds = durationMinutes * 60;
    _remainingSeconds = _originalDurationSeconds;

    // Fetch questions from the local cache.
    final rows = await _questionsLocalService.getQuestionsBySubject(
      subject,
      limit: questionCount,
    );

    // Convert DB rows to Question objects, then shuffle options independently.
    _questions = rows.map((Map<String, dynamic> row) {
      return Question.fromMap(row).shuffleOptions();
    }).toList(growable: false);

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

    // Persist to local SQLite.
    try {
      await _databaseHelper.saveQuizSession(session);
      await _databaseHelper.saveWeakAreas(_buildWeakAreas(session.sessionUuid));
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
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_remainingSeconds <= 0) {
          _countdownTimer?.cancel();
          finishQuiz();
          return;
        }
        _remainingSeconds--;
        notifyListeners();
      },
    );
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
      subject: _questions.isNotEmpty ? _questions.first.subject : 'All Subjects',
      score: correctCount,
      totalQuestions: _questions.length,
      scorePercentage: scorePercentage,
      isPass: isPass,
      timeSpentSeconds: _timeSpentSeconds,
      completedAt: now,
    );
  }

  List<WeakArea> _buildWeakAreas(String sessionUuid) {
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
          incorrectCount: existing.incorrectCount +
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
    _isCompleted = false;
    _lastSession = null;
    _originalDurationSeconds = 0;
    _frozenRemainingAtCompletion = 0;
  }  bool get _canNavigate => !_isCompleted && _questions.isNotEmpty;

  void _freezeRemainingOnCompletion() {
    _frozenRemainingAtCompletion = _remainingSeconds;
  }

  

  static String _generateUuid() {
    final Random rng = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _cancelCountdownTimer();
    super.dispose();
  }
}
