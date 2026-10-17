import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prepup_ai/data/local/database_helper.dart';
import 'package:prepup_ai/data/remote/career_remote_store.dart';
import 'package:prepup_ai/data/remote/career_sync_service.dart';
import 'package:prepup_ai/models/pending_career_sync.dart';
import 'package:prepup_ai/models/saved_career.dart';
import 'package:prepup_ai/providers/career_provider.dart';

/// Records cloud writes and can be told to fail, so the queue can be observed.
class FakeCareerRemoteStore implements CareerRemoteStore {
  final List<String> upsertedTitles = <String>[];
  final List<String> upsertedUserIds = <String>[];
  final List<String> deletedTitles = <String>[];

  /// When set, every write throws this message.
  String? failure;

  @override
  Future<void> upsert({
    required String userId,
    required SavedCareer career,
  }) async {
    if (failure != null) {
      throw Exception(failure);
    }
    upsertedTitles.add(career.careerTitle);
    upsertedUserIds.add(userId);
  }

  @override
  Future<void> delete({
    required String userId,
    required String careerTitle,
  }) async {
    if (failure != null) {
      throw Exception(failure);
    }
    deletedTitles.add(careerTitle);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper helper;
  late FakeCareerRemoteStore remote;

  const userId = 'user-123';

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    sqfliteFfiInit();
    // Own file: concurrent test files must not share one SQLite database.
    DatabaseHelper.debugDatabaseFileName = 'test_career_sync.db';
    helper = DatabaseHelper.instance;
    remote = FakeCareerRemoteStore();

    final db = await helper.database;
    await db.delete('saved_careers');
    await db.delete('pending_career_sync');
  });

  tearDown(() async {
    await helper.dispose();
  });

  SavedCareer career(String title) => SavedCareer(
    careerTitle: title,
    summary: 'Summary for $title',
    requiredSubjects: const ['Physics'],
    matchPercentage: 94,
    savedAt: DateTime(2026, 10, 17),
  );

  CareerSyncService service({
    String? Function()? userIdProvider,
    Future<bool> Function()? isOnline,
  }) {
    return CareerSyncService(
      databaseHelper: helper,
      remote: remote,
      userIdProvider: userIdProvider ?? () => userId,
      isOnline: isOnline ?? () async => true,
    );
  }

  group('queueing', () {
    test(
      'a save then delete for the same role coalesces to one delete',
      () async {
        final sync = service();

        await sync.queueUpsert(career('Ecologist'));
        await sync.queueUpsert(career('Pharmacist'));
        await sync.queueDelete('Ecologist');

        final pending = await helper.getPendingCareerSync(userId: userId);
        final byTitle = <String, String>{
          for (final operation in pending)
            operation.careerTitle: operation.operation.name,
        };

        // Two distinct roles, but only ONE operation for Ecologist.
        expect(pending, hasLength(2));
        expect(byTitle['Ecologist'], 'delete');
        expect(byTitle['Pharmacist'], 'upsert');
        expect(await sync.pendingCount(), 2);
      },
    );

    test('a save after a delete wins', () async {
      final sync = service();

      await sync.queueDelete('Ecologist');
      await sync.queueUpsert(career('Ecologist'));

      final pending = await helper.getPendingCareerSync(userId: userId);

      expect(pending, hasLength(1));
      expect(pending.single.operation.name, 'upsert');
      expect(pending.single.career?.careerTitle, 'Ecologist');
    });
  });

  group('flush', () {
    test('an empty queue is already complete', () async {
      final report = await service().flush();

      expect(report.synced, 0);
      expect(report.pending, 0);
      expect(report.isComplete, isTrue);
      expect(report.skipped, isNull);
    });

    test('online and signed in pushes queued writes and clears them', () async {
      final sync = service();
      await sync.queueUpsert(career('Mechanical Engineer'));

      final report = await sync.flush();

      expect(report.synced, 1);
      expect(report.pending, 0);
      expect(report.skipped, isNull);
      expect(remote.upsertedTitles, ['Mechanical Engineer']);
      expect(remote.upsertedUserIds, [userId]);
      expect(await sync.pendingCount(), 0);
    });

    test('offline keeps the queue and does not touch the cloud', () async {
      final sync = service(isOnline: () async => false);
      await sync.queueUpsert(career('Ecologist'));

      final report = await sync.flush();

      expect(report.skipped, CareerSyncSkip.offline);
      expect(report.pending, 1);
      expect(remote.upsertedTitles, isEmpty);
      expect(await sync.pendingCount(), 1);
    });

    test('a guest never queues, so no account can inherit the write', () async {
      final sync = service(userIdProvider: () => null);
      await sync.queueUpsert(career('Ecologist'));

      final report = await sync.flush();

      expect(report.skipped, CareerSyncSkip.notSignedIn);
      expect(report.pending, 0);
      expect(remote.upsertedTitles, isEmpty);
      expect(await helper.getPendingCareerSync(userId: userId), isEmpty);
    });

    test(
      "another account's queue is never flushed under this session",
      () async {
        final firstAccount = service(userIdProvider: () => 'user-a');
        await firstAccount.queueUpsert(career('Ecologist'));

        final secondAccount = service(userIdProvider: () => 'user-b');
        final report = await secondAccount.flush();

        expect(report.synced, 0);
        expect(remote.upsertedTitles, isEmpty);
        // user-a's write is still waiting for user-a, untouched.
        expect(
          await helper.getPendingCareerSync(userId: 'user-a'),
          hasLength(1),
        );
      },
    );

    test('the queue rejects a row with no owner', () async {
      expect(
        () => helper.queueCareerSync(
          PendingCareerSync.upsert(career('Ecologist'), userId: ''),
        ),
        throwsArgumentError,
      );
    });

    test('a remote failure keeps the operation queued with an error', () async {
      final sync = service();
      await sync.queueUpsert(career('Ecologist'));
      remote.failure = 'network down';

      final failed = await sync.flush();

      expect(failed.synced, 0);
      expect(failed.pending, 1);
      expect(failed.error, contains('network down'));
      expect(await sync.pendingCount(), 1);

      // Connectivity returns: the same queued row is pushed.
      remote.failure = null;
      final retried = await sync.flush();

      expect(retried.synced, 1);
      expect(retried.pending, 0);
      expect(remote.upsertedTitles, ['Ecologist']);
    });

    test('queued deletes reach the cloud', () async {
      final sync = service();
      await sync.queueDelete('Pharmacist');

      final report = await sync.flush();

      expect(report.synced, 1);
      expect(remote.deletedTitles, ['Pharmacist']);
      expect(remote.upsertedTitles, isEmpty);
    });

    test('operations flush oldest first', () async {
      final sync = service();
      await sync.queueUpsert(career('First'));
      // Distinct timestamps so ordering is observable.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await sync.queueUpsert(career('Second'));

      await sync.flush();

      expect(remote.upsertedTitles, ['First', 'Second']);
    });
  });

  group('CareerProvider integration', () {
    test('saving a match writes locally and pushes it to the cloud', () async {
      final provider =
          CareerProvider(databaseHelper: helper, syncService: service())
            ..setWorkEnvironment(WorkEnvironment.indoor)
            ..setActivityPreference(ActivityPreference.building)
            ..setFavoriteSubject('Physics');

      final saved = await provider.saveCurrentMatch();

      expect(provider.savedCareers.single.careerTitle, saved.careerTitle);
      expect(remote.upsertedTitles, [saved.careerTitle]);
      expect(provider.pendingSyncCount, 0);
      expect(provider.lastSyncError, isNull);
    });

    test('saving while offline still persists locally and queues', () async {
      final provider = CareerProvider(
        databaseHelper: helper,
        syncService: service(isOnline: () async => false),
      )..setFavoriteSubject('Biology');

      await provider.saveCurrentMatch();

      expect(provider.savedCareers, hasLength(1));
      expect(remote.upsertedTitles, isEmpty);
      expect(provider.pendingSyncCount, 1);
    });

    test('removing a bookmark queues and pushes a cloud delete', () async {
      final provider = CareerProvider(
        databaseHelper: helper,
        syncService: service(),
      )..setFavoriteSubject('Chemistry');

      await provider.saveCurrentMatch();
      final saved = provider.savedCareers.single;
      remote.upsertedTitles.clear();

      await provider.removeSavedCareer(saved.id!);

      expect(provider.savedCareers, isEmpty);
      expect(remote.deletedTitles, [saved.careerTitle]);
      expect(provider.pendingSyncCount, 0);
    });
  });
}
