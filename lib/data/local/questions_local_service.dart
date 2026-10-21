import 'dart:convert';
import 'package:prepup_ai/core/constants.dart';
import 'database_helper.dart';

/// Read-only helpers for the locally cached question bank.
class QuestionsLocalService {
  QuestionsLocalService(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  /// Returns up to [limit] random questions for [subject] from the local cache.
  ///
  /// Pass [AppConstants.allSubjects] to draw a mixed set across every subject.
  /// The call goes through the asset SSOT seed, so it only returns questions
  /// that were present in `assets/questions.json`.
  Future<List<Map<String, dynamic>>> getQuestionsBySubject(
    String subject, {
    int limit = 10,
  }) async {
    final db = await _databaseHelper.database;
    final bool allSubjects = subject == AppConstants.allSubjects;
    final rows = await db.query(
      'local_questions',
      where: allSubjects ? null : 'subject = ?',
      whereArgs: allSubjects ? null : [subject],
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return rows.map(_decodeOptionsRow).toList();
  }

  /// Returns up to [limit] random questions for [subject] restricted to
  /// [syllabusTopic].
  ///
  /// Used by "practice red topics": drilling the sub-topic that was answered
  /// wrongly, rather than the whole subject.
  Future<List<Map<String, dynamic>>> getQuestionsByTopic(
    String subject,
    String syllabusTopic, {
    int limit = 10,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'local_questions',
      where: 'subject = ? AND syllabus_topic = ?',
      whereArgs: [subject, syllabusTopic],
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return rows.map(_decodeOptionsRow).toList();
  }

  /// Returns the number of cached questions per subject.
  Future<Map<String, int>> getAllSubjectsQuestionCounts() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT subject, COUNT(*) AS c FROM local_questions GROUP BY subject',
    );
    return {
      for (final row in rows) row['subject'] as String: (row['c'] as int?) ?? 0,
    };
  }

  /// Total number of questions cached locally.
  Future<int> getQuestionCount() async {
    return _databaseHelper.getQuestionCount();
  }

  /// Decodes the JSON blob stored in [row]['options'] back to a list.
  static Map<String, dynamic> _decodeOptionsRow(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    List<dynamic> options;
    if (optionsRaw is List<dynamic>) {
      options = optionsRaw;
    } else {
      options = (jsonDecode(optionsRaw as String) as List).cast<String>();
    }
    return {...row, 'options': options.cast<String>()};
  }
}
