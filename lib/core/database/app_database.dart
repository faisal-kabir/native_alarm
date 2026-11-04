import 'package:drift/drift.dart';

import '../../features/alarm/data/models/alarms_table.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database (drift). Add every feature's table to
/// `tables` and bump [schemaVersion] with a migration step whenever a table changes.
@DriftDatabase(tables: [AlarmsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // onUpgrade: (m, from, to) async { if (from < 2) { ... } },
  );
}
