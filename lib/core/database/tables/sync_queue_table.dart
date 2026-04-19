import 'package:drift/drift.dart';

enum SyncOperationType {
  upload,
  download,
  delete,
  move,
  rename,
  createFolder,
  deleteFolder,
  moveFolder,
  renameFolder,
  favorite,
  unfavorite,
  trash,
  restore,
}

enum SyncOperationStatus { pending, inProgress, completed, failed }

class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()(); // 'file' or 'folder'
  TextColumn get payload => text()(); // JSON-encoded operation data
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
}
