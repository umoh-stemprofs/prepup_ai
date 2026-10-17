/// PrepUp AI — read model for a finished attempt (Phase 10).
///
/// [ResultsProvider] derives everything the results and weak-area screens need
/// from the quiz that just finished: the score snapshot and the per-topic
/// breakdown. It never re-queries the database, so the numbers on screen are
/// exactly the numbers the student just earned — even if the local cache is
/// later reseeded or re-aggregated.
library;

import '../models/quiz_session.dart';
import '../models/weak_area.dart';
import 'quiz_provider.dart';

class ResultsProvider {
  ResultsProvider(this.quiz);

  /// The attempt source of truth. [QuizProvider] holds the shuffled question
  /// snapshot and the student's answers.
  final QuizProvider quiz;

  /// The persisted snapshot of the attempt, or null before the first finish.
  QuizSession? get session => quiz.lastSession;

  /// Topic breakdown for this attempt only.
  List<WeakArea> get weakAreas => quiz.currentWeakAreas;

  /// True when an attempt has been completed and can be displayed.
  bool get hasResults => quiz.lastSession != null;

  /// Number of answered questions that were right.
  int get correctCount => quiz.correctCount;

  /// Number of answered questions that were wrong.
  int get wrongCount => quiz.wrongCount;

  /// Questions in the attempt, answered or not.
  int get totalQuestions => quiz.totalQuestions;

  /// Topics the student got wrong, weakest first — what "practice red topics"
  /// drills.
  List<WeakArea> get missedTopics {
    final missed = weakAreas.where((area) => area.incorrectCount > 0).toList();
    missed.sort((a, b) => b.incorrectRatio.compareTo(a.incorrectRatio));
    return missed;
  }

  /// True when this attempt missed at least one topic, i.e. there is something
  /// to review.
  bool get hasMissedTopics => missedTopics.isNotEmpty;
}
