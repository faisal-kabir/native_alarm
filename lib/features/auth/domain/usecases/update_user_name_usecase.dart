import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Saves the user's first name (the one word every wake-up says out loud).
@lazySingleton
class UpdateUserNameUseCase implements UseCase<UserProfile, String> {
  final UserProfileRepository repository;

  UpdateUserNameUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfile>> call(String name) =>
      repository.updateName(name);
}
