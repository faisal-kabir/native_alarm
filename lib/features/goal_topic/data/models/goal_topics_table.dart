import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/goal_topic.dart';
import 'goal_topic_model.dart';

/// SQL table `goal_topics`: the device's copy of the server's `goal_topic` table with
/// each topic's goals and whys (as JSON texts), keyed by the server's id.
@DataClassName('GoalTopicRecord')
class GoalTopicsTable extends Table {
  @override
  String get tableName => 'goal_topics';

  IntColumn get id => integer()();
  TextColumn get label => text()();
  BoolColumn get gentle => boolean().withDefault(const Constant(false))();
  TextColumn get keywords => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get goalsJson => text().withDefault(const Constant('[]'))();
  TextColumn get whysJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// SQL table `general_whys`: the device's copy of the general `why_suggestion` rows
/// (those with no topic), shown when the person's topic is their own.
@DataClassName('GeneralWhyRecord')
class GeneralWhysTable extends Table {
  @override
  String get tableName => 'general_whys';

  IntColumn get id => integer()();
  TextColumn get content => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

extension GoalTopicRecordMapper on GoalTopicRecord {
  GoalTopic toEntity() => GoalTopic(
    id: id,
    label: label,
    gentle: gentle,
    keywords: keywords,
    sortOrder: sortOrder,
    goals: GoalTopicModel.decode(goalsJson),
    whys: GoalTopicModel.decode(whysJson),
  );
}

extension GoalTopicCompanionMapper on GoalTopic {
  GoalTopicsTableCompanion toCompanion() => GoalTopicsTableCompanion(
    id: Value(id),
    label: Value(label),
    gentle: Value(gentle),
    keywords: Value(keywords),
    sortOrder: Value(sortOrder),
    goalsJson: Value(GoalTopicModel.encode(goals)),
    whysJson: Value(GoalTopicModel.encode(whys)),
  );
}

extension GeneralWhyCompanionMapper on GeneralWhyModel {
  GeneralWhysTableCompanion toCompanion() => GeneralWhysTableCompanion(
    id: Value(id),
    content: Value(text),
    sortOrder: Value(sortOrder),
  );
}
