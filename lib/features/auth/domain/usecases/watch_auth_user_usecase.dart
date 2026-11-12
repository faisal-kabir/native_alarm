import 'package:injectable/injectable.dart';

import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// The signed-in user now and whenever they change (a sign-in, a sign-out).
@lazySingleton
class WatchAuthUserUseCase {
  final AuthRepository repository;

  WatchAuthUserUseCase(this.repository);

  Stream<AppUser?> call() => repository.watchUser();
}
