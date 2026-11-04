import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reason.dart';
import '../../domain/entities/reason_area.dart';
import '../../domain/entities/reason_tone.dart';

/// SQL table `reasons`. Each row is one reason, keyed by its id. Rows come back as
/// [ReasonRecord].
@DataClassName('ReasonRecord')
class ReasonsTable extends Table {
  @override
  String get tableName => 'reasons';

  TextColumn get reasonId => text()();
  TextColumn get name => text()();
  TextColumn get area => textEnum<ReasonArea>()();
  TextColumn get tone => textEnum<ReasonTone>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {reasonId};
}

extension ReasonRecordMapper on ReasonRecord {
  Reason toEntity() => Reason(id: reasonId, name: name, area: area, tone: tone);
}
