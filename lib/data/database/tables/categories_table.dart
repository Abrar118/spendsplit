import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  @override
  List<Set<Column>> get uniqueKeys => [
    {name, isDollarCategory},
  ];

  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint('NOT NULL COLLATE NOCASE')();

  TextColumn get icon => text()();

  IntColumn get color => integer()();

  BoolColumn get isPredefined => boolean().withDefault(const Constant(false))();

  BoolColumn get isDollarCategory =>
      boolean().withDefault(const Constant(false))();
}
