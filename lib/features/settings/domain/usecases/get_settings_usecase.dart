import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

/// Loads the saved settings (the defaults when nothing was saved yet).
@lazySingleton
class GetSettingsUseCase implements UseCase<UserSettings, NoParams> {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, UserSettings>> call(NoParams params) =>
      repository.getSettings();
}
