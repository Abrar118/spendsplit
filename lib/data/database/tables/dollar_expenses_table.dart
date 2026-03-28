import 'package:drift/drift.dart';

class DollarExpensesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amount => real()();

  TextColumn get purpose => text()();

  IntColumn get categoryId => integer()();

  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
