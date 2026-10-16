import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/models/quiz_session.dart';

QuizSession _sample() => QuizSession(
      sessionUuid: '3f1a2b9c-0d4e-4f5a-8b6c-7d8e9f0a1b2c',
      subject: 'Biology',
      score: 7,
      totalQuestions: 10,
      scorePercentage: 70.0,
      isPass: true,
      timeSpentSeconds: 540,
      completedAt: DateTime.utc(2026, 10, 16, 12, 30, 5),
    );

void main() {
  group('QuizSession serialization', () {
    test('fromJson/toJson round-trip preserves every field', () {
      final QuizSession session = _sample();

      final QuizSession restored = QuizSession.fromJson(session.toJson());

      expect(restored, equals(session));
      expect(restored.sessionUuid, '3f1a2b9c-0d4e-4f5a-8b6c-7d8e9f0a1b2c');
      expect(restored.scorePercentage, 70.0);
      expect(restored.isPass, isTrue);
      expect(restored.completedAt, DateTime.utc(2026, 10, 16, 12, 30, 5));
    });

    test('toMap uses the snake_case column names', () {
      final Map<String, dynamic> map = _sample().toMap();

      expect(
        map.keys.toSet(),
        equals(<String>{
          'session_uuid',
          'subject',
          'score',
          'total_questions',
          'score_percentage',
          'is_pass',
          'time_spent_seconds',
          'completed_at',
        }),
      );
    });

    test('fromMap/toMap round-trip preserves every field', () {
      final QuizSession session = _sample();

      expect(QuizSession.fromMap(session.toMap()), equals(session));
    });

    test('tolerates integer score_percentage by widening to double', () {
      final QuizSession restored = QuizSession.fromJson(<String, dynamic>{
        'session_uuid': 'abc',
        'subject': 'Physics',
        'score': 4,
        'total_questions': 5,
        'score_percentage': 80, // int, not double
        'is_pass': true,
        'time_spent_seconds': 60,
        'completed_at': '2026-10-16T12:00:00.000Z',
      });

      expect(restored.scorePercentage, 80.0);
    });
  });
}
