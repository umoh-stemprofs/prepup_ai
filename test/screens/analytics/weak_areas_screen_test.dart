import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';
import 'package:prepup_ai/screens/analytics/weak_areas_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    DatabaseHelper.debugDatabaseFileName = 'test_weak_areas_screen.db';
    helper = DatabaseHelper.instance;

    final db = await helper.database;
    await db.delete('local_weak_areas');

    await db.insert('local_weak_areas', {
      'session_uuid': 'session-1',
      'subject': 'Chemistry',
      'syllabus_topic': 'Organic Chemistry',
      'incorrect_count': 3,
      'total_count': 4,
    });
    await db.insert('local_weak_areas', {
      'session_uuid': 'session-1',
      'subject': 'Mathematics',
      'syllabus_topic': 'Basic Algebra',
      'incorrect_count': 0,
      'total_count': 5,
    });
  });

  tearDown(() async {
    await helper.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<QuizProvider>.value(
        value: QuizProvider(databaseHelper: helper),
        child: const MaterialApp(home: WeakAreasScreen()),
      ),
    );
    await tester.pump();
    // Let the aggregated read complete. Bounded pumps rather than
    // pumpAndSettle: the loading spinner animates forever while it is shown.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('renders the design header and the red-topic card', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Topics To Practice'), findsOneWidget);
    expect(find.text('Focus on red topics first'), findsOneWidget);
    expect(find.text('NEEDS PRACTICE'), findsOneWidget);
    expect(find.text('Organic Chemistry'), findsOneWidget);
    // Phase 10.2 count, in the export's sub-title slot.
    expect(
      find.text('Chemistry: Organic Chemistry — 1/4 Correct (25%)'),
      findsOneWidget,
    );
    expect(find.text('PRACTICE RED TOPICS NOW'), findsOneWidget);
  });

  testWidgets('a clean topic renders the GOOD badge', (tester) async {
    await pumpScreen(tester);

    expect(find.text('GOOD'), findsOneWidget);
    expect(find.text('Basic Algebra'), findsOneWidget);
    expect(
      find.text('Mathematics: Basic Algebra — 5/5 Correct (100%)'),
      findsOneWidget,
    );
  });
}
