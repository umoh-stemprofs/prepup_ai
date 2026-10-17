import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/models/weak_area.dart';

void main() {
  group('WeakArea analytics categorization', () {
    test('accuracy below 70% is NEEDS PRACTICE', () {
      const topic = WeakArea(
        subject: 'Chemistry',
        syllabusTopic: 'Organic Chemistry',
        incorrectCount: 4,
        totalCount: 10,
      );

      // 6/10 correct is 60% accuracy, and 40% wrong clears the 30% threshold.
      expect(topic.accuracyPercentage, 60.0);
      expect(topic.incorrectRatio, 0.4);
      expect(topic.isNeedsPractice, isTrue);
      expect(topic.isGood, isFalse);
    });

    test('exactly 70% correct is GOOD', () {
      const topic = WeakArea(
        subject: 'Mathematics',
        syllabusTopic: 'Basic Algebra',
        incorrectCount: 3,
        totalCount: 10,
      );

      // 30% wrong is the boundary: it is not "more than 30%".
      expect(topic.accuracyPercentage, 70.0);
      expect(topic.incorrectRatio, 0.3);
      expect(topic.isNeedsPractice, isFalse);
      expect(topic.isGood, isTrue);
    });

    test('just under 70% correct is NEEDS PRACTICE', () {
      const topic = WeakArea(
        subject: 'Physics',
        syllabusTopic: 'Waves',
        incorrectCount: 31,
        totalCount: 100,
      );

      // 69% correct, 31% wrong.
      expect(topic.accuracyPercentage, 69.0);
      expect(topic.isNeedsPractice, isTrue);
      expect(topic.isGood, isFalse);
    });

    test('100% accuracy is GOOD', () {
      const topic = WeakArea(
        subject: 'Physics',
        syllabusTopic: 'Mechanics',
        incorrectCount: 0,
        totalCount: 5,
      );

      expect(topic.accuracyPercentage, 100.0);
      expect(topic.incorrectRatio, 0.0);
      expect(topic.isGood, isTrue);
    });

    test('0% accuracy is NEEDS PRACTICE', () {
      const topic = WeakArea(
        subject: 'Biology',
        syllabusTopic: 'Genetics',
        incorrectCount: 5,
        totalCount: 5,
      );

      expect(topic.accuracyPercentage, 0.0);
      expect(topic.incorrectRatio, 1.0);
      expect(topic.isNeedsPractice, isTrue);
    });

    test('an un-attempted topic is neither flagged nor promoted', () {
      const topic = WeakArea(
        subject: 'English Language',
        syllabusTopic: 'Comprehension',
        incorrectCount: 0,
        totalCount: 0,
      );

      expect(topic.accuracyPercentage, 0.0);
      expect(topic.incorrectRatio, 0.0);
      expect(topic.isNeedsPractice, isFalse);
      expect(topic.isBelowPassMark, isTrue);
    });

    test('the exam pass mark stays at 50%, separate from the badge rule', () {
      const passing = WeakArea(
        subject: 'Economics',
        syllabusTopic: 'Demand and Supply',
        incorrectCount: 1,
        totalCount: 2,
      );

      // 50% clears the exam pass mark but is still a red topic for practice.
      expect(passing.isBelowPassMark, isFalse);
      expect(passing.isNeedsPractice, isTrue);
    });

    test('raw rows aggregate into one grouped topic', () {
      final raw = [
        const WeakArea(
          subject: 'Chemistry',
          syllabusTopic: 'Organic Chemistry',
          incorrectCount: 2,
          totalCount: 4,
        ),
        const WeakArea(
          subject: 'Chemistry',
          syllabusTopic: 'Organic Chemistry',
          incorrectCount: 1,
          totalCount: 3,
        ),
      ];

      final grouped = <String, WeakArea>{};
      for (final item in raw) {
        final key = '${item.subject}|${item.syllabusTopic}';
        final existing = grouped[key];
        grouped[key] = existing == null
            ? item
            : WeakArea(
                subject: existing.subject,
                syllabusTopic: existing.syllabusTopic,
                incorrectCount: existing.incorrectCount + item.incorrectCount,
                totalCount: existing.totalCount + item.totalCount,
              );
      }

      final aggregated = grouped.values.toList();
      expect(aggregated, hasLength(1));
      expect(aggregated.first.incorrectCount, 3);
      expect(aggregated.first.totalCount, 7);
      expect(aggregated.first.correctCount, 4);
      expect(aggregated.first.isNeedsPractice, isTrue);
    });
  });
}
