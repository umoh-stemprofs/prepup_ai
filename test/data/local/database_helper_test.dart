import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/core/constants.dart';
import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/local/questions_local_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
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

  test('seedQuestionsFromAssetsIfEmpty loads all 60 seed questions once',
      () async {
    // First seed call.
    await helper.seedQuestionsFromAssetsIfEmpty();
    expect(await helper.getQuestionCount(), equals(60));

    // Second call should be a no-op.
    await helper.seedQuestionsFromAssetsIfEmpty();
    expect(await helper.getQuestionCount(), equals(60));
  });

  test('seed populates every subject from AppConstants.subjects',
      () async {
    await helper.seedQuestionsFromAssetsIfEmpty();

    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT subject, COUNT(*) AS c FROM local_questions GROUP BY subject',
    );
    final counts = {
      for (final row in rows)
        row['subject'] as String: (row['c'] as int?) ?? 0
    };

    for (final subject in AppConstants.subjects) {
      expect(counts.containsKey(subject), isTrue,
          reason: 'Missing subject in seed: $subject');
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

  test('getQuestionsBySubject returns random questions for a subject',
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
  });

  test('getAllSubjectsQuestionCounts returns counts for all subjects',
      () async {
    await helper.seedQuestionsFromAssetsIfEmpty();

    final service = QuestionsLocalService(helper);
    final counts = await service.getAllSubjectsQuestionCounts();

    for (final subject in AppConstants.subjects) {
      expect(counts.containsKey(subject), isTrue,
          reason: 'Expected counts for subject: $subject');
    }
    expect(counts[AppConstants.mathematics], equals(10));
    expect(counts[AppConstants.englishLanguage], equals(10));
  });
}
