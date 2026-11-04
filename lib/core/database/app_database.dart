import 'package:drift/drift.dart';

import '../../features/alarm/data/models/alarms_table.dart';
import '../../features/reasons/data/models/reasons_table.dart';
// The generated part refers to these enums (textEnum columns of ReasonsTable).
import '../../features/reasons/domain/entities/reason_area.dart';
import '../../features/reasons/domain/entities/reason_tone.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database (drift). Add every feature's table to
/// `tables` and bump [schemaVersion] with a migration step whenever a table changes.
@DriftDatabase(tables: [AlarmsTable, ReasonsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: the reasons table was added.
      if (from < 2) await m.createTable(reasonsTable);
    },
  );
}
