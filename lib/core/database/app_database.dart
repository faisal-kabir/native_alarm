import 'package:drift/drift.dart';

import '../../features/alarm/data/models/alarms_table.dart';
import '../../features/area_of_life/data/models/areas_of_life_table.dart';
import '../../features/reasons/data/models/reasons_table.dart';
import '../../features/settings/data/models/settings_table.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database (drift). Add every feature's table to
/// `tables` and bump [schemaVersion] with a migration step whenever a table changes.
@DriftDatabase(
  tables: [AlarmsTable, ReasonsTable, SettingsTable, AreasOfLifeTable],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2: the reasons table was added.
      if (from < 2) {
        await m.createTable(reasonsTable);
      } else if (from < 4) {
        // v4: reasons keep the server's area and tone names instead of fixed enums.
        // Nothing could create a reason yet, so the old table held no real data.
        await m.deleteTable('reasons');
        await m.createTable(reasonsTable);
      }
      // v3: the settings table was added.
      if (from < 3) await m.createTable(settingsTable);
      // v5: the areas_of_life table (the device's copy of the server's list) was added.
      if (from < 5) await m.createTable(areasOfLifeTable);
    },
  );
}
