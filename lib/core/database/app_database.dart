import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'tables/cached_files_table.dart';
import 'tables/files_table.dart';
import 'tables/folders_table.dart';
import 'tables/sync_conflicts_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/user_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    FilesTable,
    FoldersTable,
    SyncQueueTable,
    SyncConflictsTable,
    CachedFilesTable,
    UserTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(syncConflictsTable);
      }
    },
  );

  // --- Files ---
  Future<List<FilesTableData>> getFilesInFolder(String? folderId) {
    if (folderId == null) {
      return (select(filesTable)
            ..where((f) => f.folderId.isNull())
            ..orderBy([(f) => OrderingTerm.asc(f.name)]))
          .get();
    }
    return (select(filesTable)
          ..where((f) => f.folderId.equals(folderId))
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .get();
  }

  Future<FilesTableData?> getFileById(String id) {
    return (select(
      filesTable,
    )..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertFile(FilesTableCompanion file) {
    return into(filesTable).insertOnConflictUpdate(file);
  }

  Future<void> upsertFiles(List<FilesTableCompanion> files) {
    return batch((b) {
      for (final file in files) {
        b.insert(filesTable, file, onConflict: DoUpdate((_) => file));
      }
    });
  }

  Future<int> deleteFileById(String id) {
    return (delete(filesTable)..where((f) => f.id.equals(id))).go();
  }

  // --- Folders ---
  Future<List<FoldersTableData>> getFoldersInParent(String? parentId) {
    if (parentId == null) {
      return (select(foldersTable)
            ..where((f) => f.parentId.isNull())
            ..orderBy([(f) => OrderingTerm.asc(f.name)]))
          .get();
    }
    return (select(foldersTable)
          ..where((f) => f.parentId.equals(parentId))
          ..orderBy([(f) => OrderingTerm.asc(f.name)]))
        .get();
  }

  Future<FoldersTableData?> getFolderById(String id) {
    return (select(
      foldersTable,
    )..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertFolder(FoldersTableCompanion folder) {
    return into(foldersTable).insertOnConflictUpdate(folder);
  }

  Future<void> upsertFolders(List<FoldersTableCompanion> folders) {
    return batch((b) {
      for (final folder in folders) {
        b.insert(foldersTable, folder, onConflict: DoUpdate((_) => folder));
      }
    });
  }

  Future<int> deleteFolderById(String id) {
    return (delete(foldersTable)..where((f) => f.id.equals(id))).go();
  }

  // --- Sync Queue ---
  Future<List<SyncQueueTableData>> getPendingSyncOps({int limit = 10}) {
    return (select(syncQueueTable)
          ..where((s) => s.status.equals('pending') | s.status.equals('failed'))
          ..orderBy([
            (s) => OrderingTerm.desc(s.priority),
            (s) => OrderingTerm.asc(s.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<int> insertSyncOp(SyncQueueTableCompanion op) {
    return into(syncQueueTable).insert(op);
  }

  Future<void> updateSyncOpStatus(
    int id,
    String status, {
    String? errorMessage,
  }) {
    return (update(syncQueueTable)..where((s) => s.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> clearCompletedSyncOps() {
    return (delete(
      syncQueueTable,
    )..where((s) => s.status.equals('completed'))).go();
  }

  Future<void> incrementSyncOpRetry(int id) {
    return customStatement(
      'UPDATE sync_queue SET retry_count = retry_count + 1, '
      'updated_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, id],
    );
  }

  // --- Sync Conflicts ---

  Future<int> insertSyncConflict(SyncConflictsTableCompanion conflict) {
    return into(syncConflictsTable).insert(conflict);
  }

  Future<List<SyncConflictsTableData>> getUnresolvedConflicts() {
    return (select(syncConflictsTable)
          ..where((c) => c.resolvedAt.isNull())
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  Future<void> resolveConflict(int id, String resolution) {
    return (update(syncConflictsTable)..where((c) => c.id.equals(id))).write(
      SyncConflictsTableCompanion(
        resolution: Value(resolution),
        resolvedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteResolvedConflicts() {
    return (delete(
      syncConflictsTable,
    )..where((c) => c.resolvedAt.isNotNull())).go();
  }

  // --- Cached Files ---
  Future<CachedFilesTableData?> getCachedFile(String fileId) {
    return (select(
      cachedFilesTable,
    )..where((c) => c.fileId.equals(fileId))).getSingleOrNull();
  }

  Future<void> upsertCachedFile(CachedFilesTableCompanion entry) {
    return into(cachedFilesTable).insertOnConflictUpdate(entry);
  }

  Future<int> deleteCachedFile(String fileId) {
    return (delete(
      cachedFilesTable,
    )..where((c) => c.fileId.equals(fileId))).go();
  }

  // --- User ---
  Future<UserTableData?> getCurrentUser() {
    return select(userTable).getSingleOrNull();
  }

  Future<void> upsertUser(UserTableCompanion user) {
    return into(userTable).insertOnConflictUpdate(user);
  }

  Future<int> clearUser() {
    return delete(userTable).go();
  }

  // --- Wipe ---
  Future<void> clearAllData() async {
    await delete(filesTable).go();
    await delete(foldersTable).go();
    await delete(syncQueueTable).go();
    await delete(syncConflictsTable).go();
    await delete(cachedFilesTable).go();
    await delete(userTable).go();
  }
}

/// Opens a local SQLite database at the given directory.
LazyDatabase openDatabase(String dbFolder) {
  return LazyDatabase(() async {
    final file = File(p.join(dbFolder, 'oxicloud.db'));
    return NativeDatabase.createInBackground(file);
  });
}
