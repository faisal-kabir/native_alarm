import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sound_type.dart';
import '../../domain/repositories/sound_repository.dart';
import '../datasources/sound_remote_data_source.dart';

@LazySingleton(as: SoundRepository)
class SoundRepositoryImpl implements SoundRepository {
  final SoundRemoteDataSource remoteDataSource;

  SoundRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<SoundType>>> getSoundTypes() async {
    try {
      return Right(await remoteDataSource.fetchSoundTypes());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
