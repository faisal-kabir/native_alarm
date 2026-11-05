import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/area_of_life.dart';
import '../repositories/area_of_life_repository.dart';

/// Streams the saved areas of life (local first, see [AreaOfLifeRepository]).
@lazySingleton
class WatchAreasOfLifeUseCase {
  final AreaOfLifeRepository repository;

  WatchAreasOfLifeUseCase(this.repository);

  Stream<Either<Failure, List<AreaOfLife>>> call(NoParams params) =>
      repository.watchAreas();
}
