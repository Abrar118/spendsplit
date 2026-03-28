import 'package:drift/drift.dart';

class SavingsGoalsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  RealColumn get currentAmount => real().withDefault(const Constant(0))();

  RealColumn get targetAmount => real()();

  TextColumn get icon => text().withDefault(const Constant('flag'))();

  DateTimeColumn get deadline => dateTime().nullable()();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
