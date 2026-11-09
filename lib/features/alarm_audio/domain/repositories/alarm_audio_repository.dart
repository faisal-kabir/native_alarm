import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/alarm_audio.dart';

abstract class AlarmAudioRepository {
  /// The device's copy of one list (by id), with its downloaded files; emits again
  /// after every change.
  Stream<Either<Failure, List<AlarmAudio>>> watchAudio(AlarmAudioKind kind);

  /// Brings both lists and their icon / audio files up to date with the server: new
  /// and changed files are downloaded, files no row uses any more are deleted. What
  /// fails (offline, one file) keeps the previous copy and is tried again next time.
  Future<Either<Failure, Unit>> refreshAudio();
}
