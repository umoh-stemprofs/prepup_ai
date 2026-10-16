/// PrepUp AI — weak-area diagnostic model (Phase 03, task 3.4).
library;

/// Misses grouped by subject + syllabus topic, driving the analytics screen.
class WeakArea {
  const WeakArea({
    required this.subject,
    required this.syllabusTopic,
    required this.incorrectCount,
    required this.totalCount,
  });

  /// Subject the topic belongs to.
  final String subject;

  /// Syllabus topic label.
  final String syllabusTopic;

  /// How many answers in this topic were wrong.
  final int incorrectCount;

  /// How many answers in this topic were attempted.
  final int totalCount;

  /// Questions answered correctly in this topic.
  int get correctCount => totalCount - incorrectCount;

  /// `(correct / total) * 100`, or 0 when nothing was attempted.
  double get accuracyPercentage =>
      totalCount == 0 ? 0 : (correctCount / totalCount) * 100;

  /// True when accuracy is below the 50% pass mark.
  bool get isBelowPassMark => accuracyPercentage < 50;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory WeakArea.fromJson(Map<String, dynamic> json) => WeakArea(
        subject: json['subject'] as String,
        syllabusTopic: json['syllabus_topic'] as String,
        incorrectCount: json['incorrect_count'] as int,
        totalCount: json['total_count'] as int,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject': subject,
        'syllabus_topic': syllabusTopic,
        'incorrect_count': incorrectCount,
        'total_count': totalCount,
      };

  /// Same as [fromJson]; sqflite rows share the JSON column names.
  factory WeakArea.fromMap(Map<String, dynamic> map) => WeakArea.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeakArea &&
          other.subject == subject &&
          other.syllabusTopic == syllabusTopic &&
          other.incorrectCount == incorrectCount &&
          other.totalCount == totalCount;

  @override
  int get hashCode =>
      Object.hash(subject, syllabusTopic, incorrectCount, totalCount);

  @override
  String toString() =>
      'WeakArea($subject: $syllabusTopic, $correctCount/$totalCount)';
}
