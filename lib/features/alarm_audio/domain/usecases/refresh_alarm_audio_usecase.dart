import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/alarm_audio_repository.dart';

/// Brings the saved alarm sounds and sound tracks (and their files) up to date.
@lazySingleton
class RefreshAlarmAudioUseCase implements UseCase<Unit, NoParams> {
  final AlarmAudioRepository repository;

  RefreshAlarmAudioUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.refreshAudio();
}
