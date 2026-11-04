import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/app_info_data_source.dart';
import '../datasources/settings_local_data_source.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;
  final AppInfoDataSource appInfoDataSource;

  SettingsRepositoryImpl(this.localDataSource, this.appInfoDataSource);

  @override
  Future<Either<Failure, UserSettings>> getSettings() async {
    try {
      return Right(await localDataSource.getSettings());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(UserSettings settings) async {
    try {
      await localDataSource.saveSettings(settings);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppInfo>> getAppInfo() async {
    try {
      return Right(await appInfoDataSource.getAppInfo());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
