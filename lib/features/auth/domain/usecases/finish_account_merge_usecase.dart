import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../reasons/domain/repositories/reason_repository.dart';
import '../repositories/auth_repository.dart';

/// Finishes moving an anonymous user's goals and alarms into the account they signed in
/// to, when the sign-in could not (offline); then the device reads the goals again. True
/// when something was moved now. Asked on every app start; costs nothing when no move
/// is waiting.
@lazySingleton
class FinishAccountMergeUseCase implements UseCase<bool, NoParams> {
  final AuthRepository auth;
  final ReasonRepository reasons;

  FinishAccountMergeUseCase(this.auth, this.reasons);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    final result = await auth.finishPendingMerge();
    if (result.getOrElse(() => false)) await reasons.refreshReasons();
    return result;
  }
}
