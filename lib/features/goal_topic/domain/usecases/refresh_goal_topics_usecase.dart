import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/goal_topic_repository.dart';

/// Brings the saved topics, goals and whys up to date with the server.
@lazySingleton
class RefreshGoalTopicsUseCase implements UseCase<Unit, NoParams> {
  final GoalTopicRepository repository;

  RefreshGoalTopicsUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repository.refresh();
}
