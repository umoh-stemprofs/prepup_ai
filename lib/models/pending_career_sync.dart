/// PrepUp AI — queued career sync operation (Phase 09).
library;

import 'dart:convert';

import 'saved_career.dart';

/// What the cloud should do with one bookmarked career.
enum CareerSyncOperation {
  /// Insert or overwrite the row for this role.
  upsert,

  /// Remove the row for this role.
  delete,
}

/// One queued cloud write, persisted in `pending_career_sync`.
///
/// Rows are keyed by ([userId], [careerTitle]) so repeated edits to the same
/// role collapse into a single pending operation, while two accounts sharing a
/// phone keep separate queues. A row is only ever flushed to the account that
/// queued it — see [CareerSyncService.queueUpsert].
class PendingCareerSync {
  const PendingCareerSync({
    required this.userId,
    required this.careerTitle,
    required this.operation,
    required this.queuedAt,
    this.career,
  });

  /// The account this write belongs to. Never empty: guest bookmark changes are
  /// stored locally only and never queued.
  final String userId;

  /// The role this operation targets.
  final String careerTitle;

  /// Whether the cloud row should be written or removed.
  final CareerSyncOperation operation;

  /// When the operation was queued (used to preserve ordering).
  final DateTime queuedAt;

  /// Payload for [CareerSyncOperation.upsert]; null for deletes.
  final SavedCareer? career;

  factory PendingCareerSync.upsert(
    SavedCareer career, {
    required String userId,
  }) => PendingCareerSync(
    userId: userId,
    careerTitle: career.careerTitle,
    operation: CareerSyncOperation.upsert,
    queuedAt: DateTime.now(),
    career: career,
  );

  factory PendingCareerSync.delete(
    String careerTitle, {
    required String userId,
  }) => PendingCareerSync(
    userId: userId,
    careerTitle: careerTitle,
    operation: CareerSyncOperation.delete,
    queuedAt: DateTime.now(),
  );

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory PendingCareerSync.fromMap(Map<String, dynamic> map) {
    final operation = CareerSyncOperation.values.firstWhere(
      (value) => value.name == (map['operation'] as String?),
      orElse: () => CareerSyncOperation.upsert,
    );
    final payload = map['payload'];

    SavedCareer? career;
    if (operation == CareerSyncOperation.upsert && payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        career = SavedCareer.fromJson(decoded);
      }
    }

    return PendingCareerSync(
      userId: map['user_id'] as String? ?? '',
      careerTitle: map['career_title'] as String? ?? '',
      operation: operation,
      queuedAt:
          DateTime.tryParse(map['queued_at'] as String? ?? '') ??
          DateTime.now(),
      career: career,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'user_id': userId,
    'career_title': careerTitle,
    'operation': operation.name,
    'payload': jsonEncode(career?.toJson() ?? const <String, dynamic>{}),
    'queued_at': queuedAt.toIso8601String(),
  };

  @override
  String toString() =>
      'PendingCareerSync($userId, $careerTitle, ${operation.name})';
}
