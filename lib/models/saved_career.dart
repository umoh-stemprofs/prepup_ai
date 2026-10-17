/// PrepUp AI — locally saved career recommendation (Phase 09).
library;

import 'dart:convert';

/// A STEM career the student bookmarked from the career helper.
///
/// Persisted in the offline cache so saved careers survive an app restart.
class SavedCareer {
  const SavedCareer({
    this.id,
    required this.careerTitle,
    required this.summary,
    required this.requiredSubjects,
    required this.matchPercentage,
    required this.savedAt,
  });

  /// SQLite row id; null until the row has been inserted.
  final int? id;

  /// Matched role, e.g. "Mechanical Engineer".
  final String careerTitle;

  /// Short prose explanation of the match.
  final String summary;

  /// Subjects that matter most for the role.
  final List<String> requiredSubjects;

  /// Deterministic match score shown on the badge, 0-100.
  final int matchPercentage;

  /// When the student saved it.
  final DateTime savedAt;

  SavedCareer copyWith({int? id}) => SavedCareer(
        id: id ?? this.id,
        careerTitle: careerTitle,
        summary: summary,
        requiredSubjects: requiredSubjects,
        matchPercentage: matchPercentage,
        savedAt: savedAt,
      );

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory SavedCareer.fromJson(Map<String, dynamic> json) {
    final Object? subjects =
        json['required_subjects'] ?? json['requiredSubjects'];
    final Object? savedAt = json['saved_at'] ?? json['savedAt'];

    return SavedCareer(
      id: json['id'] as int?,
      careerTitle: (json['career_title'] ?? json['careerTitle']) as String? ?? '',
      summary: json['summary'] as String? ?? '',
      requiredSubjects: subjects is String
          ? (jsonDecode(subjects) as List<dynamic>)
              .whereType<String>()
              .toList()
          : subjects is List<dynamic>
              ? subjects.whereType<String>().toList()
              : const <String>[],
      matchPercentage: (json['match_percentage'] ?? json['matchPercentage'])
              as int? ??
          0,
      savedAt: savedAt is String
          ? DateTime.tryParse(savedAt) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        'career_title': careerTitle,
        'summary': summary,
        'required_subjects': jsonEncode(requiredSubjects),
        'match_percentage': matchPercentage,
        'saved_at': savedAt.toIso8601String(),
      };

  /// Same as [fromJson]; sqflite rows share the JSON column names.
  factory SavedCareer.fromMap(Map<String, dynamic> map) =>
      SavedCareer.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCareer &&
          other.id == id &&
          other.careerTitle == careerTitle &&
          other.summary == summary &&
          other.matchPercentage == matchPercentage &&
          other.savedAt == savedAt &&
          _listEquals(other.requiredSubjects, requiredSubjects);

  @override
  int get hashCode => Object.hash(
        id,
        careerTitle,
        summary,
        matchPercentage,
        savedAt,
        Object.hashAll(requiredSubjects),
      );

  @override
  String toString() => 'SavedCareer($careerTitle, $matchPercentage%)';
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
