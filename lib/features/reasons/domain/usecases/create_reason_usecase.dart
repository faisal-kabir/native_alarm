import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/new_reason.dart';
import '../entities/reason.dart';
import '../repositories/reason_repository.dart';

/// Saves a new reason (server + device) under a name the user does not use yet.
@lazySingleton
class CreateReasonUseCase implements UseCase<Reason, NewReason> {
  final ReasonRepository repository;

  CreateReasonUseCase(this.repository);

  @override
  Future<Either<Failure, Reason>> call(NewReason params) =>
      repository.createReason(params);
}
