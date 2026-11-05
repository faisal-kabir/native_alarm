import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/device_info.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Keeps the user's `platform`, `app_version` and `fcm_token` on the server equal to
/// this installation's, updating them only when they changed.
@lazySingleton
class UpdateDeviceInfoUseCase implements UseCase<UserProfile, DeviceInfo> {
  final UserProfileRepository repository;

  UpdateDeviceInfoUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(DeviceInfo info) =>
      repository.updateDeviceInfo(info);
}
