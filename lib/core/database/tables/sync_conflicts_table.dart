import 'package:drift/drift.dart';

class SyncConflictsTable extends Table {
  @override
  String get tableName => 'sync_conflicts';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()(); // 'file' or 'folder'
  TextColumn get operationType => text()();
  TextColumn get conflictType =>
      text().withDefault(const Constant('retry_exhausted'))();
  TextColumn get payload => text()(); // JSON original payload
  TextColumn get errorMessage => text().nullable()();
  TextColumn get resolution =>
      text().nullable()(); // 'local', 'remote', 'manual'
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
