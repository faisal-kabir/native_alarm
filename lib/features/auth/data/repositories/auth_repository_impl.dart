import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/pending_merge_local_data_source.dart';
import '../datasources/social_credential_source.dart';
import '../models/app_user_mapper.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SocialCredentialSource credentialSource;
  final PendingMergeLocalDataSource pendingMerge;

  AuthRepositoryImpl(
    this.remoteDataSource,
    this.credentialSource,
    this.pendingMerge,
  );

  @override
  Future<Either<Failure, AppUser>> ensureSignedIn() async {
    // A saved session survives app restarts (supabase_flutter keeps and refreshes it),
    // so only a fresh install or a signed-out device creates a new anonymous user.
    final existing = remoteDataSource.currentUser;
    if (existing != null) return Right(existing.toEntity());
    try {
      final user = await remoteDataSource.signInAnonymously();
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<AppUser?> watchUser() =>
      remoteDataSource.userChanges.map((user) => user?.toEntity()).distinct();

  @override
  Future<Either<Failure, SignedIn>> signIn(AuthProvider provider) async {
    try {
      final credential = await credentialSource.request(provider);
      final current = remoteDataSource.currentUser;
      if (current == null || !current.isAnonymous) {
        final user = await remoteDataSource.signInWithIdToken(
          provider,
          credential,
        );
        return Right(
          SignedIn(
            user.toEntity(signedInWith: provider),
            name: credential.name,
            joined: user.id != current?.id,
          ),
        );
      }
      try {
        final user = await remoteDataSource.linkWithIdToken(
          provider,
          credential,
        );
        return Right(
          SignedIn(
            user.toEntity(signedInWith: provider),
            name: credential.name,
          ),
        );
      } on AccountInUseException {
        return Right(await _join(provider, credential));
      }
    } on CancelledException {
      return const Left(CancelledFailure('Cancelled'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  /// The account already exists: sign in to it and move this anonymous user's things
  /// into it. The ticket is asked for and kept BEFORE the session changes: once signed
  /// in, nothing else could prove that the anonymous user was this device's.
  Future<SignedIn> _join(
    AuthProvider provider,
    SocialCredential credential,
  ) async {
    await pendingMerge.write(await remoteDataSource.startMerge());
    final User user;
    try {
      user = await remoteDataSource.signInWithIdToken(provider, credential);
    } on AccountInUseException {
      await pendingMerge.clear();
      throw const ServerException('Account could not be signed in to');
    } on ServerException {
      // Still the anonymous user, with everything where it was: nothing to move.
      await pendingMerge.clear();
      rethrow;
    }
    final merged = await finishPendingMerge();
    return SignedIn(
      user.toEntity(signedInWith: provider),
      name: credential.name,
      joined: true,
      mergePending: merged.fold((_) => true, (_) => false),
    );
  }

  @override
  Future<Either<Failure, bool>> finishPendingMerge() async {
    try {
      final ticket = await pendingMerge.read();
      final current = remoteDataSource.currentUser;
      // Only the account can finish it (an anonymous session is refused).
      if (ticket == null || current == null || current.isAnonymous) {
        return const Right(false);
      }
      await remoteDataSource.finishMerge(ticket);
      await pendingMerge.clear();
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signOut() async {
    try {
      await remoteDataSource.signOut();
      final user = await remoteDataSource.signInAnonymously();
      return Right(user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
