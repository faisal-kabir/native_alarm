import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/features/goal_topic/data/datasources/goal_topic_local_data_source.dart';
import 'package:eala/features/goal_topic/data/datasources/goal_topic_remote_data_source.dart';
import 'package:eala/features/goal_topic/data/models/goal_topic_model.dart';
import 'package:eala/features/goal_topic/data/repositories/goal_topic_repository_impl.dart';
import 'package:eala/features/goal_topic/domain/entities/goal_topic.dart';
import 'package:eala/features/goal_topic/domain/goal_topic_search.dart';
import 'package:flutter_test/flutter_test.dart';

GoalTopic topic(
  int id,
  String label, {
  String keywords = '',
  bool gentle = false,
}) => GoalTopic(
  id: id,
  label: label,
  keywords: keywords,
  gentle: gentle,
  sortOrder: id,
);

class FakeRemote implements GoalTopicRemoteDataSource {
  List<GoalTopicModel> topics = [];
  List<GeneralWhyModel> whys = [];
  bool fail = false;

  @override
  Future<List<GoalTopicModel>> fetchTopics() async {
    if (fail) throw const ServerException('offline');
    return topics;
  }

  @override
  Future<List<GeneralWhyModel>> fetchGeneralWhys() async {
    if (fail) throw const ServerException('offline');
    return whys;
  }
}

GoalTopicModel model(int id, String label, {bool gentle = false}) =>
    GoalTopicModel.fromJson({
      'id': id,
      'label': label,
      'gentle': gentle,
      'keywords': 'k$id',
      'sort_order': id,
      'goals': [
        {'suggestion': 'Second goal $id', 'sort_order': 2},
        {'suggestion': 'First goal $id', 'sort_order': 1},
        {'suggestion': '  ', 'sort_order': 3},
      ],
      'whys': [
        {'suggestion': 'Why $id', 'sort_order': 1},
      ],
    });

