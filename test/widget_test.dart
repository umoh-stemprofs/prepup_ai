// Phase 02 smoke test: the app boots straight to the guest shell.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prepup_ai/main.dart';
import 'package:prepup_ai/screens/dashboard/main_shell.dart';

void main() {
  testWidgets('boots to guest shell', (WidgetTester tester) async {
    await tester.pumpWidget(const PrepUpApp());
    await tester.pump();

    // The root is a real MaterialApp wrapping the bottom-nav shell.
    final materialAppFinder = find.byType(MaterialApp);
    expect(materialAppFinder, findsOneWidget);

    final element = materialAppFinder.evaluate().first;
    final statefulElement = element as StatefulElement;
    final materialAppWidget = statefulElement.widget as MaterialApp;
    expect(materialAppWidget.home, isA<MainShell>());
  });
}
