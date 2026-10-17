import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prepup_ai/main.dart';

void main() {
  const viewports = <String, Size>{
    'small phone 320x480': Size(320, 480),
    'compact phone 360x640': Size(360, 640),
    'modern phone 390x844': Size(390, 844),
    'tablet 768x1024': Size(768, 1024),
    'desktop-ish 800x600': Size(800, 600),
  };

  const actions = <String>[
    'Start Practising',
    'My Weak Areas',
    'STEM Career Helper',
    'Saved Careers',
  ];

  for (final entry in viewports.entries) {
    testWidgets('dashboard fits and scrolls at ${entry.key}', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = entry.value;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const PrepUpApp());
      await tester.pump();

      // A RenderFlex overflow is reported as a test exception.
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to PrepUp AI'), findsOneWidget);

      for (final label in actions) {
        await tester.scrollUntilVisible(
          find.text(label),
          120,
          scrollable: find.byType(Scrollable).first,
        );

        expect(
          find.text(label),
          findsOneWidget,
          reason: '$label at ${entry.key}',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at ${entry.key}',
        );
      }
    });
  }

  testWidgets('dashboard groups actions under Practice and Career', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PrepUpApp());
    await tester.pump();

    expect(find.text('PRACTICE'), findsOneWidget);

    // CAREER sits below PRACTICE, so scroll it into view before asserting.
    await tester.scrollUntilVisible(
      find.text('CAREER'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CAREER'), findsOneWidget);
  });
}
