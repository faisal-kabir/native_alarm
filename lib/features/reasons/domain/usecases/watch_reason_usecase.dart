import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/reason.dart';
import '../repositories/reason_repository.dart';

/// Follows one saved reason (its screen shows every change at once).
@lazySingleton
class WatchReasonUseCase {
  final ReasonRepository repository;

  WatchReasonUseCase(this.repository);

  Stream<Either<Failure, Reason?>> call(int id) => repository.watchReason(id);
}
