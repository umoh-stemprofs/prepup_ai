import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/core/constants.dart';
import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/local/questions_local_service.dart';
import 'package:prepup_ai/models/quiz_session.dart';
import 'package:prepup_ai/models/weak_area.dart';

final DateTime _completedAt = DateTime(2026, 10, 17, 9);
final DateTime _later = DateTime(2026, 10, 17, 11);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_database_helper.db';
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    await helper.dispose();
  });

  test('opens an in-memory database and creates the offline schema', () async {
    final db = await helper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    final tableNames = tables.map((row) => row['name'] as String).toSet();

    expect(
      tableNames,
      containsAll([
        'local_questions',
        'local_quiz_sessions',
        'local_weak_areas',
        'pending_sync_results',
      ]),
    );
  });

  test(
    'seedQuestionsFromAssetsIfEmpty loads all 60 seed questions once',
    () async {
      // First seed call.
      await helper.seedQuestionsFromAssetsIfEmpty();
      expect(await helper.getQuestionCount(), equals(60));

      // Second call should be a no-op.
      await helper.seedQuestionsFromAssetsIfEmpty();
      expect(await helper.getQuestionCount(), equals(60));
    },
  );

  test('seed populates every subject from AppConstants.subjects', () async {
    await helper.seedQuestionsFromAssetsIfEmpty();

    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT subject, COUNT(*) AS c FROM local_questions GROUP BY subject',
    );
    final counts = {
      for (final row in rows) row['subject'] as String: (row['c'] as int?) ?? 0,
    };

    for (final subject in AppConstants.subjects) {
      expect(
        counts.containsKey(subject),
        isTrue,
        reason: 'Missing subject in seed: $subject',
      );
    }

    expect(
      counts[AppConstants.mathematics],
      equals(10),
      reason: 'Expected 10 Mathematics questions in the seed.',
    );
    expect(
      counts[AppConstants.englishLanguage],
      equals(10),
      reason: 'Expected 10 English Language questions in the seed.',
    );
  });

  test(
    'getQuestionsBySubject returns random questions for a subject',
    () async {
      await helper.seedQuestionsFromAssetsIfEmpty();

      final service = QuestionsLocalService(helper);
      final questions = await service.getQuestionsBySubject(
        AppConstants.mathematics,
        limit: 3,
      );

      expect(questions.length, lessThanOrEqualTo(3));
      for (final question in questions) {
        expect(question['subject'], equals(AppConstants.mathematics));
        expect(question['options'], isA<List<String>>());
        expect(question['options'].length, equals(4));
        expect(question['correct_option_index'], anyOf([0, 1, 2, 3]));
        expect(question['explanation'], isA<String>());
        expect((question['explanation'] as String).isNotEmpty, isTrue);
      }
    },
  );

  test('getQuestionsByTopic returns only the requested sub-topic', () async {
    await helper.seedQuestionsFromAssetsIfEmpty();

    final service = QuestionsLocalService(helper);
    final questions = await service.getQuestionsByTopic(
      AppConstants.mathematics,
      'Algebra',
      limit: 10,
    );

    expect(questions, isNotEmpty);
    for (final question in questions) {
      expect(question['subject'], equals(AppConstants.mathematics));
      expect(question['syllabus_topic'], equals('Algebra'));
    }
  });

  test('both queues record which account owns the write', () async {
    final db = await helper.database;

    final resultColumns = await db.rawQuery(
      'PRAGMA table_info(pending_sync_results)',
    );
    expect(
      resultColumns.map((column) => column['name'] as String),
      containsAll(['session_uuid', 'user_id', 'payload', 'created_at']),
    );

    final careerColumns = await db.rawQuery(
      'PRAGMA table_info(pending_career_sync)',
    );
    expect(
      careerColumns.map((column) => column['name'] as String),
      containsAll(['user_id', 'career_title']),
    );
  });

  test(
    'enqueuePendingSyncResult stores one envelope per attempt, owner-scoped',
    () async {
      final db = await helper.database;
      await db.delete('pending_sync_results');

      final session = QuizSession(
        sessionUuid: 'session-1',
        subject: AppConstants.mathematics,
        score: 3,
        totalQuestions: 4,
        scorePercentage: 75,
        isPass: true,
        timeSpentSeconds: 120,
        completedAt: _completedAt,
      );
      const areas = [
        WeakArea(
          subject: AppConstants.mathematics,
          syllabusTopic: 'Algebra',
          incorrectCount: 1,
          totalCount: 4,
        ),
      ];

      await helper.enqueuePendingSyncResult(
        session,
        weakAreas: areas,
        userId: 'user-a',
      );
      // Same attempt again: AM-3 says upsert, not duplicate.
      await helper.enqueuePendingSyncResult(
        session,
        weakAreas: areas,
        userId: 'user-a',
      );

      expect(await helper.pendingSyncResultCount(), 1);

      final rows = await helper.getPendingSyncResults(userId: 'user-a');
      expect(rows.single['session_uuid'], 'session-1');

      final payload =
          jsonDecode(rows.single['payload'] as String) as Map<String, dynamic>;
      expect(payload['session'], isA<Map<String, dynamic>>());
      expect(payload['weak_areas'], hasLength(1));

      // A guest attempt is local history only: no owner, no queue row.
      await helper.enqueuePendingSyncResult(
        QuizSession(
          sessionUuid: 'session-guest',
          subject: AppConstants.physics,
          score: 1,
          totalQuestions: 2,
          scorePercentage: 50,
          isPass: true,
          timeSpentSeconds: 60,
          completedAt: _completedAt,
        ),
        weakAreas: const [],
      );
      expect(await helper.pendingSyncResultCount(), 1);
      expect(await helper.getPendingSyncResults(userId: 'user-b'), isEmpty);
    },
  );

  test('getRecentSessions returns the newest attempt first', () async {
    final db = await helper.database;
    await db.delete('local_quiz_sessions');

    await helper.saveQuizSession(
      QuizSession(
        sessionUuid: 'older',
        subject: AppConstants.mathematics,
        score: 2,
        totalQuestions: 4,
        scorePercentage: 50,
        isPass: true,
        timeSpentSeconds: 90,
        completedAt: _completedAt,
      ),
    );
    await helper.saveQuizSession(
      QuizSession(
        sessionUuid: 'newer',
        subject: AppConstants.physics,
        score: 3,
        totalQuestions: 4,
        scorePercentage: 75,
        isPass: true,
        timeSpentSeconds: 80,
        completedAt: _later,
      ),
    );

    final history = await helper.getRecentSessions(limit: 1);

    expect(history, hasLength(1));
    expect(history.single.sessionUuid, 'newer');
  });

  test(
    'getAllSubjectsQuestionCounts returns counts for all subjects',
    () async {
      await helper.seedQuestionsFromAssetsIfEmpty();

      final service = QuestionsLocalService(helper);
      final counts = await service.getAllSubjectsQuestionCounts();

      for (final subject in AppConstants.subjects) {
        expect(
          counts.containsKey(subject),
          isTrue,
          reason: 'Expected counts for subject: $subject',
        );
      }
      expect(counts[AppConstants.mathematics], equals(10));
      expect(counts[AppConstants.englishLanguage], equals(10));
    },
  );
}
