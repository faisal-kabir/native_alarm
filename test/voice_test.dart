import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/features/area_of_life/data/datasources/area_of_life_local_data_source.dart';
import 'package:eala/features/area_of_life/data/datasources/area_of_life_remote_data_source.dart';
import 'package:eala/features/area_of_life/data/models/area_of_life_model.dart';
import 'package:eala/features/area_of_life/data/models/matter_suggestion_model.dart';
import 'package:eala/features/area_of_life/data/models/purpose_suggestion_model.dart';
import 'package:eala/features/area_of_life/data/repositories/area_of_life_repository_impl.dart';
import 'package:eala/features/voice/data/datasources/voice_local_data_source.dart';
import 'package:eala/features/voice/data/datasources/voice_remote_data_source.dart';
import 'package:eala/features/voice/data/models/voice_model.dart';
import 'package:eala/features/voice/data/repositories/voice_repository_impl.dart';
import 'package:eala/features/voice/domain/entities/voice.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVoiceRemote implements VoiceRemoteDataSource {
  List<VoiceModel> rows = [];
  bool fail = false;

  @override
  Future<List<VoiceModel>> fetchVoices() async {
    if (fail) throw const ServerException('offline');
    return rows;
  }
}

VoiceModel voice(int id, String name, {String? audio = 'voices/a.mp3'}) =>
    VoiceModel.fromJson({
      'id': id,
      'name': name,
      'voice_id': 'v_$id',
      'audio': audio,
      'avatar': 'voices/$id.png',
      'group_id': 7,
      'gender': 'female',
      'accent': 'British',
      'traits': 'calm, warm',
      'color': '#112233',
      'is_premium': id.isEven,
      'voice_group': {'id': 7, 'title': 'Warm', 'description': 'Kind'},
    });

class FakeAreaRemote implements AreaOfLifeRemoteDataSource {
  final requested = <int>[];
  bool fail = false;

  @override
  Future<List<AreaOfLifeModel>> fetchAreas() async => [];

  @override
  Future<List<PurposeSuggestionModel>> fetchPurposeSuggestions(
    int areaId,
  ) async {
    requested.add(areaId);
    if (fail) throw const ServerException('offline');
    return [
      PurposeSuggestionModel.fromJson({
        'id': 1,
        'area_id': areaId,
        'suggestion': 'Go.',
      }),
    ];
  }

  final matterRequested = <(int, int?)>[];

  @override
  Future<List<MatterSuggestionModel>> fetchMatterSuggestions(
    int areaId,
    int? purposeSuggestionId,
  ) async {
    matterRequested.add((areaId, purposeSuggestionId));
    if (fail) throw const ServerException('offline');
    return [
      MatterSuggestionModel.fromJson({
        'id': 9,
        'area_id': areaId,
        'purpose_suggestion_id': purposeSuggestionId,
        'suggestion': 'Because.',
      }),
    ];
  }
}

