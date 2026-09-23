import 'package:drift/drift.dart';

@TableIndex(name: 'transactions_sms_ref', columns: {#smsRef}, unique: true)
class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();

  RealColumn get amount => real()();

  IntColumn get categoryId => integer().nullable()();

  IntColumn get savingsGoalId => integer().nullable()();

  TextColumn get source => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// `<provider receive millis>|<full SMS body>` for SMS-imported rows, null
  /// for anything entered by hand. The unique index blocks double imports.
  TextColumn get smsRef => text().nullable()();

  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
}
