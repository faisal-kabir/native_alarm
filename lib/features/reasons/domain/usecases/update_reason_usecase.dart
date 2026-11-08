import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reason.dart';
import '../entities/reason_draft.dart';
import '../repositories/reason_repository.dart';

class UpdateReasonParams extends Equatable {
  final int id;
  final ReasonDraft draft;

  const UpdateReasonParams(this.id, this.draft);

  @override
  List<Object?> get props => [id, draft];
}

/// Saves a reason's changed area, purpose, why, sound, voice and length (server +
/// device); returns the reason as saved.
@lazySingleton
class UpdateReasonUseCase implements UseCase<Reason, UpdateReasonParams> {
  final ReasonRepository repository;

  UpdateReasonUseCase(this.repository);

  @override
  Future<Either<Failure, Reason>> call(UpdateReasonParams params) =>
      repository.updateReason(params.id, params.draft);
}
