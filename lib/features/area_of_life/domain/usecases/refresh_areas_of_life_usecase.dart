import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/area_of_life_repository.dart';

/// Brings the saved areas of life up to date with the server.
@lazySingleton
class RefreshAreasOfLifeUseCase implements UseCase<Unit, NoParams> {
  final AreaOfLifeRepository repository;

  RefreshAreasOfLifeUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.refreshAreas();
}
