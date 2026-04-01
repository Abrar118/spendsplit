import 'package:drift/drift.dart';

class TransactionTemplatesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get amount => real().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
