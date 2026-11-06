import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/voice_repository.dart';

/// Brings the saved voices up to date with the server.
@lazySingleton
class RefreshVoicesUseCase implements UseCase<Unit, NoParams> {
  final VoiceRepository repository;

  RefreshVoicesUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.refreshVoices();
}
