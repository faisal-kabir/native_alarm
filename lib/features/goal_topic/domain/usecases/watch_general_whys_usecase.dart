import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/goal_topic_repository.dart';

/// Streams the saved general whys: the ones suggested when the topic is the person's own.
@lazySingleton
class WatchGeneralWhysUseCase {
  final GoalTopicRepository repository;

  WatchGeneralWhysUseCase(this.repository);

  Stream<Either<Failure, List<String>>> call(NoParams params) =>
      repository.watchGeneralWhys();
}
