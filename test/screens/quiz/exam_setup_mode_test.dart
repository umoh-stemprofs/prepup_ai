// Phase 09, task 9.2: the exam-setup mode selector. Choosing Practice flips
// the duration hint and START TEST NOW launches an untimed quiz.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';
import 'package:prepup_ai/screens/quiz/exam_screen.dart';
import 'package:prepup_ai/screens/quiz/exam_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    DatabaseHelper.debugDatabaseFileName = 'test_exam_setup.db';
  });

  testWidgets('choosing Practice starts an untimed quiz', (tester) async {
    final quiz = QuizProvider(databaseHelper: DatabaseHelper.instance);
    addTearDown(quiz.dispose);

    await tester.runAsync(
      () => DatabaseHelper.instance.seedQuestionsFromAssetsIfEmpty(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<QuizProvider>.value(value: quiz),
        ],
        child: const MaterialApp(home: ExamSetupScreen()),
      ),
    );
    await tester.pump();

    // Timed by default, so the practice-only hint is absent.
    expect(find.text('No time limit'), findsNothing);

    // The mode cards sit below the 11 subject cards; scroll them into view.
    await tester.scrollUntilVisible(
      find.text('Practice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Practice'));
    await tester.pump();
    expect(find.text('No time limit'), findsOneWidget);

    await tester.tap(find.text('START TEST NOW'));
    await tester.pump();

    // Let the route transition and the question fetch finish. Bounded pumps:
    // practice mode runs a 1s ticker that pumpAndSettle would chase forever.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(ExamScreen), findsOneWidget);
    expect(quiz.mode, QuizMode.practice);
    expect(quiz.examEndsAt, isNull);

    // Drop the attempt so the ticker is cancelled before the test ends.
    quiz.quitAttempt();
    await tester.pump();
  });
}
