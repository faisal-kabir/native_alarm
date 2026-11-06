import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/sound_quote.dart';
import '../entities/sound_type.dart';

abstract class SoundRepository {
  /// The sound types, in server order, straight from the server.
  Future<Either<Failure, List<SoundType>>> getSoundTypes();

  /// The example line for [areaId] in sound [soundId], or null when there is none.
  /// Straight from the server, never saved on the device.
  Future<Either<Failure, SoundQuote?>> getSoundQuote(int areaId, int soundId);
}
