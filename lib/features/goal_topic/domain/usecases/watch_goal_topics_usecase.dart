import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/goal_topic.dart';
import '../repositories/goal_topic_repository.dart';

/// Streams the saved goal topics (local first, see [GoalTopicRepository]).
@lazySingleton
class WatchGoalTopicsUseCase {
  final GoalTopicRepository repository;

  WatchGoalTopicsUseCase(this.repository);

  Stream<Either<Failure, List<GoalTopic>>> call(NoParams params) =>
      repository.watchTopics();
}
