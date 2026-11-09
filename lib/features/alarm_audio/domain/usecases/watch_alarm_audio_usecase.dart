import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/alarm_audio.dart';
import '../repositories/alarm_audio_repository.dart';

/// Follows the device's copy of one list (alarm sounds or sound tracks), with the
/// downloaded files: it never asks the server, so it works offline.
@lazySingleton
class WatchAlarmAudioUseCase {
  final AlarmAudioRepository repository;

  WatchAlarmAudioUseCase(this.repository);

  Stream<Either<Failure, List<AlarmAudio>>> call(AlarmAudioKind kind) =>
      repository.watchAudio(kind);
}
