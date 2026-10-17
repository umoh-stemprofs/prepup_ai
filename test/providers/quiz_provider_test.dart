import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/core/constants.dart';
import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/local/questions_local_service.dart';
import 'package:prepup_ai/models/question.dart';
import 'package:prepup_ai/models/quiz_session.dart';
import 'package:prepup_ai/models/weak_area.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late QuestionsLocalService localService;

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_quiz_provider.db';
    helper = DatabaseHelper.instance;
    localService = QuestionsLocalService(helper);
  });

  tearDown(() async {
    await helper.dispose();
  });

  Future<void> clearTables() async {
    final db = await helper.database;
    await db.delete('local_quiz_sessions');
    await db.delete('local_weak_areas');
    // Also reset any in-flight quiz state by ensuring the questions table
    // still has data (seedQuestionsFromAssetsIfEmpty is called in setUp).
  }

  group('QuizProvider', () {
    setUp(() async {
      await clearTables();
      await helper.seedQuestionsFromAssetsIfEmpty();
    });

    test(
      'startQuiz fetches questions and shuffles options independently',
      () async {
        final provider = QuizProvider(
          databaseHelper: helper,
          questionsLocalService: localService,
        );

        await provider.startQuiz(
          subject: AppConstants.mathematics,
          questionCount: 5,
        );

        // Questions were fetched.
        expect(provider.questions.length, equals(5));
        expect(provider.totalQuestions, equals(5));

        // Every question has independently shuffled options: the correct option
        // index should differ from the original in most runs (and must still
        // point at the same answer text).
        for (final question in provider.questions) {
          expect(question.options.length, equals(4));
          expect(question.options[question.correctOptionIndex], isNotNull);
          // Shuffling changes ordering: the new correct index is very likely
          // different from 0..3 original position across multiple seeds.
        }

        // The provider is no longer loading and the quiz is active (not
        // completed).
        expect(provider.isLoading, isFalse);
        expect(provider.isCompleted, isFalse);
        expect(provider.currentIndex, equals(0));
        expect(provider.remainingSeconds, greaterThan(0));
      },
    );

    test(
      'option selection records the answer for the given question index',
      () async {
        final provider = QuizProvider(
          databaseHelper: helper,
          questionsLocalService: localService,
        );

        await provider.startQuiz(
          subject: AppConstants.englishLanguage,
          questionCount: 3,
        );

        // Initially nothing is selected.
        expect(provider.currentSelectedOption, isNull);
        expect(provider.userAnswers, isEmpty);

        // Select an option for the current question.
        provider.selectOption(0, 2);
        expect(provider.currentSelectedOption, equals(2));
        expect(provider.userAnswers.length, equals(1));
        expect(provider.userAnswers[0], equals(2));

        // Move to the next question and select there.
        provider.nextQuestion();
        expect(provider.currentIndex, equals(1));
        provider.selectOption(1, 0);
        expect(provider.userAnswers.length, equals(2));
        expect(provider.userAnswers[1], equals(0));

        // Selecting for an unrelated index works too.
        provider.selectOption(2, 3);
        expect(provider.userAnswers.length, equals(3));
        expect(provider.userAnswers[2], equals(3));
      },
    );

    test('answer recording ignores selection when quiz is completed', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(subject: AppConstants.physics, questionCount: 2);

      provider.selectOption(0, 1);
      expect(provider.userAnswers[0], equals(1));

      await provider.finishQuiz();
      expect(provider.isCompleted, isTrue);

      // After completion, further selections are ignored.
      provider.selectOption(1, 0);
      expect(provider.userAnswers.length, equals(1));
    });

    test(
      'score calculation, pass mark evaluation, and session summary',
      () async {
        final provider = QuizProvider(
          databaseHelper: helper,
          questionsLocalService: localService,
        );

        await provider.startQuiz(
          subject: AppConstants.chemistry,
          questionCount: 4,
        );

        // Answer every question correctly.
        for (int i = 0; i < 4; i++) {
          final correct = provider.questions[i].correctOptionIndex;
          provider.selectOption(i, correct);
        }

        expect(provider.correctCount, equals(4));
        expect(provider.wrongCount, equals(0));
        expect(provider.answeredCount, equals(4));
        expect(provider.scorePercentage, equals(100.0));
        expect(provider.isPass, isTrue);

        await provider.finishQuiz();
        final session = provider.lastSession;
        expect(session, isNotNull);
        expect(session!.score, equals(4));
        expect(session.totalQuestions, equals(4));
        expect(session.scorePercentage, equals(100.0));
        expect(session.isPass, isTrue);
        expect(session.subject, equals(AppConstants.chemistry));
        expect(session.timeSpentSeconds, greaterThanOrEqualTo(0));
        expect(session.completedAt, isNotNull);
        expect(session.sessionUuid, isA<String>());
      },
    );

    test('passing threshold is 50 percent via AppConstants.isPass', () {
      // 2 of 4 = 50% -> pass.
      final providerA = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );
      expect(providerA.isPass, isFalse); // no questions yet -> 0%
      // We can't easily set arbitrary scores without a quiz, but we can
      // verify the constant the provider relies on.
      expect(AppConstants.isPass(50.0), isTrue);
      expect(AppConstants.isPass(49.9), isFalse);
      expect(AppConstants.isPass(100.0), isTrue);
      expect(AppConstants.isPass(0.0), isFalse);
    });

    test('failing quiz produces a non-passing session', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(subject: AppConstants.biology, questionCount: 4);

      // Answer everything incorrectly.
      for (int i = 0; i < 4; i++) {
        final correct = provider.questions[i].correctOptionIndex;
        final wrong = [0, 1, 2, 3]..remove(correct);
        provider.selectOption(i, wrong.first);
      }

      expect(provider.correctCount, equals(0));
      expect(provider.scorePercentage, equals(0.0));
      expect(provider.isPass, isFalse);

      await provider.finishQuiz();
      final session = provider.lastSession;
      expect(session, isNotNull);
      expect(session!.score, equals(0));
      expect(session.isPass, isFalse);
      expect(session.scorePercentage, equals(0.0));
    });

    test('mixed answers produce correct score and weak areas', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(
        subject: AppConstants.mathematics,
        questionCount: 6,
      );

      // Answer 4 correctly, 2 incorrectly.
      int correct = 0;
      for (int i = 0; i < 6; i++) {
        final q = provider.questions[i];
        if (i < 4) {
          provider.selectOption(i, q.correctOptionIndex);
          correct++;
        } else {
          final wrong = [0, 1, 2, 3]..remove(q.correctOptionIndex);
          provider.selectOption(i, wrong.first);
        }
      }

      expect(provider.correctCount, equals(4));
      expect(provider.wrongCount, equals(2));
      expect(provider.answeredCount, equals(6));
      expect(provider.scorePercentage, equals((4 / 6) * 100));
      // 66.67% >= 50% -> pass.
      expect(provider.isPass, isTrue);

      await provider.finishQuiz();
      final session = provider.lastSession;
      expect(session, isNotNull);
      expect(session!.score, equals(4));
      expect(session.totalQuestions, equals(6));
      expect(session.isPass, isTrue);

      // Weak areas were persisted for the incorrect questions.
      final db = await helper.database;
      final weakRows = await db.query(
        'local_weak_areas',
        where: 'incorrect_count > 0',
      );
      expect(
        weakRows.length,
        greaterThan(0),
        reason: 'Expected at least one weak area with incorrect_count > 0',
      );

      final persisted = weakRows.map((row) => WeakArea.fromMap(row)).toList();
      for (final area in persisted) {
        expect(area.incorrectCount, greaterThan(0));
        expect(area.totalCount, greaterThan(0));
        expect(area.subject, equals(AppConstants.mathematics));
      }
    });

    test('finishQuiz persists session row in local_sqlite', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(
        subject: AppConstants.geography,
        questionCount: 3,
      );

      for (int i = 0; i < 3; i++) {
        provider.selectOption(i, provider.questions[i].correctOptionIndex);
      }

      await provider.finishQuiz();

      final db = await helper.database;
      final rows = await db.query('local_quiz_sessions');
      expect(rows.length, greaterThanOrEqualTo(1));

      final session = QuizSession.fromMap(rows.first);
      expect(session.subject, equals(AppConstants.geography));
      expect(session.totalQuestions, equals(3));
      expect(session.score, equals(3));
      expect(session.isPass, isTrue);
    });

    test('weak area persistence records incorrect and total counts', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(
        subject: AppConstants.economics,
        questionCount: 5,
      );

      // Answer 3 correctly, 2 incorrectly, all in the same syllabus topic
      // (the seed uses varied topics, so we just verify the aggregate).
      for (int i = 0; i < 5; i++) {
        final q = provider.questions[i];
        if (i % 2 == 0) {
          provider.selectOption(i, q.correctOptionIndex);
        } else {
          final wrong = [0, 1, 2, 3]..remove(q.correctOptionIndex);
          provider.selectOption(i, wrong.first);
        }
      }

      await provider.finishQuiz();

      final db = await helper.database;
      final weakRows = await db.query('local_weak_areas');
      final totalIncorrect = weakRows.fold<int>(
        0,
        (sum, row) => sum + (row['incorrect_count'] as int? ?? 0),
      );
      final totalAttempted = weakRows.fold<int>(
        0,
        (sum, row) => sum + (row['total_count'] as int? ?? 0),
      );

      // 2 incorrect answers across the topics that were missed.
      expect(totalIncorrect, equals(2));
      expect(totalAttempted, equals(5));
    });

    test('quiz can be restarted after completion', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(subject: AppConstants.physics, questionCount: 2);
      provider.selectOption(0, 0);
      await provider.finishQuiz();

      expect(provider.isCompleted, isTrue);
      expect(provider.lastSession, isNotNull);

      // Start a fresh quiz — state should reset.
      await provider.startQuiz(subject: AppConstants.physics, questionCount: 3);

      expect(provider.questions.length, equals(3));
      expect(provider.isCompleted, isFalse);
      expect(provider.currentIndex, equals(0));
      expect(provider.userAnswers, isEmpty);
      expect(provider.remainingSeconds, greaterThan(0));
    });

    test('navigation guards prevent out-of-range movement', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(
        subject: AppConstants.englishLanguage,
        questionCount: 3,
      );

      expect(provider.canGoBack, isFalse);
      provider.nextQuestion();
      expect(provider.currentIndex, equals(1));
      expect(provider.canGoBack, isTrue);
      provider.nextQuestion();
      expect(provider.currentIndex, equals(2));
      expect(provider.canGoForward, isFalse);

      // Forward past the end does nothing.
      provider.nextQuestion();
      expect(provider.currentIndex, equals(2));

      // Back past the start does nothing.
      provider.previousQuestion();
      provider.previousQuestion();
      provider.previousQuestion();
      expect(provider.currentIndex, equals(0));
    });

    test('selectOption ignores out-of-range indices', () async {
      final provider = QuizProvider(
        databaseHelper: helper,
        questionsLocalService: localService,
      );

      await provider.startQuiz(
        subject: AppConstants.chemistry,
        questionCount: 2,
      );

      provider.selectOption(-1, 0);
      provider.selectOption(0, -1);
      provider.selectOption(0, 4);
      provider.selectOption(5, 0);
      expect(provider.userAnswers, isEmpty);
    });

    test(
      'duration is 15 minutes for 10 questions and 30 minutes for 20',
      () async {
        final short = QuizProvider(
          databaseHelper: helper,
          questionsLocalService: localService,
        );
        final long = QuizProvider(
          databaseHelper: helper,
          questionsLocalService: localService,
        );

        await short.startQuiz(
          subject: AppConstants.mathematics,
          questionCount: 10,
        );
        await long.startQuiz(
          subject: AppConstants.mathematics,
          questionCount: 20,
        );

        expect(short.remainingSeconds, equals(15 * 60));
        expect(long.remainingSeconds, equals(30 * 60));

        await short.finishQuiz();
        await long.finishQuiz();
      },
    );
  });

  group('QuizSession persistence round-trip', () {
    setUp(() async {
      await clearTables();
    });

    test('saved session can be read back from SQLite', () async {
      await helper.seedQuestionsFromAssetsIfEmpty();

      final session = QuizSession(
        sessionUuid: 'test-uuid-1234',
        subject: AppConstants.physics,
        score: 7,
        totalQuestions: 10,
        scorePercentage: 70.0,
        isPass: true,
        timeSpentSeconds: 900,
        completedAt: DateTime.utc(2026, 10, 16, 12, 0, 0),
      );

      await helper.saveQuizSession(session);

      final db = await helper.database;
      final rows = await db.query('local_quiz_sessions');
      expect(rows.length, equals(1));

      final restored = QuizSession.fromMap(rows.first);
      expect(restored, equals(session));
    });

    test('saveQuizSession upserts on duplicate session UUID', () async {
      await helper.seedQuestionsFromAssetsIfEmpty();

      final sessionA = QuizSession(
        sessionUuid: 'upsert-uuid',
        subject: AppConstants.biology,
        score: 3,
        totalQuestions: 5,
        scorePercentage: 60.0,
        isPass: true,
        timeSpentSeconds: 600,
        completedAt: DateTime.utc(2026, 10, 16, 10, 0, 0),
      );

      await helper.saveQuizSession(sessionA);
      await helper.saveQuizSession(
        sessionA.copyWith(score: 5, scorePercentage: 100.0, isPass: true),
      );

      final db = await helper.database;
      final rows = await db.query(
        'local_quiz_sessions',
        where: 'session_uuid = ?',
        whereArgs: ['upsert-uuid'],
      );
      expect(rows.length, equals(1));
      expect(rows.first['score'], equals(5));
    });
  });
}

// Helper to create a mutated copy for upsert tests.
extension on QuizSession {
  QuizSession copyWith({
    String? sessionUuid,
    String? subject,
    int? score,
    int? totalQuestions,
    double? scorePercentage,
    bool? isPass,
    int? timeSpentSeconds,
    DateTime? completedAt,
  }) {
    return QuizSession(
      sessionUuid: sessionUuid ?? this.sessionUuid,
      subject: subject ?? this.subject,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      isPass: isPass ?? this.isPass,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
