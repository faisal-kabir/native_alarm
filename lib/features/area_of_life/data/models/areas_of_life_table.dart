import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/area_of_life.dart';

/// SQL table `areas_of_life`: the device's copy of the server's `area_of_life` table,
/// keyed by the server's id. Rows come back as [AreaOfLifeRecord].
@DataClassName('AreaOfLifeRecord')
class AreasOfLifeTable extends Table {
  @override
  String get tableName => 'areas_of_life';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

extension AreaOfLifeRecordMapper on AreaOfLifeRecord {
  AreaOfLife toEntity() => AreaOfLife(
    id: id,
    name: name,
    title: title,
    description: description,
    icon: icon,
    color: color,
  );
}

extension AreaOfLifeCompanionMapper on AreaOfLife {
  AreasOfLifeTableCompanion toCompanion() => AreasOfLifeTableCompanion(
    id: Value(id),
    name: Value(name),
    title: Value(title),
    description: Value(description),
    icon: Value(icon),
    color: Value(color),
  );
}
