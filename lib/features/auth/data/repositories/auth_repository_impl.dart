import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_mapper.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

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
}
