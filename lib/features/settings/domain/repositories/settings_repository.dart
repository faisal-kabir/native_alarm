import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_info.dart';
import '../entities/user_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> getSettings();
  Future<Either<Failure, void>> saveSettings(UserSettings settings);
  Future<Either<Failure, AppInfo>> getAppInfo();
}
