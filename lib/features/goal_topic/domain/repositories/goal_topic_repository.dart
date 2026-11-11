import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/goal_topic.dart';

abstract class GoalTopicRepository {
  /// The topics saved on the device, in chip order, each with its goals and whys. Emits
  /// again whenever they change (a [refresh] that brought something new).
  Stream<Either<Failure, List<GoalTopic>>> watchTopics();

  /// The general whys saved on the device (for a topic the person typed themselves), in
  /// order. Emits again whenever they change.
  Stream<Either<Failure, List<String>>> watchGeneralWhys();

  /// Downloads the topics and the general whys and saves them on the device. A failure
  /// (offline, server error) leaves what is saved untouched.
  Future<Either<Failure, Unit>> refresh();
}
