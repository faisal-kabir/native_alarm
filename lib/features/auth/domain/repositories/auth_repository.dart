import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  /// The signed-in user, starting an anonymous session first if there is none.
  Future<Either<Failure, AppUser>> ensureSignedIn();
}
