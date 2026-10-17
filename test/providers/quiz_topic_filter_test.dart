import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/core/constants.dart';
import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/local/questions_local_service.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';

/// "PRACTICE RED TOPICS NOW" must drill the missed syllabus topic, and a
/// finished attempt must queue its envelope against the account that earned it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late QuestionsLocalService localService;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_quiz_topic_filter.db';
    helper = DatabaseHelper.instance;
    localService = QuestionsLocalService(helper);

    final db = await helper.database;
    await db.delete('local_quiz_sessions');
    await db.delete('local_weak_areas');
    await db.delete('pending_sync_results');
    await helper.seedQuestionsFromAssetsIfEmpty();
  });

  tearDown(() async {
    await helper.dispose();
  });

  QuizProvider buildProvider({String? Function()? userIdProvider}) {
    return QuizProvider(
      databaseHelper: helper,
      questionsLocalService: localService,
      userIdProvider: userIdProvider,
    );
  }

  test('a topic-scoped quiz only contains that sub-topic', () async {
    final provider = buildProvider();

    await provider.startQuiz(
      subject: AppConstants.mathematics,
      questionCount: 10,
      syllabusTopic: 'Algebra',
    );

    expect(provider.questions, isNotEmpty);
    for (final question in provider.questions) {
      expect(question.subject, AppConstants.mathematics);
      expect(question.syllabusTopic, 'Algebra');
    }
  });

  test(
    'an empty topic yields no questions instead of widening to the subject',
    () async {
      final provider = buildProvider();

      await provider.startQuiz(
        subject: AppConstants.mathematics,
        questionCount: 10,
        syllabusTopic: 'Topics That Do Not Exist',
      );

      // Widening here would silently reintroduce the old wrong-topic quiz.
      expect(provider.questions, isEmpty);
      expect(provider.totalQuestions, 0);
    },
  );

  test('omitting the topic keeps the whole-subject pool', () async {
    final provider = buildProvider();

    await provider.startQuiz(
      subject: AppConstants.mathematics,
      questionCount: 5,
    );

    expect(provider.questions, hasLength(5));
  });

  test(
    'finishing enqueues one owner-scoped envelope with its weak areas',
    () async {
      final provider = buildProvider(userIdProvider: () => 'user-a');

      await provider.startQuiz(
        subject: AppConstants.mathematics,
        questionCount: 4,
        syllabusTopic: 'Algebra',
      );
      expect(provider.questions, hasLength(4));

      // Two right, two wrong, so the attempt produces a mixed topic breakdown.
      for (var i = 0; i < 4; i++) {
        final correct = provider.questions[i].correctOptionIndex;
        provider.selectOption(i, i.isEven ? correct : (correct + 1) % 4);
      }

      await provider.finishQuiz();

      expect(provider.lastSession, isNotNull);
      expect(await helper.pendingSyncResultCount(userId: 'user-a'), 1);

      final db = await helper.database;
      final sessions = await helper.getRecentSessions();
      expect(sessions.single.sessionUuid, provider.lastSession!.sessionUuid);

      // Weak areas are now linked to the attempt they came from.
      final areas = await db.query(
        'local_weak_areas',
        where: 'session_uuid = ?',
        whereArgs: [provider.lastSession!.sessionUuid],
      );
      expect(areas, hasLength(1));
      expect(areas.single['syllabus_topic'], 'Algebra');
      expect(areas.single['incorrect_count'], 2);
      expect(areas.single['total_count'], 4);
    },
  );

  test('a guest attempt stays local and is not queued', () async {
    final provider = buildProvider();

    await provider.startQuiz(subject: AppConstants.physics, questionCount: 2);
    provider.selectOption(0, provider.questions[0].correctOptionIndex);
    await provider.finishQuiz();

    expect(await helper.getRecentSessions(), hasLength(1));
    expect(await helper.pendingSyncResultCount(), 0);
  });
}
