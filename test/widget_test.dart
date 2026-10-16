// Phase 02 smoke test: the app boots straight to the guest placeholder home.

import 'package:flutter_test/flutter_test.dart';

import 'package:prepup_ai/main.dart';

void main() {
  testWidgets('boots to guest placeholder home', (WidgetTester tester) async {
    await tester.pumpWidget(const PrepUpApp());

    expect(find.text('PrepUp AI'), findsWidgets);
    expect(find.text('Welcome to PrepUp AI'), findsOneWidget);
    expect(find.textContaining('guest'), findsOneWidget);
    expect(find.text('Start Practising'), findsOneWidget);
  });
}
