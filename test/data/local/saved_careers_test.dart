import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/models/saved_career.dart';
import 'package:prepup_ai/providers/career_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    helper = DatabaseHelper.instance;
    // Bookmarks are UNIQUE per role, so clear leftovers between tests.
    final db = await helper.database;
    await db.delete('saved_careers');
  });

  tearDown(() async {
    await helper.dispose();
  });

  SavedCareer buildCareer({
    String title = 'Mechanical Engineer',
    int matchPercentage = 99,
    DateTime? savedAt,
    List<String> subjects = const ['Physics', 'Mathematics'],
  }) {
    return SavedCareer(
      careerTitle: title,
      summary: 'You build and fix machines.',
      requiredSubjects: subjects,
      matchPercentage: matchPercentage,
      savedAt: savedAt ?? DateTime(2026, 10, 17, 9, 30),
    );
  }

  group('saved_careers schema', () {
    test('the saved_careers table is created on a fresh database', () async {
      final db = await helper.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = tables.map((row) => row['name'] as String).toSet();

      expect(names, contains('saved_careers'));
    });

    test('the database schema version is 2', () async {
      final db = await helper.database;

      expect(await db.getVersion(), 2);
    });
  });

  group('DatabaseHelper saved careers', () {
    test('a saved career round-trips every field', () async {
      final career = buildCareer(
        subjects: const ['Physics', 'Mathematics', 'Chemistry'],
      );
      await helper.saveSavedCareer(career);

      final stored = (await helper.getSavedCareers()).single;

      expect(stored.careerTitle, career.careerTitle);
      expect(stored.summary, career.summary);
      expect(stored.requiredSubjects, career.requiredSubjects);
      expect(stored.matchPercentage, career.matchPercentage);
      expect(stored.savedAt, career.savedAt);
      expect(stored.id, isNotNull);
    });

    test('bookmarks survive closing and reopening the database', () async {
      await helper.saveSavedCareer(buildCareer(title: 'Ecologist'));

      // Simulate an app restart: close the connection, then read again.
      await helper.dispose();
      final afterRestart = await helper.getSavedCareers();

      expect(afterRestart, hasLength(1));
      expect(afterRestart.single.careerTitle, 'Ecologist');
    });

    test('re-saving the same role updates instead of duplicating', () async {
      await helper.saveSavedCareer(buildCareer(matchPercentage: 91));
      await helper.saveSavedCareer(buildCareer(matchPercentage: 97));

      final stored = await helper.getSavedCareers();

      expect(stored, hasLength(1));
      expect(stored.single.matchPercentage, 97);
    });

    test('careers are returned newest first', () async {
      await helper.saveSavedCareer(
        buildCareer(title: 'Older', savedAt: DateTime(2026, 10, 1)),
      );
      await helper.saveSavedCareer(
        buildCareer(title: 'Newer', savedAt: DateTime(2026, 10, 16)),
      );

      final stored = await helper.getSavedCareers();

      expect(stored.map((c) => c.careerTitle), ['Newer', 'Older']);
    });

    test('deleting a bookmark removes only that row', () async {
      await helper.saveSavedCareer(buildCareer(title: 'Ecologist'));
      await helper.saveSavedCareer(buildCareer(title: 'Pharmacist'));

      final target = (await helper.getSavedCareers())
          .firstWhere((c) => c.careerTitle == 'Ecologist');
      await helper.deleteSavedCareer(target.id!);

      final remaining = await helper.getSavedCareers();

      expect(remaining, hasLength(1));
      expect(remaining.single.careerTitle, 'Pharmacist');
    });
  });

  group('CareerProvider persistence', () {
    test('loadSavedCareers starts empty and reads stored rows', () async {
      await helper.saveSavedCareer(buildCareer(title: 'Data Scientist'));

      final provider = CareerProvider(databaseHelper: helper);
      expect(provider.savedCareers, isEmpty);
      expect(provider.savedCareersLoaded, isFalse);

      await provider.loadSavedCareers();

      expect(provider.savedCareersLoaded, isTrue);
      expect(provider.savedCareers.single.careerTitle, 'Data Scientist');
    });

    test('saveCurrentMatch persists the matched role', () async {
      final provider = CareerProvider(databaseHelper: helper)
        ..setWorkEnvironment(WorkEnvironment.indoor)
        ..setActivityPreference(ActivityPreference.building)
        ..setFavoriteSubject('Physics');

      final expected = provider.match();
      final saved = await provider.saveCurrentMatch();

      expect(saved.careerTitle, expected.title);
      expect(saved.matchPercentage, expected.matchPercentage);
      expect(saved.requiredSubjects, expected.subjects);

      // A second provider reading the same database proves it was persisted,
      // not just held in memory.
      final reloaded = CareerProvider(databaseHelper: helper);
      await reloaded.loadSavedCareers();
      expect(reloaded.savedCareers.single.careerTitle, expected.title);
    });

    test('removeSavedCareer deletes the bookmark from the cache', () async {
      final provider = CareerProvider(databaseHelper: helper)
        ..setFavoriteSubject('Biology');
      await provider.saveCurrentMatch();

      final id = provider.savedCareers.single.id!;
      await provider.removeSavedCareer(id);

      expect(provider.savedCareers, isEmpty);
      expect(await helper.getSavedCareers(), isEmpty);
    });
  });
}
