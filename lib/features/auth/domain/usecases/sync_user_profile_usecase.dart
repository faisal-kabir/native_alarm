import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Downloads the signed-in user's row from the `user` table and saves it on the
/// device, replacing whatever was saved before.
@lazySingleton
class SyncUserProfileUseCase implements UseCase<UserProfile, NoParams> {
  final UserProfileRepository repository;

  SyncUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(NoParams params) =>
      repository.syncProfile();
}
