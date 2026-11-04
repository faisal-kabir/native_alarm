import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_settings.dart';
import '../models/settings_table.dart';

abstract class SettingsLocalDataSource {
  /// The saved settings, or the defaults when nothing was saved yet.
  Future<UserSettings> getSettings();
  Future<void> saveSettings(UserSettings settings);
}

@LazySingleton(as: SettingsLocalDataSource)
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final AppDatabase db;

  SettingsLocalDataSourceImpl(this.db);

  @override
  Future<UserSettings> getSettings() async {
    try {
      final record = await db.select(db.settingsTable).getSingleOrNull();
      return record?.toEntity() ?? const UserSettings();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    try {
      await db
          .into(db.settingsTable)
          .insertOnConflictUpdate(settings.toCompanion());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
