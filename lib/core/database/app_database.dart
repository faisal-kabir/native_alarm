import 'package:drift/drift.dart';

import '../../features/alarm/data/models/alarms_table.dart';
import '../../features/area_of_life/data/models/areas_of_life_table.dart';
import '../../features/reasons/data/models/reasons_table.dart';
import '../../features/settings/data/models/settings_table.dart';
import '../../features/voice/data/models/voices_table.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database (drift). Add every feature's table to
/// `tables` and bump [schemaVersion] with a migration step whenever a table changes.
@DriftDatabase(
  tables: [
    AlarmsTable,
    ReasonsTable,
    SettingsTable,
    AreasOfLifeTable,
    VoicesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v8: reasons keep the server's whole row (area, sound, voice joined in) as
      // JSON. The table is only a copy of the server's reasons (every write goes to
      // the server first), so the old shape is dropped and refilled by the next
      // refresh; no user data is lost. (v2 added the table, v4 changed it.)
      if (from < 8) {
        if (from >= 2) await m.deleteTable('reasons');
        await m.createTable(reasonsTable);
      }
      // v3: the settings table was added.
      if (from < 3) await m.createTable(settingsTable);
      // v5: the areas_of_life table (the device's copy of the server's list) was added.
      if (from < 5) await m.createTable(areasOfLifeTable);
      // v6: the voices table (the device's copy of the server's voice list) was added.
      if (from < 6) {
        await m.createTable(voicesTable);
      } else if (from < 7) {
        // v7: voices keep their group (title, description) from the server join.
        await m.addColumn(voicesTable, voicesTable.groupTitle);
        await m.addColumn(voicesTable, voicesTable.groupDescription);
      }
    },
  );
}
