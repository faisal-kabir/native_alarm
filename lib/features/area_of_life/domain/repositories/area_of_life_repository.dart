import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/area_of_life.dart';

abstract class AreaOfLifeRepository {
  /// The areas saved on the device, in server order. Emits again whenever they change
  /// (a [refreshAreas] that brought something new), so the UI follows by itself.
  Stream<Either<Failure, List<AreaOfLife>>> watchAreas();

  /// Downloads the areas from the server and saves them on the device. A failure
  /// (offline, server error) leaves the saved areas untouched.
  Future<Either<Failure, Unit>> refreshAreas();
}
