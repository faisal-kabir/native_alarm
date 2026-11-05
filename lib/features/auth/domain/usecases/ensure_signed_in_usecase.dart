import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Makes sure the app has a Supabase session. For now every new install starts as an
/// anonymous user; Google/Apple sign-in will be added with onboarding.
@lazySingleton
class EnsureSignedInUseCase implements UseCase<AppUser, NoParams> {
  final AuthRepository repository;

  EnsureSignedInUseCase(this.repository);

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) =>
      repository.ensureSignedIn();
}
