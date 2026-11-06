import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/new_reason.dart';
import '../entities/reason.dart';

abstract class ReasonRepository {
  /// The user's reasons saved on the device, oldest first; emits again on change
  /// (a new reason, a rename), so the list follows by itself.
  Stream<Either<Failure, List<Reason>>> watchReasons();

  /// Saves [reason] to the server's `reason` table under a name not yet used by
  /// this user, keeps a copy on the device and returns it (with the server's id).
  Future<Either<Failure, Reason>> createReason(NewReason reason);

  /// Renames reason [id] on the server and on the device.
  Future<Either<Failure, Unit>> renameReason(String id, String name);
}
