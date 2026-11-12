import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../entities/auth_provider.dart';

abstract class AuthRepository {
  /// The signed-in user, starting an anonymous session first if there is none.
  Future<Either<Failure, AppUser>> ensureSignedIn();

  /// The user now and every time it changes (a sign-in, a sign-out); null while there
  /// is no session.
  Stream<AppUser?> watchUser();

  /// Signs in with [provider] (its own sheet opens). Nothing the person made is lost:
  ///
  /// * anonymous, with an Apple / Google account that is new to Eala: the account is
  ///   LINKED to this user (same user, same goals);
  /// * anonymous, with an account Eala already has: signs in to it and MOVES this
  ///   user's goals and alarms into it ([SignedIn.joined]; [SignedIn.mergePending]
  ///   while the move still has to be finished by [finishPendingMerge]);
  /// * already signed in: signs in to the account.
  ///
  /// [CancelledFailure] when the sheet was closed. Returns the user and the name the
  /// provider gave, if any.
  Future<Either<Failure, SignedIn>> signIn(AuthProvider provider);

  /// Finishes a move [signIn] began but could not finish (offline): true when it moved
  /// things just now, false when nothing was waiting. On failure it waits for the next
  /// try; nothing is lost meanwhile.
  Future<Either<Failure, bool>> finishPendingMerge();

  /// Ends the session and starts a new anonymous one for this device; returns its user.
  Future<Either<Failure, AppUser>> signOut();
}

/// The result of a sign-in: who is signed in, and the name the provider gave.
class SignedIn {
  const SignedIn(
    this.user, {
    this.name,
    this.joined = false,
    this.mergePending = false,
  });

  final AppUser user;
  final String? name;

  /// Signed in to an account that already existed, so another user than before: what
  /// the device keeps of the server (the profile, the goals) has to be read again.
  final bool joined;

  /// [joined], but the anonymous user's goals and alarms have not reached the account
  /// yet (see [AuthRepository.finishPendingMerge]).
  final bool mergePending;
}
