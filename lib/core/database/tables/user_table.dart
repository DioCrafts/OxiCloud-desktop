import 'package:drift/drift.dart';

class UserTable extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get email => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('user'))();
  IntColumn get storageQuotaBytes => integer().nullable()();
  IntColumn get storageUsedBytes => integer().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
