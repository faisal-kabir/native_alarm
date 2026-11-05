import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
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
}
