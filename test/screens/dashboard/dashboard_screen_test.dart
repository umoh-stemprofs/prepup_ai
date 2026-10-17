import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/providers/auth_provider.dart';
import 'package:prepup_ai/providers/career_provider.dart';
import 'package:prepup_ai/providers/quiz_provider.dart';
import 'package:prepup_ai/screens/dashboard/main_shell.dart';
import 'package:prepup_ai/screens/dashboard/dashboard_screen.dart';

/// Phase 11.3: dashboard renders the three quick-start cards, the
/// empty-history state for a new user, and the pending-sync badge logic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    DatabaseHelper.debugDatabaseFileName = 'test_dashboard.db';
  });

  Widget wrap({required bool hasHistory, int pendingSyncCount = 0}) {
    final AuthProvider auth = AuthProvider.guest();
    final CareerProvider career = CareerProvider();
    career.setPendingSyncCount(pendingSyncCount);

    // The DashboardScreen reads _historyLoaded from its own
    // _loadHistory() call; hasHistory here reflects a completed load.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<QuizProvider>.value(
          value: QuizProvider(databaseHelper: DatabaseHelper.instance),
        ),
        ChangeNotifierProvider<CareerProvider>.value(value: career),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
  }

  testWidgets('renders the hero card and two choice cards', (tester) async {
    await tester.pumpWidget(wrap(hasHistory: false));
    await tester.pump();

    // Hero card
    expect(find.text("Today's Practice"), findsOneWidget);
    expect(find.text('Chemistry'), findsOneWidget);
    expect(find.text('10 Quick Questions'), findsOneWidget);
    expect(find.text('START PRACTICE NOW'), findsOneWidget);
    // Choice cards
    expect(find.text('Practice Other Subjects'), findsOneWidget);
    expect(find.text('Check Weak Topics'), findsOneWidget);
  });

  testWidgets('shows the empty-history state for a new user', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hasHistory: false));
    await tester.pump();

    expect(find.text('No attempts yet'), findsOneWidget);
    expect(
      find.text('Finish a quiz and your latest results will show up here.'),
      findsOneWidget,
    );
  });

  testWidgets('shows recent attempts when history exists', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hasHistory: true));
    await tester.pump();

    expect(find.text('No attempts yet'), findsNothing);
  });

  testWidgets('shows the pending-sync banner when a queue exists', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hasHistory: false, pendingSyncCount: 2));
    await tester.pump();

    expect(find.text('2 saved careers waiting to sync'), findsOneWidget);
  });

  testWidgets('the banner shows the count as soon as set', (tester) async {
    final CareerProvider career = CareerProvider();
    career.setPendingSyncCount(2);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CareerProvider>.value(value: career),
        ],
        child: MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('2 saved careers waiting to sync'), findsOneWidget);
  });

  testWidgets('the banner hides when the count is set to zero', (tester) async {
    final CareerProvider career = CareerProvider();
    career.setPendingSyncCount(0);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CareerProvider>.value(value: career),
        ],
        child: MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('saved careers waiting to sync'), findsNothing);
  });

  testWidgets('does not show the pending-sync banner when the queue is empty',
    (tester) async {
    await tester.pumpWidget(wrap(hasHistory: false, pendingSyncCount: 0));
    await tester.pump();

    expect(find.text('saved careers waiting to sync'), findsNothing);
  });

  testWidgets('hero and choice cards open the correct routes', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(hasHistory: false));
    await tester.pump();

    // Hero card → exam setup (practice mode)
    await tester.tap(find.text('START PRACTICE NOW'));
    await tester.pump();
    expect(find.text('Choose Subject'), findsOneWidget);

    // Navigate back to dashboard
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    // Practice Other Subjects → exam setup
    await tester.tap(find.text('Practice Other Subjects'));
    await tester.pump();
    expect(find.text('Choose Subject'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    // Check Weak Topics → weak areas screen
    await tester.tap(find.text('Check Weak Topics'));
    await tester.pump();
    expect(find.text('Topics To Practice'), findsOneWidget);
  });

  testWidgets('Practice and Career tabs are reachable from the shell', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The shell owns a NavigationBar with four destinations in this order:
    // Dashboard (0), Practice (1), Career (2), Profile (3).
    await _tapShellTab(tester, 1); // Practice
    await tester.pump();
    expect(find.text('Choose Subject'), findsOneWidget);

    await _tapShellTab(tester, 2); // Career
    await tester.pump();
    expect(find.text('Find Jobs For You'), findsOneWidget);

    await _tapShellTab(tester, 3); // Profile
    await tester.pump();
    expect(find.text('Profile'), findsOneWidget);
  });
}

/// Builds the shell with a fresh tab, taps its [index] NavigationDestination,
/// and rebuilds so the chosen tab body stays mounted.
Future<void> _tapShellTab(WidgetTester tester, int index) async {
  await tester.pumpWidget(const MainShell());
  await tester.pump();
  expect(find.byType(NavigationDestination), findsNWidgets(4));
  await tester.tap(find.byType(NavigationDestination).at(index));
  await tester.pump();
}

