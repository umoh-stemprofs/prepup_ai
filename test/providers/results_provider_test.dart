import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/core/constants.dart';
import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/local/questions_local_service.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';
import 'package:prepup_ai/providers/results_provider.dart';

/// Phase 10.3: the results screen reads the attempt from the shuffled snapshot,
/// never by re-querying the database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late QuestionsLocalService localService;
  late QuizProvider quiz;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_results_provider.db';
    helper = DatabaseHelper.instance;
    localService = QuestionsLocalService(helper);
    quiz = QuizProvider(
      databaseHelper: helper,
      questionsLocalService: localService,
    );

    final db = await helper.database;
    await db.delete('local_quiz_sessions');
    await db.delete('local_weak_areas');
    await db.delete('pending_sync_results');
    await helper.seedQuestionsFromAssetsIfEmpty();
  });

  tearDown(() async {
    quiz.dispose();
    await helper.dispose();
  });

  test('has no results before an attempt finishes', () {
    final results = ResultsProvider(quiz);

    expect(results.hasResults, isFalse);
    expect(results.session, isNull);
    expect(results.weakAreas, isEmpty);
    expect(results.missedTopics, isEmpty);
  });

  test('derives score and weak areas from the in-memory attempt', () async {
    // One sub-topic so the breakdown is a single row.
    await quiz.startQuiz(
      subject: AppConstants.mathematics,
      questionCount: 4,
      syllabusTopic: 'Algebra',
    );

    // Three wrong, one right.
    for (var i = 0; i < 4; i++) {
      final correct = quiz.questions[i].correctOptionIndex;
      quiz.selectOption(i, i == 0 ? correct : (correct + 1) % 4);
    }
    await quiz.finishQuiz();

    final results = ResultsProvider(quiz);

    expect(results.hasResults, isTrue);
    expect(results.session?.score, 1);
    expect(results.correctCount, 1);
    expect(results.wrongCount, 3);
    expect(results.totalQuestions, 4);
    expect(results.weakAreas, hasLength(1));
    expect(results.hasMissedTopics, isTrue);
    expect(results.missedTopics.single.incorrectCount, 3);
  });
}
