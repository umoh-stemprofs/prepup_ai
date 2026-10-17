import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/models/weak_area.dart';

void main() {
  group('WeakArea accuracyPercentage', () {
    test('1 of 4 correct is 25%', () {
      const WeakArea area = WeakArea(
        subject: 'Chemistry',
        syllabusTopic: 'Organic Reactions',
        incorrectCount: 3,
        totalCount: 4,
      );

      expect(area.correctCount, equals(1));
      expect(area.accuracyPercentage, equals(25.0));
      expect(area.isBelowPassMark, isTrue);
    });

    test('4 of 4 correct is 100%', () {
      const WeakArea area = WeakArea(
        subject: 'Mathematics',
        syllabusTopic: 'Probability',
        incorrectCount: 0,
        totalCount: 4,
      );

      expect(area.accuracyPercentage, equals(100.0));
      expect(area.isBelowPassMark, isFalse);
    });

    test('zero total avoids division by zero', () {
      const WeakArea area = WeakArea(
        subject: 'English Language',
        syllabusTopic: 'Comprehension',
        incorrectCount: 0,
        totalCount: 0,
      );

      expect(area.accuracyPercentage, equals(0.0));
    });

    test('exactly 50% is not below the pass mark', () {
      const WeakArea area = WeakArea(
        subject: 'Economics',
        syllabusTopic: 'Demand and Supply',
        incorrectCount: 1,
        totalCount: 2,
      );

      expect(area.accuracyPercentage, equals(50.0));
      expect(area.isBelowPassMark, isFalse);
    });
  });

  group('WeakArea display', () {
    test('displayLabel matches the Phase 10 "1/4 Correct (25%)" format', () {
      const topic = WeakArea(
        subject: 'Chemistry',
        syllabusTopic: 'Organic Reactions',
        incorrectCount: 3,
        totalCount: 4,
      );

      expect(
        topic.displayLabel,
        'Chemistry: Organic Reactions — 1/4 Correct (25%)',
      );
    });
  });

  group('WeakArea serialization', () {
    test('fromJson/toJson round-trip preserves every field', () {
      const WeakArea area = WeakArea(
        subject: 'Physics',
        syllabusTopic: 'Kinematics',
        incorrectCount: 2,
        totalCount: 3,
      );

      expect(WeakArea.fromJson(area.toJson()), equals(area));
      expect(
        area.toJson().keys.toSet(),
        equals(<String>{
          'subject',
          'syllabus_topic',
          'incorrect_count',
          'total_count',
        }),
      );
    });

    test('fromMap/toMap round-trip preserves every field', () {
      const WeakArea area = WeakArea(
        subject: 'Biology',
        syllabusTopic: 'Cell Division',
        incorrectCount: 1,
        totalCount: 5,
      );

      expect(WeakArea.fromMap(area.toMap()), equals(area));
    });
  });
}
