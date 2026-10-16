/// PrepUp AI — AI career advisor result model (Phase 03, task 3.5).
library;

/// A career recommendation returned by the AI advisor.
///
/// [CareerResult.fromJson] is deliberately tolerant: LLM output varies, so
/// missing, null, or oddly-typed fields degrade to safe defaults instead of
/// throwing.
class CareerResult {
  const CareerResult({
    required this.careerTitle,
    required this.summary,
    required this.requiredSubjects,
  });

  /// Recommended career, e.g. "Petroleum Engineer".
  final String careerTitle;

  /// Short prose explanation of why this career fits.
  final String summary;

  /// Subjects that matter most for this career.
  final List<String> requiredSubjects;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Tolerant factory: any missing/null/badly-typed field degrades gracefully.
  factory CareerResult.fromJson(Map<String, dynamic> json) {
    final Object? title = json['career_title'] ?? json['careerTitle'] ?? json['title'];
    final Object? body = json['summary'] ?? json['description'];
    final Object? subjects =
        json['required_subjects'] ?? json['requiredSubjects'] ?? json['subjects'];

    return CareerResult(
      careerTitle: title is String ? title : '',
      summary: body is String ? body : '',
      requiredSubjects: subjects is List<dynamic>
          ? subjects.whereType<String>().toList()
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'career_title': careerTitle,
        'summary': summary,
        'required_subjects': requiredSubjects,
      };

  /// Same as [fromJson].
  factory CareerResult.fromMap(Map<String, dynamic> map) =>
      CareerResult.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareerResult &&
          other.careerTitle == careerTitle &&
          other.summary == summary &&
          _listEquals(other.requiredSubjects, requiredSubjects);

  @override
  int get hashCode => Object.hash(
        careerTitle,
        summary,
        Object.hashAll(requiredSubjects),
      );

  @override
  String toString() => 'CareerResult($careerTitle, subjects: $requiredSubjects)';
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
