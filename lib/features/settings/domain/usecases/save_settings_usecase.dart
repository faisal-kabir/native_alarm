import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

@lazySingleton
class SaveSettingsUseCase implements UseCase<void, UserSettings> {
  final SettingsRepository repository;

  SaveSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UserSettings settings) =>
      repository.saveSettings(settings);
}
