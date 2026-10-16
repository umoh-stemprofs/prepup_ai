/// PrepUp AI — exam question model (Phase 03, tasks 3.1 & 3.2).
library;

import 'dart:math';

/// A single exam question with its four options and explanation.
class Question {
  const Question({
    required this.id,
    required this.subject,
    required this.syllabusTopic,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  /// Unique question id.
  final String id;

  /// One of the 10 subjects from `AppConstants.subjects`.
  final String subject;

  /// Syllabus topic label, used for weak-area analytics.
  final String syllabusTopic;

  /// The question prompt.
  final String questionText;

  /// The answer options (4 in the seed bank).
  final List<String> options;

  /// Index into [options] of the correct answer.
  final int correctOptionIndex;

  /// Why the correct answer is correct; shown in result review.
  final String explanation;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// JSON keys match the seed-bank schema (`assets/questions.json`).
  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        subject: json['subject'] as String,
        syllabusTopic: json['syllabus_topic'] as String,
        questionText: json['question_text'] as String,
        options: (json['options'] as List<dynamic>).cast<String>(),
        correctOptionIndex: json['correct_option_index'] as int,
        explanation: json['explanation'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'subject': subject,
        'syllabus_topic': syllabusTopic,
        'question_text': questionText,
        'options': options,
        'correct_option_index': correctOptionIndex,
        'explanation': explanation,
      };

  /// Same data as [toJson] but with snake_case keys, convenient for sqflite
  /// rows (which use the same names as the JSON schema).
  factory Question.fromMap(Map<String, dynamic> map) =>
      Question.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  // ---------------------------------------------------------------------------
  // Behaviour
  // ---------------------------------------------------------------------------

  /// Returns a new [Question] whose options are shuffled, with
  /// [correctOptionIndex] remapped so it still points at the same answer text.
  ///
  /// Pure: the original question is never mutated. Works even when two options
  /// share the same text. Pass [random] for deterministic, unit-testable
  /// shuffles.
  Question shuffleOptions({Random? random}) {
    final Random rng = random ?? Random();
    final List<int> order = List<int>.generate(options.length, (int i) => i);
    order.shuffle(rng);

    final List<String> shuffled =
        order.map((int i) => options[i]).toList(growable: false);

    return Question(
      id: id,
      subject: subject,
      syllabusTopic: syllabusTopic,
      questionText: questionText,
      options: shuffled,
      correctOptionIndex: order.indexOf(correctOptionIndex),
      explanation: explanation,
    );
  }

  // ---------------------------------------------------------------------------
  // Value equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          other.id == id &&
          other.subject == subject &&
          other.syllabusTopic == syllabusTopic &&
          other.questionText == questionText &&
          _listEquals(other.options, options) &&
          other.correctOptionIndex == correctOptionIndex &&
          other.explanation == explanation;

  @override
  int get hashCode => Object.hash(
        id,
        subject,
        syllabusTopic,
        questionText,
        Object.hashAll(options),
        correctOptionIndex,
        explanation,
      );

  @override
  String toString() =>
      'Question(id: $id, subject: $subject, correctOptionIndex: $correctOptionIndex)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
