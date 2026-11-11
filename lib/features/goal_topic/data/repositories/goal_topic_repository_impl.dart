import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/goal_topic.dart';
import '../../domain/repositories/goal_topic_repository.dart';
import '../datasources/goal_topic_local_data_source.dart';
import '../datasources/goal_topic_remote_data_source.dart';
import '../models/goal_topic_model.dart';
import '../models/goal_topics_table.dart';

/// Local first, like the areas of life were: the saved topics show at once (offline
/// too) and follow the server update that runs behind them.
@LazySingleton(as: GoalTopicRepository)
class GoalTopicRepositoryImpl implements GoalTopicRepository {
  final GoalTopicRemoteDataSource remoteDataSource;
  final GoalTopicLocalDataSource localDataSource;

  GoalTopicRepositoryImpl(this.remoteDataSource, this.localDataSource);

  StreamTransformer<S, Either<Failure, T>> _toEither<S, T>(T Function(S) map) =>
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(Right(map(data))),
        handleError: (error, _, sink) =>
            sink.add(Left(CacheFailure(error.toString()))),
      );

  @override
  Stream<Either<Failure, List<GoalTopic>>> watchTopics() =>
      localDataSource.watchTopics().transform(
        _toEither((records) => [for (final r in records) r.toEntity()]),
      );

  @override
  Stream<Either<Failure, List<String>>> watchGeneralWhys() => localDataSource
      .watchGeneralWhys()
      .transform(_toEither((records) => [for (final r in records) r.content]));

  @override
  Future<Either<Failure, Unit>> refresh() async {
    try {
      // The two lists come in parallel: one round trip, not two. (`Future.wait`
      // rethrows the first failure as it is, so the catches below still see it.)
      final lists = await Future.wait<Object>([
        remoteDataSource.fetchTopics(),
        remoteDataSource.fetchGeneralWhys(),
      ]);
      final topics = lists[0] as List<GoalTopicModel>;
      final whys = lists[1] as List<GeneralWhyModel>;
      // An empty answer is never trusted over what is saved: the flow can not work
      // without topics, so it is a misconfigured server rather than a real "none".
      if (topics.isNotEmpty) await localDataSource.replaceAll(topics, whys);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
