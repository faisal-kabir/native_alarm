import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/name_utils.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_local_data_source.dart';
import '../datasources/user_profile_remote_data_source.dart';

@LazySingleton(as: UserProfileRepository)
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileRemoteDataSource remoteDataSource;
  final UserProfileLocalDataSource localDataSource;

  UserProfileRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, UserProfile?>> getCachedProfile() async {
    try {
      final saved = await localDataSource.read();
      final current = remoteDataSource.authUserId;
      // iOS keeps Keychain data after the app is deleted, so a reinstall can find the
      // previous user's profile. It must never be shown to the new anonymous user.
      if (saved != null && current != null && saved.authUserId != current) {
        await localDataSource.clear();
        return const Right(null);
      }
      return Right(saved);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> syncProfile() async {
    final authUserId = remoteDataSource.authUserId;
    if (authUserId == null) return const Left(ServerFailure('Not signed in'));
    try {
      final profile = await remoteDataSource.fetchProfile(authUserId);
      await localDataSource.write(profile);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateDeviceInfo(DeviceInfo info) async {
    final authUserId = remoteDataSource.authUserId;
    if (authUserId == null) return const Left(ServerFailure('Not signed in'));
    try {
      final saved = await localDataSource.read();
      final upToDate =
          saved != null &&
          saved.authUserId == authUserId &&
          saved.platform == info.platform &&
          saved.appVersion == info.appVersion &&
          (info.fcmToken == null || saved.fcmToken == info.fcmToken);
      if (upToDate) return Right(saved);

      final updated = await remoteDataSource.updateDeviceInfo(authUserId, info);
      await localDataSource.write(updated);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateName(String name) {
    final clean = name.trim();
    if (!isValidName(clean)) {
      return Future.value(const Left(CacheFailure('Not a valid name')));
    }
    return _write({'name': clean});
  }

  @override
  Future<Either<Failure, UserProfile>> recordSignIn(
    AppUser user, {
    String? suggestedName,
  }) async {
    // The saved copy; without one, the server's row: a name that is set is never
    // overwritten by the provider's.
    final saved = await _readSaved() ?? await _fetchQuietly();
    final suggested = sanitizeName(suggestedName ?? '').trim();
    final needsName = (saved?.name ?? '').trim().isEmpty;
    return _write({
      'primary_provider': ?user.provider?.value,
      'email': ?user.email,
      if (needsName && isValidName(suggested)) 'name': suggested,
    });
  }

  Future<UserProfile?> _fetchQuietly() async {
    final authUserId = remoteDataSource.authUserId;
    if (authUserId == null) return null;
    try {
      return await remoteDataSource.fetchProfile(authUserId);
    } on ServerException {
      return null;
    }
  }

  Future<UserProfile?> _readSaved() async {
    try {
      return await localDataSource.read();
    } on CacheException {
      return null;
    }
  }

  Future<Either<Failure, UserProfile>> _write(
    Map<String, Object?> fields,
  ) async {
    final authUserId = remoteDataSource.authUserId;
    if (authUserId == null) return const Left(ServerFailure('Not signed in'));
    try {
      final updated = await remoteDataSource.updateFields(authUserId, fields);
      await localDataSource.write(updated);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
