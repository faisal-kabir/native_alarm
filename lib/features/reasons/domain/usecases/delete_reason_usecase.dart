import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/reason_repository.dart';

/// Deletes a reason (server, then device) by its id.
@lazySingleton
class DeleteReasonUseCase implements UseCase<Unit, int> {
  final ReasonRepository repository;

  DeleteReasonUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int id) => repository.deleteReason(id);
}
