import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sound_quote.dart';
import '../repositories/sound_repository.dart';

class SoundQuoteParams extends Equatable {
  final int areaId;
  final int soundId;

  const SoundQuoteParams(this.areaId, this.soundId);

  @override
  List<Object?> get props => [areaId, soundId];
}

/// Loads the example line for an area in a sound, from the server every time.
@lazySingleton
class GetSoundQuoteUseCase implements UseCase<SoundQuote?, SoundQuoteParams> {
  final SoundRepository repository;

  GetSoundQuoteUseCase(this.repository);

  @override
  Future<Either<Failure, SoundQuote?>> call(SoundQuoteParams params) =>
      repository.getSoundQuote(params.areaId, params.soundId);
}
