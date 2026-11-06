import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sound_type.dart';
import '../repositories/sound_repository.dart';

/// Loads the sound types from the server.
@lazySingleton
class GetSoundTypesUseCase implements UseCase<List<SoundType>, NoParams> {
  final SoundRepository repository;

  GetSoundTypesUseCase(this.repository);

  @override
  Future<Either<Failure, List<SoundType>>> call(NoParams params) =>
      repository.getSoundTypes();
}
