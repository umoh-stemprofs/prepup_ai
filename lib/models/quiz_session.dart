/// PrepUp AI — completed quiz session model (Phase 03, task 3.3).
library;

/// One finished practice/timed attempt, persisted locally and synced later.
class QuizSession {
  const QuizSession({
    required this.sessionUuid,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.scorePercentage,
    required this.isPass,
    required this.timeSpentSeconds,
    required this.completedAt,
  });

  /// Client-generated UUID (AM-3). Becomes the cloud `quiz_sessions.id`, so
  /// enqueueing the same session twice upserts instead of duplicating.
  final String sessionUuid;

  /// Subject practised, or "All Subjects".
  final String subject;

  /// Number of correct answers.
  final int score;

  /// Total questions answered.
  final int totalQuestions;

  /// `score / totalQuestions * 100`.
  final double scorePercentage;

  /// Pass when [scorePercentage] >= 50.
  final bool isPass;

  /// Wall-clock seconds spent on the attempt.
  final int timeSpentSeconds;

  /// When the attempt finished.
  final DateTime completedAt;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory QuizSession.fromJson(Map<String, dynamic> json) => QuizSession(
        sessionUuid: json['session_uuid'] as String,
        subject: json['subject'] as String,
        score: json['score'] as int,
        totalQuestions: json['total_questions'] as int,
        scorePercentage: (json['score_percentage'] as num).toDouble(),
        isPass: json['is_pass'] as bool,
        timeSpentSeconds: json['time_spent_seconds'] as int,
        completedAt: DateTime.parse(json['completed_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'session_uuid': sessionUuid,
        'subject': subject,
        'score': score,
        'total_questions': totalQuestions,
        'score_percentage': scorePercentage,
        'is_pass': isPass,
        'time_spent_seconds': timeSpentSeconds,
        'completed_at': completedAt.toIso8601String(),
      };

  /// Same as [fromJson]; sqflite rows share the JSON column names.
  factory QuizSession.fromMap(Map<String, dynamic> map) =>
      QuizSession.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizSession &&
          other.sessionUuid == sessionUuid &&
          other.subject == subject &&
          other.score == score &&
          other.totalQuestions == totalQuestions &&
          other.scorePercentage == scorePercentage &&
          other.isPass == isPass &&
          other.timeSpentSeconds == timeSpentSeconds &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
        sessionUuid,
        subject,
        score,
        totalQuestions,
        scorePercentage,
        isPass,
        timeSpentSeconds,
        completedAt,
      );

  @override
  String toString() =>
      'QuizSession($sessionUuid, $subject, $score/$totalQuestions, pass: $isPass)';
}
