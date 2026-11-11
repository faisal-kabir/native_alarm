import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/goal_topic.dart';
import '../models/goal_topic_model.dart';
import '../models/goal_topics_table.dart';

abstract class GoalTopicLocalDataSource {
  /// The saved topics in chip order; emits again after every change of the table.
  Stream<List<GoalTopicRecord>> watchTopics();

  /// The saved general whys in order; emits again after every change.
  Stream<List<GeneralWhyRecord>> watchGeneralWhys();

  /// Makes the saved topics and general whys exactly [topics] and [whys]: rows are
  /// added or updated and rows the server no longer has are removed, in one transaction.
  Future<void> replaceAll(List<GoalTopic> topics, List<GeneralWhyModel> whys);
}

@LazySingleton(as: GoalTopicLocalDataSource)
class GoalTopicLocalDataSourceImpl implements GoalTopicLocalDataSource {
  final AppDatabase db;

  GoalTopicLocalDataSourceImpl(this.db);

  @override
  Stream<List<GoalTopicRecord>> watchTopics() => (db.select(
    db.goalTopicsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  @override
  Stream<List<GeneralWhyRecord>> watchGeneralWhys() => (db.select(
    db.generalWhysTable,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  @override
  Future<void> replaceAll(
    List<GoalTopic> topics,
    List<GeneralWhyModel> whys,
  ) async {
    try {
      await db.transaction(() async {
        final topicIds = topics.map((t) => t.id).toList();
        await (db.delete(
          db.goalTopicsTable,
        )..where((t) => t.id.isNotIn(topicIds))).go();
        await db.batch(
          (batch) => batch.insertAllOnConflictUpdate(
            db.goalTopicsTable,
            topics.map((t) => t.toCompanion()).toList(),
          ),
        );
        final whyIds = whys.map((w) => w.id).toList();
        await (db.delete(
          db.generalWhysTable,
        )..where((t) => t.id.isNotIn(whyIds))).go();
        await db.batch(
          (batch) => batch.insertAllOnConflictUpdate(
            db.generalWhysTable,
            whys.map((w) => w.toCompanion()).toList(),
          ),
        );
      });
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
