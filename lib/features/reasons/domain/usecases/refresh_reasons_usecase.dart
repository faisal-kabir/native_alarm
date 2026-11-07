import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/reason_repository.dart';

/// Brings the device's copy of the user's reasons up to date with the server.
@lazySingleton
class RefreshReasonsUseCase implements UseCase<Unit, NoParams> {
  final ReasonRepository repository;

  RefreshReasonsUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.refreshReasons();
}
