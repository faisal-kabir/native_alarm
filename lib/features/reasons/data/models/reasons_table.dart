import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/reason.dart';
import 'reason_model.dart';

/// SQL table `reasons`: the device's copy of the user's reasons. Each row keeps the
/// server's whole `reason` row, with its area, sound and voice joined in, as JSON
/// ([data]), so one reason is one object everywhere and nothing has to be joined on the
/// device. [createdAt] is only there to keep the list in order.
@DataClassName('ReasonRecord')
class ReasonsTable extends Table {
  @override
  String get tableName => 'reasons';

  IntColumn get id => integer()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

extension ReasonRecordMapper on ReasonRecord {
  Reason toEntity() => reasonFromJson(jsonDecode(data) as Map<String, dynamic>);
}

/// A server row (with its joins) as a row of [ReasonsTable].
ReasonsTableCompanion reasonRowCompanion(Map<String, dynamic> row) =>
    ReasonsTableCompanion(
      id: Value((row['id'] as num).toInt()),
      createdAt: Value(DateTime.tryParse('${row['created_at']}')?.toUtc()),
      data: Value(jsonEncode(row)),
    );
