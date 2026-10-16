import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:prepup_ai/core/constants.dart';

void main() {
  test('assets/questions.json conforms to the seeded question schema', () {
    final file = File('assets/questions.json');
    expect(file.existsSync(), isTrue);

    final raw = file.readAsStringSync();
    final json = jsonDecode(raw);
    expect(json, isA<List>());

    final questions = json.cast<Map<String, dynamic>>();

    // 1. At least 60 questions overall.
    expect(
      questions.length,
      greaterThanOrEqualTo(60),
      reason: 'Expected at least 60 seeded questions, got ${questions.length}.',
    );

    // 2. All 10 subjects are represented.
    final subjectsPresent = questions.map((q) => q['subject'] as String).toSet();
    for (final subject in AppConstants.subjects) {
      expect(
        subjectsPresent.contains(subject),
        isTrue,
        reason: 'Missing subject: $subject',
      );
    }

    // 3. Every question has exactly 4 options, a valid correct index, and a
    //    non-empty explanation.
    for (final question in questions) {
      expect(question['id'], isA<String>(), reason: 'id must be a string');
      expect(question['subject'], isA<String>(), reason: 'subject must be a string');
      expect(
        question['syllabus_topic'],
        isA<String>(),
        reason: 'syllabus_topic must be a string',
      );
      expect(
        question['question_text'],
        isA<String>(),
        reason: 'question_text must be a string',
      );

      final options = question['options'];
      expect(options, isA<List>(), reason: 'options must be a list');
      expect(
        options.length,
        equals(4),
        reason:
            'Question "${question['id']}" has ${options.length} options, expected 4.',
      );

      final correctIndex = question['correct_option_index'];
      expect(correctIndex, isA<int>(), reason: 'correct_option_index must be an int');
      expect(
        correctIndex >= 0 && correctIndex <= 3,
        isTrue,
        reason:
            'Question "${question['id']}" has correct_option_index $correctIndex, '
            'expected 0-3.',
      );

      final explanation = question['explanation'];
      expect(explanation, isA<String>(), reason: 'explanation must be a string');
      expect(
        (explanation as String).trim().isNotEmpty,
        isTrue,
        reason: 'Question "${question['id']}" has an empty explanation.',
      );
    }
  });
}
