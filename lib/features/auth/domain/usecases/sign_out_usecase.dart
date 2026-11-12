import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_profile_repository.dart';

/// Signs out. The name stays: it is spoken in every wake-up, so the new anonymous user
/// of this device gets it again (best effort).
@lazySingleton
class SignOutUseCase implements UseCase<AppUser, NoParams> {
  final AuthRepository auth;
  final UserProfileRepository profile;

  SignOutUseCase(this.auth, this.profile);

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) async {
    final name = (await profile.getCachedProfile()).fold(
      (_) => null,
      (saved) => saved?.name,
    );
    final result = await auth.signOut();
    if (result.isRight()) {
      await profile.syncProfile();
      if (name != null && name.trim().isNotEmpty) {
        await profile.updateName(name);
      }
    }
    return result;
  }
}
