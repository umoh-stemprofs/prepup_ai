// Phase 08/09: timing modes, the wall-clock deadline (D7), resume
// auto-submit, and quit semantics (8.6).

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/core/constants.dart';
import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/local/questions_local_service.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late QuestionsLocalService localService;

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_quiz_mode_deadline.db';
    helper = DatabaseHelper.instance;
    localService = QuestionsLocalService(helper);
  });

  tearDown(() async {
    await helper.dispose();
  });

  QuizProvider buildProvider({DateTime Function()? now}) {
    final provider = QuizProvider(
      databaseHelper: helper,
      questionsLocalService: localService,
      now: now,
    );
    addTearDown(provider.dispose);
    return provider;
  }

  group('QuizMode and the wall-clock deadline', () {
    setUp(() async {
      final db = await helper.database;
      await db.delete('local_quiz_sessions');
      await db.delete('local_weak_areas');
      await helper.seedQuestionsFromAssetsIfEmpty();
    });

    test('a timed quiz pins its deadline and counts down', () async {
      final frozen = DateTime(2026, 10, 17, 9);
      final provider = buildProvider(now: () => frozen);

      await provider.startQuiz(
        subject: AppConstants.mathematics,
        questionCount: 10,
      );

      expect(provider.mode, QuizMode.timed);
      expect(provider.examEndsAt, frozen.add(const Duration(minutes: 15)));
      expect(provider.remainingSeconds, 15 * 60);
      expect(provider.autoSubmitted, isFalse);
    });

    test('resuming past the deadline auto-submits the attempt', () async {
      var now = DateTime(2026, 10, 17, 9);
      final provider = buildProvider(now: () => now);

      await provider.startQuiz(
        subject: AppConstants.physics,
        questionCount: 10,
      );
      provider.selectOption(0, 0);

      // The app was backgrounded for 16 minutes: the clock kept running.
      now = now.add(const Duration(minutes: 16));
      provider.handleAppResume();

      expect(provider.isCompleted, isTrue);
      expect(provider.autoSubmitted, isTrue);
      expect(provider.remainingSeconds, 0);
      expect(provider.lastSession, isNotNull);

      // Let the best-effort persistence settle before teardown.
      await Future<void>.delayed(Duration.zero);
    });

    test('practice mode has no deadline and counts elapsed time', () async {
      var now = DateTime(2026, 10, 17, 9);
      final provider = buildProvider(now: () => now);

      await provider.startQuiz(
        subject: AppConstants.chemistry,
        questionCount: 10,
        mode: QuizMode.practice,
      );

      expect(provider.mode, QuizMode.practice);
      expect(provider.examEndsAt, isNull);

      now = now.add(const Duration(hours: 2));
      provider.handleAppResume();

      expect(provider.isCompleted, isFalse);
      expect(provider.autoSubmitted, isFalse);
      expect(provider.lastSession, isNull);
      expect(provider.elapsedSeconds, 2 * 3600);
    });

    test('quitting an attempt discards it without persisting', () async {
      final provider = buildProvider();

      await provider.startQuiz(
        subject: AppConstants.biology,
        questionCount: 10,
      );
      provider.selectOption(0, 1);
      provider.quitAttempt();

      expect(provider.isCompleted, isFalse);
      expect(provider.questions, isEmpty);
      expect(provider.lastSession, isNull);

      final db = await helper.database;
      expect(await db.query('local_quiz_sessions'), isEmpty);
    });

    test('All Subjects draws a mixed set across every subject', () async {
      final provider = buildProvider();

      await provider.startQuiz(
        subject: AppConstants.allSubjects,
        questionCount: 10,
      );

      expect(provider.questions, hasLength(10));
      expect(
        provider.questions.map((question) => question.subject).toSet().length,
        greaterThan(1),
      );
    });
  });
}
