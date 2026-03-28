import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().unique()();

  TextColumn get icon => text()();

  IntColumn get color => integer()();

  BoolColumn get isPredefined => boolean().withDefault(const Constant(false))();

  BoolColumn get isDollarCategory =>
      boolean().withDefault(const Constant(false))();
}
