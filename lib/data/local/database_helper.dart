import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/quiz_session.dart';
import '../../models/weak_area.dart';

/// Singleton SQLite helper for the local offline cache.
///
/// This class is intentionally kept on the data side only; it knows how to
/// create the offline schema and seed from the asset SSOT, but it does not
/// import UI or service-layer code.
class DatabaseHelper {
  DatabaseHelper._();

  static DatabaseHelper? _instance;
  static Database? _database;

  /// The canonical asset path for the question SSOT.
  static const _questionsAssetPath = 'assets/questions.json';

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// The open database, lazily created on first access.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Disposes the cached database instance.
  ///
  /// Mostly useful in tests; in production the database normally lives for
  /// the lifetime of the app.
  Future<void> dispose() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await db.close();
    }
  }

  /// Opens the SQLite database, creating the offline schema on first launch.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'prepup_ai_local.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Keep foreign keys enabled inside the local cache, even though we do
    // not currently model every FK at the SQLite level.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_questions (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        syllabus_topic TEXT NOT NULL,
        question_text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_option_index INTEGER NOT NULL,
        explanation TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_quiz_sessions (
        session_uuid TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        score_percentage REAL NOT NULL,
        is_pass INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_weak_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_uuid TEXT NOT NULL,
        subject TEXT NOT NULL,
        syllabus_topic TEXT NOT NULL,
        incorrect_count INTEGER NOT NULL,
        total_count INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sync_results (
        session_uuid TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// If [local_questions] is empty, read the asset SSOT and batch-insert all
  /// seed questions.
  ///
  /// This keeps the local cache consistent with [assets/questions.json]
  /// without requiring network access or the Supabase schema to exist.
  Future<void> seedQuestionsFromAssetsIfEmpty() async {
    final db = await database;

    final existing = await db.rawQuery(
      'SELECT id FROM local_questions LIMIT 1',
    );
    if (existing.isNotEmpty) {
      return;
    }

    final jsonText = await rootBundle.loadString(_questionsAssetPath);
    final parsed = jsonDecode(jsonText) as List<dynamic>;
    if (parsed.isEmpty) {
      return;
    }

    final batch = db.batch();
    for (final item in parsed) {
      final map = item as Map<dynamic, dynamic>;
      batch.insert('local_questions', {
        'id': map['id'],
        'subject': map['subject'],
        'syllabus_topic': map['syllabus_topic'],
        'question_text': map['question_text'],
        'options': jsonEncode(map['options']),
        'correct_option_index': map['correct_option_index'],
        'explanation': map['explanation'],
      });
    }
    await batch.commit(noResult: true);
  }

  /// Returns the number of cached questions.
  Future<int> getQuestionCount() async {
    final db = await database;
    final row = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM local_questions',
    );
    return (row.first['c'] as int?) ?? 0;
  }

  /// Persists a completed [QuizSession] row into [local_quiz_sessions].
  ///
  /// Uses `INSERT OR REPLACE` so re-enqueuing the same session UUID upserts
  /// instead of throwing a primary-key conflict.
  ///
  /// sqflite does not accept Dart [bool] values, so [isPass] is stored as
  /// 1/0 to match the INTEGER column.
  Future<void> saveQuizSession(QuizSession session) async {
    final db = await database;
    await db.insert(
      'local_quiz_sessions',
      {
        ...session.toMap(),
        'is_pass': session.isPass ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Persists one or more [WeakArea] rows belonging to a completed session.
  Future<void> saveWeakAreas(List<WeakArea> areas) async {
    final db = await database;
    final batch = db.batch();
    for (final area in areas) {
      batch.insert('local_weak_areas', {
        ...area.toMap(),
        'session_uuid': '',
      });
    }
    await batch.commit(noResult: true);
  }
}
