import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/models/question.dart';

Question _sample() => const Question(
      id: 'q-math-001',
      subject: 'Mathematics',
      syllabusTopic: 'Algebra — Linear Equations',
      questionText: 'Solve for x: 2x + 6 = 14',
      options: <String>['x = 2', 'x = 4', 'x = 8', 'x = 10'],
      correctOptionIndex: 1,
      explanation: '2x + 6 = 14 → 2x = 8 → x = 4.',
    );

void main() {
  group('Question serialization', () {
    test('fromJson/toJson round-trip preserves every field', () {
      final Question q = _sample();

      final Question restored = Question.fromJson(q.toJson());

      expect(restored, equals(q));
      expect(restored.toJson()['syllabus_topic'], 'Algebra — Linear Equations');
      expect(restored.toJson()['correct_option_index'], 1);
    });

    test('fromMap/toMap round-trip preserves every field', () {
      final Question q = _sample();

      expect(Question.fromMap(q.toMap()), equals(q));
    });
  });

  group('Question.shuffleOptions', () {
    // Task 3.2: remapping must hold across many runs.
    test('remaps correctOptionIndex correctly over 200 runs', () {
      for (int run = 0; run < 200; run++) {
        final Random rng = Random(run);
        final Question original = _sample();
        final String correctText = original.options[original.correctOptionIndex];

        final Question shuffled = original.shuffleOptions(random: rng);

        // Same option multiset, just reordered.
        expect(
          List<String>.from(shuffled.options)..sort(),
          equals(List<String>.from(original.options)..sort()),
          reason: 'run $run: options changed',
        );

        // The remapped index still points at the correct answer text.
        expect(
          shuffled.options[shuffled.correctOptionIndex],
          equals(correctText),
          reason: 'run $run: correctOptionIndex remapped incorrectly',
        );
      }
    });

    test('is pure — the original question is never mutated', () {
      final Question original = _sample();
      final Question before = Question.fromJson(original.toJson());

      original.shuffleOptions(random: Random(42));

      expect(original, equals(before));
    });

    test('handles duplicate option texts without losing the index', () {
      const Question dupes = Question(
        id: 'q-dup-001',
        subject: 'Mathematics',
        syllabusTopic: 'Arithmetic',
        questionText: 'What is 2 + 2?',
        options: <String>['4', '4', '5', '6'],
        correctOptionIndex: 1,
        explanation: '2 + 2 = 4.',
      );

      for (int run = 0; run < 100; run++) {
        final Question shuffled = dupes.shuffleOptions(random: Random(run));

        expect(shuffled.options.length, equals(4));
        expect(shuffled.options[shuffled.correctOptionIndex], equals('4'));
      }
    });
  });
}
