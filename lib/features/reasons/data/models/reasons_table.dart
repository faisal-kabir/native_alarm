import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reason.dart';

/// SQL table `reasons`. Each row is one reason, keyed by its id; the area and tone
/// are stored as the display names the server sent. Rows come back as
/// [ReasonRecord].
@DataClassName('ReasonRecord')
class ReasonsTable extends Table {
  @override
  String get tableName => 'reasons';

  TextColumn get reasonId => text()();
  TextColumn get name => text()();
  TextColumn get areaName => text()();
  IntColumn get areaColor => integer().nullable()();
  TextColumn get toneName => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {reasonId};
}

extension ReasonRecordMapper on ReasonRecord {
  Reason toEntity() => Reason(
    id: reasonId,
    name: name,
    areaName: areaName,
    areaColor: areaColor,
    toneName: toneName,
  );
}
