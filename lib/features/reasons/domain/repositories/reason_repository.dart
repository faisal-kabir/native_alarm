import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/new_reason.dart';
import '../entities/reason.dart';
import '../entities/reason_draft.dart';

abstract class ReasonRepository {
  /// The user's reasons saved on the device, oldest first; emits again on change
  /// (a new reason, a rename, an edit, a refresh), so screens follow by themselves.
  Stream<Either<Failure, List<Reason>>> watchReasons();

  /// One saved reason; emits again when it changes (null once it is gone).
  Stream<Either<Failure, Reason?>> watchReason(int id);

  /// Downloads the user's reasons and makes the device's copy match. On failure
  /// (offline) the saved copy stays as it is.
  Future<Either<Failure, Unit>> refreshReasons();

  /// Saves a new reason to the server's `reason` table under a name not yet used by
  /// this user, keeps the full row on the device and returns it.
  Future<Either<Failure, Reason>> createReason(NewReason reason);

  /// Renames reason [id] on the server and on the device; returns it as saved.
  Future<Either<Failure, Reason>> renameReason(int id, String name);

  /// Saves [draft] (area, purpose, why, sound, voice, length) as reason [id]'s new
  /// values, server first, then the device; returns it as saved.
  Future<Either<Failure, Reason>> updateReason(int id, ReasonDraft draft);

  /// Deletes reason [id] on the server, then from the device (screens following it
  /// drop it). On failure nothing is removed.
  Future<Either<Failure, Unit>> deleteReason(int id);
}
