import 'package:drift/drift.dart';

class FoldersTable extends Table {
  @override
  String get tableName => 'folders';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  BoolColumn get isRoot => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
