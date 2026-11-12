import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../reasons/domain/repositories/reason_repository.dart';
import '../entities/app_user.dart';
import '../entities/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_profile_repository.dart';

/// Signs in with Apple or Google (see [AuthRepository.signIn]), then brings the device
/// up to date with the server:
///
/// * the profile learns how they sign in, their e-mail, and the name the provider gave
///   when none is set yet;
/// * an account that already existed is another user: its profile and its goals (the
///   ones moved here from this device included) replace what the device kept. While
///   the move is unfinished the goals are left alone, so none disappears meanwhile.
///
/// Keeping the device up to date is best effort: a sign-in that worked is never
/// reported as failed because of it.
@lazySingleton
class SignInWithProviderUseCase implements UseCase<AppUser, AuthProvider> {
  final AuthRepository auth;
  final UserProfileRepository profile;
  final ReasonRepository reasons;

  SignInWithProviderUseCase(this.auth, this.profile, this.reasons);

  @override
  Future<Either<Failure, AppUser>> call(AuthProvider provider) async {
    final result = await auth.signIn(provider);
    return result.fold(Left.new, (signedIn) async {
      if (signedIn.joined) await profile.syncProfile();
      await profile.recordSignIn(signedIn.user, suggestedName: signedIn.name);
      if (signedIn.joined && !signedIn.mergePending) {
        await reasons.refreshReasons();
      }
      return Right(signedIn.user);
    });
  }
}
