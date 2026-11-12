import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../entities/device_info.dart';
import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  /// The profile kept on the device, or null when none is saved or it belongs to a
  /// different user than the one signed in now.
  Future<Either<Failure, UserProfile?>> getCachedProfile();

  /// Reads the signed-in user's row from Supabase and saves it on the device.
  Future<Either<Failure, UserProfile>> syncProfile();

  /// Writes [info] to the signed-in user's row, but only the parts that differ from
  /// what is saved (nothing is sent when nothing changed), and saves the result on the
  /// device. Returns the up-to-date profile.
  Future<Either<Failure, UserProfile>> updateDeviceInfo(DeviceInfo info);

  /// Saves the user's first name on the server and on the device. Returns the profile.
  Future<Either<Failure, UserProfile>> updateName(String name);

  /// After a sign-in: writes how they sign in (`primary_provider`) and their e-mail to
  /// the profile, and [suggestedName] (what the provider gave) when no name is set yet.
  Future<Either<Failure, UserProfile>> recordSignIn(
    AppUser user, {
    String? suggestedName,
  });
}
