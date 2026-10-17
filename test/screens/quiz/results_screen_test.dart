import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/models/quiz_session.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';
import 'package:prepup_ai/providers/results_provider.dart';
import 'package:prepup_ai/screens/quiz/results_screen.dart';

/// A quiz that has already finished, without touching the database.
class _FinishedQuiz extends QuizProvider {
  _FinishedQuiz(this._session);

  final QuizSession _session;

  @override
  QuizSession? get lastSession => _session;

  @override
  int get correctCount => _session.score;

  @override
  int get wrongCount => _session.totalQuestions - _session.score;

  @override
  int get totalQuestions => _session.totalQuestions;
}

QuizSession session({required int score}) => QuizSession(
  sessionUuid: 'session-1',
  subject: 'Chemistry',
  score: score,
  totalQuestions: 10,
  scorePercentage: score * 10,
  isPass: score >= 5,
  timeSpentSeconds: 300,
  completedAt: DateTime(2026, 10, 17),
);

Widget wrap(QuizSession attempt) {
  final quiz = _FinishedQuiz(attempt);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<QuizProvider>.value(value: quiz),
      Provider<ResultsProvider>(create: (_) => ResultsProvider(quiz)),
    ],
    child: const MaterialApp(home: ResultsScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    DatabaseHelper.debugDatabaseFileName = 'test_results_screen.db';
  });

  testWidgets('a passing attempt shows the pass card and its actions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(session(score: 7)));
    await tester.pump();

    expect(find.text('YOU PASSED!'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('Brilliant performance!'), findsOneWidget);
    expect(find.text('Chemistry · 10 Questions Answered'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.text('CHECK MY ANSWERS'), findsOneWidget);
    expect(find.text('GO TO HOME PAGE'), findsOneWidget);
  });

  testWidgets('a failing attempt shows TRY AGAIN and the review actions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(session(score: 4)));
    await tester.pump();

    // The badge and the retry action both read TRY AGAIN, as in the export.
    expect(find.text('TRY AGAIN'), findsNWidgets(2));
    expect(find.text('40%'), findsOneWidget);
    expect(
      find.text("Don't give up! Try again to score higher."),
      findsOneWidget,
    );
    expect(find.text('REVIEW MISTAKES'), findsOneWidget);
  });

  testWidgets('tapping Wrong opens the weak-areas list', (tester) async {
    await tester.pumpWidget(wrap(session(score: 4)));
    await tester.pump();

    await tester.tap(find.text('Wrong'));
    await tester.pump();
    // Let the route transition and the weak-area query finish. Bounded pumps
    // rather than pumpAndSettle: the loading spinner never settles while the
    // query is outstanding.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Topics To Practice'), findsOneWidget);
  });
}
