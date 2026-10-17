import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/models/saved_career.dart';
import 'package:prepup_ai/providers/career_provider.dart';
import 'package:prepup_ai/screens/career/saved_careers_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_saved_careers_screen.db';
    helper = DatabaseHelper.instance;
  });

  tearDown(() async {
    await helper.dispose();
  });

  SavedCareer career({
    String title = 'Mechanical Engineer',
    int matchPercentage = 99,
    DateTime? savedAt,
  }) {
    return SavedCareer(
      careerTitle: title,
      summary: 'You build and fix machines.',
      requiredSubjects: const ['Physics', 'Mathematics'],
      matchPercentage: matchPercentage,
      savedAt: savedAt ?? DateTime(2026, 10, 17),
    );
  }

  /// Seeds the cache and returns a provider that already holds the rows, so
  /// the first frame renders the list instead of an endless spinner.
  Future<CareerProvider> seed(List<SavedCareer> careers) async {
    final db = await helper.database;
    await db.delete('saved_careers');
    for (final item in careers) {
      await helper.saveSavedCareer(item);
    }
    final provider = CareerProvider(databaseHelper: helper);
    await provider.loadSavedCareers();
    return provider;
  }

  test('formatSavedDate renders a compact day-month-year label', () {
    expect(formatSavedDate(DateTime(2026, 10, 7)), '7 Oct 2026');
    expect(formatSavedDate(DateTime(2026, 1, 31)), '31 Jan 2026');
    expect(formatSavedDate(DateTime(2025, 12, 1)), '1 Dec 2025');
  });

  Widget wrap(CareerProvider provider) {
    return ChangeNotifierProvider<CareerProvider>.value(
      value: provider,
      child: const MaterialApp(home: SavedCareersScreen()),
    );
  }

  testWidgets('shows an empty state when nothing is bookmarked', (
    tester,
  ) async {
    final provider = await tester.runAsync(() => seed(const []));

    await tester.pumpWidget(wrap(provider!));
    await tester.pump();

    expect(find.text('No saved careers yet'), findsOneWidget);
    expect(find.textContaining('SAVE THIS JOB'), findsOneWidget);
  });

  testWidgets('lists bookmarked roles newest first', (tester) async {
    final provider = await tester.runAsync(
      () => seed([
        career(title: 'Older Role', savedAt: DateTime(2026, 10, 1)),
        career(title: 'Newest Role', savedAt: DateTime(2026, 10, 16)),
      ]),
    );

    await tester.pumpWidget(wrap(provider!));
    await tester.pump();

    expect(find.text('Newest Role'), findsOneWidget);
    expect(find.text('Older Role'), findsOneWidget);

    final newestY = tester.getTopLeft(find.text('Newest Role')).dy;
    final olderY = tester.getTopLeft(find.text('Older Role')).dy;
    expect(newestY, lessThan(olderY));
  });

  testWidgets('tapping a card opens its detail with summary and score', (
    tester,
  ) async {
    final provider = await tester.runAsync(
      () => seed([career(title: 'Ecologist', matchPercentage: 93)]),
    );

    await tester.pumpWidget(wrap(provider!));
    await tester.pump();

    await tester.tap(find.text('Ecologist'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Career'), findsOneWidget);
    expect(find.text('You build and fix machines.'), findsOneWidget);
    expect(find.text('93% Match'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
  });

  testWidgets('swiping a card removes it from the list and the cache', (
    tester,
  ) async {
    final provider = await tester.runAsync(
      () => seed([
        career(title: 'Pharmacist', savedAt: DateTime(2026, 10, 16)),
        career(title: 'Ecologist', savedAt: DateTime(2026, 10, 1)),
      ]),
    );

    await tester.pumpWidget(wrap(provider!));
    await tester.pump();

    await tester.drag(find.text('Pharmacist'), const Offset(-600, 0));
    // Run the dismiss animation to completion: onDismissed only fires after it.
    await tester.pumpAndSettle();

    // Let the real sqflite delete finish while the tree is still mounted.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(find.text('Pharmacist'), findsNothing);
    expect(find.text('Ecologist'), findsOneWidget);

    final stored = await tester.runAsync(() => helper.getSavedCareers());
    expect(stored!.map((c) => c.careerTitle), ['Ecologist']);

    // Let the "Removed Pharmacist" snackbar timer expire so no timer is left
    // pending when the test ends.
    await tester.pump(const Duration(seconds: 5));
  });
}
