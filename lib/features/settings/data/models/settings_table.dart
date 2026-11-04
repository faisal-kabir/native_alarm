import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_settings.dart';

/// SQL table `settings`: a single row (id 1) holding the user's choices.
@DataClassName('SettingsRecord')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get notifyBilling => boolean().withDefault(const Constant(true))();
  BoolColumn get notifyAlarms => boolean().withDefault(const Constant(true))();
  BoolColumn get notifyQuotes => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

extension SettingsRecordMapper on SettingsRecord {
  UserSettings toEntity() => UserSettings(
    notifyBilling: notifyBilling,
    notifyAlarms: notifyAlarms,
    notifyQuotes: notifyQuotes,
  );
}

extension SettingsCompanionMapper on UserSettings {
  SettingsTableCompanion toCompanion() => SettingsTableCompanion(
    id: const Value(1),
    notifyBilling: Value(notifyBilling),
    notifyAlarms: Value(notifyAlarms),
    notifyQuotes: Value(notifyQuotes),
  );
}
