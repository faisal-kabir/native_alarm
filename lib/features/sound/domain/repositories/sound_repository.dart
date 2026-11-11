import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/sound_type.dart';

abstract class SoundRepository {
  /// The sound types, in server order, straight from the server.
  Future<Either<Failure, List<SoundType>>> getSoundTypes();
}
