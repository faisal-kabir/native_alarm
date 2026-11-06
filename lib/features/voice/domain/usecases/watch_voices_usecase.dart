import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/voice.dart';
import '../repositories/voice_repository.dart';

/// Streams the saved voices (local first, see [VoiceRepository]).
@lazySingleton
class WatchVoicesUseCase {
  final VoiceRepository repository;

  WatchVoicesUseCase(this.repository);

  Stream<Either<Failure, List<Voice>>> call(NoParams params) =>
      repository.watchVoices();
}
