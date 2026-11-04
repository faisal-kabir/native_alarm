import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reason.dart';
import '../repositories/reason_repository.dart';

/// Loads the saved reasons, oldest first.
@lazySingleton
class GetReasonsUseCase implements UseCase<List<Reason>, NoParams> {
  final ReasonRepository repository;

  GetReasonsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Reason>>> call(NoParams params) =>
      repository.getReasons();
}
