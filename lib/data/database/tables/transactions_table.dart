import 'package:drift/drift.dart';

class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();

  RealColumn get amount => real()();

  IntColumn get categoryId => integer().nullable()();

  TextColumn get source => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
