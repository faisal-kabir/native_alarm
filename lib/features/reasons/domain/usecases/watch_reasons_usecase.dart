import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reason.dart';
import '../repositories/reason_repository.dart';

/// Streams the user's saved reasons, oldest first.
@lazySingleton
class WatchReasonsUseCase {
  final ReasonRepository repository;

  WatchReasonsUseCase(this.repository);

  Stream<Either<Failure, List<Reason>>> call(NoParams params) =>
      repository.watchReasons();
}
