import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reason.dart';
import '../repositories/reason_repository.dart';

class RenameReasonParams extends Equatable {
  final int id;
  final String name;

  const RenameReasonParams(this.id, this.name);

  @override
  List<Object?> get props => [id, name];
}

/// Gives a reason a new name (server + device); returns the reason as saved.
@lazySingleton
class RenameReasonUseCase implements UseCase<Reason, RenameReasonParams> {
  final ReasonRepository repository;

  RenameReasonUseCase(this.repository);

  @override
  Future<Either<Failure, Reason>> call(RenameReasonParams params) =>
      repository.renameReason(params.id, params.name);
}