void main() {
  group('VoiceModel', () {
    test('reads every column; audio and avatar stay paths', () {
      final model = voice(2, 'Calm');
      expect(model.id, 2);
      expect(model.voiceId, 'v_2');
      expect(model.audio, 'voices/a.mp3');
      expect(model.avatar, 'voices/2.png');
      expect(model.groupId, 7);
      expect(model.group?.title, 'Warm');
      expect(model.group?.description, 'Kind');
      expect(model.gender, 'female');
      expect(model.accent, 'British');
      expect(model.traits, 'calm, warm');
      expect(model.color, 0xFF112233);
      expect(model.isPremium, isTrue);
    });

    test('missing and blank columns become null / false', () {
      final model = VoiceModel.fromJson({
        'id': 1,
        'name': 'X',
        'voice_id': 'v',
        'audio': ' ',
        'avatar': null,
        'group_id': null,
        'is_premium': null,
        'color': 'oops',
      });
      expect(model.audio, isNull);
      expect(model.avatar, isNull);
      expect(model.groupId, isNull);
      expect(model.group, isNull);
      expect(model.color, isNull);
      expect(model.isPremium, isFalse);
    });
  });

  group('VoiceRepositoryImpl (local first)', () {
    late AppDatabase db;
    late FakeVoiceRemote remote;
    late VoiceRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      remote = FakeVoiceRemote();
      repository = VoiceRepositoryImpl(remote, VoiceLocalDataSourceImpl(db));
    });

    tearDown(() => db.close());

    Future<List<Voice>> saved() async =>
        (await repository.watchVoices().first).getOrElse(() => []);

    test('the first update saves every column on the device', () async {
      remote.rows = [voice(2, 'Calm'), voice(1, 'Bold')];
      await repository.refreshVoices();
      final voices = await saved();
      expect(voices.map((v) => v.name), ['Bold', 'Calm']);
      final calm = voices.last;
      expect(calm.audio, 'voices/a.mp3');
      expect(calm.avatar, 'voices/2.png');
      expect(calm.groupId, 7);
      // The joined group is kept on the device with the voice.
      expect(calm.group?.id, 7);
      expect(calm.group?.title, 'Warm');
      expect(calm.group?.description, 'Kind');
      expect(calm.traits, 'calm, warm');
      expect(calm.color, 0xFF112233);
      expect(calm.isPremium, isTrue);
    });

    test('later updates change, add and remove rows', () async {
      remote.rows = [voice(1, 'Bold'), voice(2, 'Calm')];
      await repository.refreshVoices();
      remote.rows = [voice(1, 'Bolder'), voice(3, 'Soft')];
      await repository.refreshVoices();
      expect((await saved()).map((v) => v.name), ['Bolder', 'Soft']);
    });

    test('failures and empty answers keep what is saved', () async {
      remote.rows = [voice(1, 'Bold')];
      await repository.refreshVoices();

      remote.fail = true;
      final failed = await repository.refreshVoices();
      expect(failed.isLeft(), isTrue);
      failed.fold((f) => expect(f, isA<ServerFailure>()), (_) {});

      remote
        ..fail = false
        ..rows = [];
      expect((await repository.refreshVoices()).isRight(), isTrue);
      expect((await saved()).map((v) => v.name), ['Bold']);
    });

    test('the saved voices follow an update on their own', () async {
      final seen = <int>[];
      final sub = repository.watchVoices().listen(
        (r) => seen.add(r.getOrElse(() => []).length),
      );
      await Future<void>.delayed(Duration.zero);
      remote.rows = [voice(1, 'Bold')];
      await repository.refreshVoices();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.first, 0);
      expect(seen.last, 1);
    });
  });

  group('Quotes of an area (no cache)', () {
    late AppDatabase db;
    late FakeAreaRemote remote;
    late AreaOfLifeRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      remote = FakeAreaRemote();
      repository = AreaOfLifeRepositoryImpl(
        remote,
        AreaOfLifeLocalDataSourceImpl(db),
      );
    });

    tearDown(() => db.close());

    test('every call asks the server for that area id', () async {
      await repository.getPurposeSuggestions(3);
      await repository.getPurposeSuggestions(3);
      final result = await repository.getPurposeSuggestions(5);
      expect(remote.requested, [3, 3, 5]);
      expect(result.getOrElse(() => []).single.areaId, 5);
    });

    test('offline is a failure, nothing is served from a copy', () async {
      await repository.getPurposeSuggestions(3);
      remote.fail = true;
      final result = await repository.getPurposeSuggestions(3);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });

    test('a quote row without text is skipped by the model', () {
      expect(
        PurposeSuggestionModel.fromJson({
          'id': 1,
          'area_id': 2,
          'suggestion': '  ',
        }).text,
        isEmpty,
      );
    });

    test(
      'matter suggestions ask the server for the area and purpose id',
      () async {
        final forPick = await repository.getMatterSuggestions(3, 11);
        final general = await repository.getMatterSuggestions(3, null);
        expect(remote.matterRequested, [(3, 11), (3, null)]);
        expect(forPick.getOrElse(() => []).single.purposeSuggestionId, 11);
        expect(general.getOrElse(() => []).single.purposeSuggestionId, isNull);

        remote.fail = true;
        expect(
          (await repository.getMatterSuggestions(3, null)).isLeft(),
          isTrue,
        );
      },
    );

    test('a matter row reads its columns', () {
      final model = MatterSuggestionModel.fromJson({
        'id': 4,
        'area_id': 11,
        'purpose_suggestion_id': null,
        'suggestion': ' I want to say yes to life again ',
      });
      expect(model.areaId, 11);
      expect(model.purposeSuggestionId, isNull);
      expect(model.text, 'I want to say yes to life again');
    });
  });
}
