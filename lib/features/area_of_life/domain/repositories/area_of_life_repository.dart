import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/area_of_life.dart';
import '../entities/matter_suggestion.dart';
import '../entities/purpose_suggestion.dart';

abstract class AreaOfLifeRepository {
  /// The areas saved on the device, in server order. Emits again whenever they change
  /// (a [refreshAreas] that brought something new), so the UI follows by itself.
  Stream<Either<Failure, List<AreaOfLife>>> watchAreas();

  /// Downloads the areas from the server and saves them on the device. A failure
  /// (offline, server error) leaves the saved areas untouched.
  Future<Either<Failure, Unit>> refreshAreas();

  /// The purpose suggestions of [areaId], straight from the server. They are fully dynamic, so
  /// they are never saved on the device (no offline copy: offline is a failure).
  Future<Either<Failure, List<PurposeSuggestion>>> getPurposeSuggestions(
    int areaId,
  );

  /// The "why it matters" suggestions of [areaId] that follow purpose suggestion
  /// [purposeSuggestionId], or, when it is null, the area's ones with no purpose
  /// suggestion. Straight from the server, never saved on the device.
  Future<Either<Failure, List<MatterSuggestion>>> getMatterSuggestions(
    int areaId,
    int? purposeSuggestionId,
  );
}
