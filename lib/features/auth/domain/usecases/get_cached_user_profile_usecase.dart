import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// The user's profile from the device (works offline); null if none is saved yet.
@lazySingleton
class GetCachedUserProfileUseCase implements UseCase<UserProfile?, NoParams> {
  final UserProfileRepository repository;

  GetCachedUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile?>> call(NoParams params) =>
      repository.getCachedProfile();
}
