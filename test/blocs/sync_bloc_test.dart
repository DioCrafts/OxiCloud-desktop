import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:oxicloud_app/core/entities/sync_folder.dart';
import 'package:oxicloud_app/core/entities/sync_status.dart';
import 'package:oxicloud_app/core/repositories/sync_repository.dart';
import 'package:oxicloud_app/presentation/blocs/sync/sync_bloc.dart';

// Manual mock using mocktail
class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late MockSyncRepository mockSyncRepository;
  late SyncBloc syncBloc;

  setUp(() {
    mockSyncRepository = MockSyncRepository();
    
    // Default mock for status stream
    when(() => mockSyncRepository.syncStatusStream)
        .thenAnswer((_) => const Stream<SyncStatus>.empty());
    
    syncBloc = SyncBloc(mockSyncRepository);
  });

  tearDown(() {
    syncBloc.close();
  });

  group('SyncBloc', () {
    group('SyncStarted', () {
      blocTest<SyncBloc, SyncState>(
        'emits [SyncInProgress] when sync starts successfully',
        build: () {
          when(() => mockSyncRepository.startSync())
              .thenAnswer((_) async => const Right<SyncFailure, void>(null));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const SyncStarted()),
        expect: () => [
          isA<SyncInProgress>(),
        ],
        verify: (_) {
          verify(() => mockSyncRepository.startSync()).called(1);
        },
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncError] when sync fails to start',
        build: () {
          when(() => mockSyncRepository.startSync()).thenAnswer(
            (_) async => const Left<SyncFailure, void>(NetworkSyncFailure('No connection')),
          );
          return syncBloc;
        },
        act: (bloc) => bloc.add(const SyncStarted()),
        expect: () => [
          isA<SyncError>(),
        ],
      );
    });

    group('SyncStopped', () {
      blocTest<SyncBloc, SyncState>(
        'emits [SyncPaused] when sync stops successfully',
        build: () {
          when(() => mockSyncRepository.stopSync())
              .thenAnswer((_) async => const Right<SyncFailure, void>(null));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const SyncStopped()),
        expect: () => [
          const SyncPaused(),
        ],
        verify: (_) {
          verify(() => mockSyncRepository.stopSync()).called(1);
        },
      );
    });

    group('SyncNowRequested', () {
      final syncResult = SyncResult(
        success: true,
        itemsUploaded: 5,
        itemsDownloaded: 3,
        itemsDeleted: 1,
        conflicts: 0,
        errors: [],
        duration: const Duration(seconds: 10),
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncInProgress, SyncIdle] when immediate sync succeeds',
        build: () {
          when(() => mockSyncRepository.syncNow())
              .thenAnswer((_) async => Right<SyncFailure, SyncResult>(syncResult));
          when(() => mockSyncRepository.getConflicts())
              .thenAnswer((_) async => const Right<SyncFailure, List<SyncConflict>>([]));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const SyncNowRequested()),
        expect: () => [
          isA<SyncInProgress>(),
          isA<SyncIdle>(),
        ],
        verify: (_) {
          verify(() => mockSyncRepository.syncNow()).called(1);
          verify(() => mockSyncRepository.getConflicts()).called(1);
        },
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncInProgress, SyncError] when immediate sync fails',
        build: () {
          when(() => mockSyncRepository.syncNow()).thenAnswer(
            (_) async => const Left<SyncFailure, SyncResult>(NetworkSyncFailure('Timeout')),
          );
          return syncBloc;
        },
        act: (bloc) => bloc.add(const SyncNowRequested()),
        expect: () => [
          isA<SyncInProgress>(),
          isA<SyncError>(),
        ],
      );
    });

    group('LoadRemoteFolders', () {
      final testFolders = [
        SyncFolder(
          id: '1',
          name: 'Documents',
          path: '/Documents',
          sizeBytes: 1073741824,
          itemCount: 100,
          isSelected: true,
        ),
        SyncFolder(
          id: '2',
          name: 'Photos',
          path: '/Photos',
          sizeBytes: 5368709120,
          itemCount: 500,
          isSelected: false,
        ),
      ];

      blocTest<SyncBloc, SyncState>(
        'emits [RemoteFoldersLoaded] when folders load successfully',
        build: () {
          when(() => mockSyncRepository.getRemoteFolders())
              .thenAnswer((_) async => Right<SyncFailure, List<SyncFolder>>(testFolders));
          when(() => mockSyncRepository.getSyncFolders())
              .thenAnswer((_) async => const Right<SyncFailure, List<String>>(['1']));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const LoadRemoteFolders()),
        expect: () => [
          RemoteFoldersLoaded(
            folders: testFolders,
            selectedFolderIds: const ['1'],
          ),
        ],
      );
    });

    group('UpdateSyncFolders', () {
      blocTest<SyncBloc, SyncState>(
        'calls setSyncFolders and reloads folders',
        build: () {
          when(() => mockSyncRepository.setSyncFolders(any()))
              .thenAnswer((_) async => const Right<SyncFailure, void>(null));
          when(() => mockSyncRepository.getRemoteFolders())
              .thenAnswer((_) async => const Right<SyncFailure, List<SyncFolder>>([]));
          when(() => mockSyncRepository.getSyncFolders())
              .thenAnswer((_) async => const Right<SyncFailure, List<String>>(['1', '2']));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const UpdateSyncFolders(['1', '2'])),
        verify: (_) {
          verify(() => mockSyncRepository.setSyncFolders(['1', '2'])).called(1);
        },
      );
    });

    group('ResolveConflictRequested', () {
      blocTest<SyncBloc, SyncState>(
        'resolves conflict and reloads conflicts',
        build: () {
          when(() => mockSyncRepository.resolveConflict(any(), any()))
              .thenAnswer((_) async => const Right<SyncFailure, void>(null));
          when(() => mockSyncRepository.getConflicts())
              .thenAnswer((_) async => const Right<SyncFailure, List<SyncConflict>>([]));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const ResolveConflictRequested(
          conflictId: 'conflict-1',
          resolution: ConflictResolution.keepLocal,
        )),
        verify: (_) {
          verify(() => mockSyncRepository.resolveConflict(
            'conflict-1',
            ConflictResolution.keepLocal,
          )).called(1);
          verify(() => mockSyncRepository.getConflicts()).called(1);
        },
      );
    });
  });
}
