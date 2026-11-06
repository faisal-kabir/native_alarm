import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/voice.dart';

abstract class VoiceRepository {
  /// The voices saved on the device, in server order. Emits again whenever they change
  /// (a [refreshVoices] that brought something new).
  Stream<Either<Failure, List<Voice>>> watchVoices();

  /// Downloads the voices from the server and saves them on the device. A failure
  /// leaves the saved voices untouched.
  Future<Either<Failure, Unit>> refreshVoices();
}
