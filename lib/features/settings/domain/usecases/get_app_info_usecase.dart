import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_info.dart';
import '../repositories/settings_repository.dart';

@lazySingleton
class GetAppInfoUseCase implements UseCase<AppInfo, NoParams> {
  final SettingsRepository repository;

  GetAppInfoUseCase(this.repository);

  @override
  Future<Either<Failure, AppInfo>> call(NoParams params) =>
      repository.getAppInfo();
}