void main() {
  group('search', () {
    final fit = topic(1, 'Getting fit', keywords: 'gym run workout');
    final debt = topic(2, 'Getting out of debt');
    final studies = topic(3, 'My studies');

    test('a chip matches when its name starts with what was typed', () {
      expect(topicMatches(fit, 'get'), isTrue);
      expect(topicMatches(fit, 'Getting f'), isTrue);
      expect(topicMatches(fit, 'xyz'), isFalse);
      expect(topicMatches(fit, '   '), isFalse);
    });

    test('every word typed must start a word of the name or its keywords', () {
      expect(topicMatches(debt, 'out debt'), isTrue);
      expect(topicMatches(debt, 'out dog'), isFalse);
      expect(topicMatches(fit, 'gym'), isTrue);
      expect(topicMatches(fit, 'run gym'), isTrue);
    });

    test('filler words are ignored ("my stu" finds "My studies")', () {
      expect(topicMatches(studies, 'stu'), isTrue);
      expect(topicMatches(studies, 'my stu'), isTrue);
      expect(topicMatches(studies, 'my'), isTrue, reason: 'it starts with it');
      expect(topicMatches(debt, 'the'), isFalse, reason: 'only filler');
    });

    test('a chip\'s exact name, case and punctuation aside, is that chip', () {
      final all = [fit, debt, studies];
      expect(topicNamed(all, 'getting FIT'), fit);
      expect(topicNamed(all, ' my  studies! '), studies);
      expect(topicNamed(all, 'my stud'), isNull);
      expect(topicNamed(all, ''), isNull);
    });

    test('the chips arrive in steps of 20, then 15, then the rest', () {
      expect(chipSteps(50), [20, 35, 50]);
      expect(chipSteps(30), [20, 30]);
      expect(chipSteps(10), [10]);
      expect(chipSteps(20), [20]);
    });

    test('words that call for gentleness', () {
      expect(isGentleText('Staying sober'), isTrue);
      expect(isGentleText('Grieving my mum'), isTrue);
      expect(isGentleText('Quit smoking'), isTrue);
      expect(isGentleText('Surfing'), isFalse);
      expect(isGentleText('My garden'), isFalse);
    });

    test('the answer: a chip or the person\'s own words', () {
      final chip = TopicAnswer(chip: topic(1, 'Grief', gentle: true));
      expect(chip.label, 'Grief');
      expect(chip.gentle, isTrue);
      expect(chip.ready, isTrue);

      const own = TopicAnswer(text: ' My garden ');
      expect(own.label, 'My garden');
      expect(own.gentle, isFalse);
      expect(own.ready, isTrue);

      expect(const TopicAnswer(text: 'a').ready, isFalse);
      expect(const TopicAnswer().ready, isFalse);
      expect(const TopicAnswer(text: 'sobriety').gentle, isTrue);
    });
  });

  group('GoalTopicModel', () {
    test(
      'reads the row with goals and whys in sort order, blanks left out',
      () {
        final m = model(4, '  My family ');
        expect(m.id, 4);
        expect(m.label, 'My family');
        expect(m.sortOrder, 4);
        expect(m.keywords, 'k4');
        expect(m.goals, ['First goal 4', 'Second goal 4']);
        expect(m.whys, ['Why 4']);
        expect(m.gentle, isFalse);
      },
    );

    test('a bare row still reads', () {
      final m = GoalTopicModel.fromJson({'id': 1, 'label': 'X'});
      expect(
        (m.goals, m.whys, m.gentle, m.keywords),
        (const <String>[], const <String>[], false, ''),
      );
    });

    test('texts survive the trip to the device and back', () {
      const texts = ['One, "quoted"', 'Two\nlines', 'Ünïcode ✓'];
      expect(GoalTopicModel.decode(GoalTopicModel.encode(texts)), texts);
      expect(GoalTopicModel.decode('not json'), isEmpty);
      expect(GoalTopicModel.decode('{"a":1}'), isEmpty);
    });
  });

  group('GoalTopicRepositoryImpl', () {
    late AppDatabase db;
    late FakeRemote remote;
    late GoalTopicRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      remote = FakeRemote();
      repository = GoalTopicRepositoryImpl(
        remote,
        GoalTopicLocalDataSourceImpl(db),
      );
    });
    tearDown(() => db.close());

    Future<List<GoalTopic>> saved() async =>
        (await repository.watchTopics().first).getOrElse(() => throw 'failed');

    Future<List<String>> savedWhys() async =>
        (await repository.watchGeneralWhys().first).getOrElse(
          () => throw 'failed',
        );

    test('nothing saved yet is an empty list, not a failure', () async {
      expect(await saved(), isEmpty);
      expect(await savedWhys(), isEmpty);
    });

    test(
      'refresh saves topics (goals, whys) and general whys in order',
      () async {
        remote.topics = [
          model(2, 'Grief', gentle: true),
          model(1, 'Getting fit'),
        ];
        remote.whys = const [
          GeneralWhyModel(id: 11, text: 'Second', sortOrder: 2),
          GeneralWhyModel(id: 10, text: 'First', sortOrder: 1),
        ];
        expect((await repository.refresh()).isRight(), isTrue);

        final topics = await saved();
        expect([for (final t in topics) t.label], ['Getting fit', 'Grief']);
        expect(topics.last.gentle, isTrue);
        expect(topics.first.goals, ['First goal 1', 'Second goal 1']);
        expect(topics.first.whys, ['Why 1']);
        expect(topics.first.keywords, 'k1');
        expect(await savedWhys(), ['First', 'Second']);
      },
    );

    test('a refresh replaces: changed rows update, removed rows go', () async {
      remote
        ..topics = [model(1, 'Getting fit'), model(2, 'Grief')]
        ..whys = const [GeneralWhyModel(id: 10, text: 'Old', sortOrder: 1)];
      await repository.refresh();

      remote
        ..topics = [model(1, 'Fitness')]
        ..whys = const [GeneralWhyModel(id: 12, text: 'New', sortOrder: 1)];
      await repository.refresh();

      expect([for (final t in await saved()) t.label], ['Fitness']);
      expect(await savedWhys(), ['New']);
    });

    test('offline: a failure, and what is saved stays', () async {
      remote.topics = [model(1, 'Getting fit')];
      await repository.refresh();

      remote.fail = true;
      final result = await repository.refresh();
      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      expect([for (final t in await saved()) t.label], ['Getting fit']);
    });

    test('an empty answer is never trusted over what is saved', () async {
      remote.topics = [model(1, 'Getting fit')];
      await repository.refresh();

      remote.topics = [];
      expect((await repository.refresh()).isRight(), isTrue);
      expect([for (final t in await saved()) t.label], ['Getting fit']);
    });

    test('watching follows a refresh', () async {
      final labels = <List<String>>[];
      final sub = repository.watchTopics().listen(
        (r) => labels.add([for (final t in r.getOrElse(() => [])) t.label]),
      );
      await Future<void>.delayed(Duration.zero);
      remote.topics = [model(1, 'Getting fit')];
      await repository.refresh();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(labels, [
        <String>[],
        ['Getting fit'],
      ]);
    });
  });
}
