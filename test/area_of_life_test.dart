import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/error/exceptions.dart';
import 'package:eala/core/error/failures.dart';
import 'package:eala/core/utils/server_value.dart';
import 'package:eala/features/area_of_life/data/datasources/area_of_life_local_data_source.dart';
import 'package:eala/features/area_of_life/data/datasources/area_of_life_remote_data_source.dart';
import 'package:eala/features/area_of_life/data/models/area_of_life_model.dart';
import 'package:eala/features/area_of_life/data/models/purpose_suggestion_model.dart';
import 'package:eala/features/area_of_life/data/repositories/area_of_life_repository_impl.dart';
import 'package:eala/features/area_of_life/domain/entities/area_of_life.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemote implements AreaOfLifeRemoteDataSource {
  List<AreaOfLifeModel> rows = [];
  bool fail = false;

  @override
  Future<List<AreaOfLifeModel>> fetchAreas() async {
    if (fail) throw const ServerException('offline');
    return rows;
  }

  @override
  Future<List<PurposeSuggestionModel>> fetchPurposeSuggestions(
    int areaId,
  ) async => [];
}

AreaOfLifeModel area(int id, String title, {String? color = '#112233'}) =>
    AreaOfLifeModel.fromJson({
      'id': id,
      'name': 'area_$id',
      'title': title,
      'description': 'About $title',
      'icon': null,
      'color': color,
    });

void main() {
  group('AreaOfLifeModel', () {
    test('reads the server row, colour as ARGB', () {
      final model = AreaOfLifeModel.fromJson({
        'id': 3,
        'name': 'health',
        'title': 'Health',
        'description': 'Body & mind',
        'icon': 'https://example.com/health.svg',
        'color': '#C96B4B',
      });
      expect(model.id, 3);
      expect(model.title, 'Health');
      expect(model.description, 'Body & mind');
      expect(model.icon, 'https://example.com/health.svg');
      expect(model.color, 0xFFC96B4B);
    });

    test(
      'falls back: title -> name, blank texts -> null, bad colour -> null',
      () {
        final model = AreaOfLifeModel.fromJson({
          'id': 1,
          'name': 'work',
          'title': null,
          'description': '  ',
          'icon': '',
          'color': 'not a colour',
        });
        expect(model.title, 'work');
        expect(model.description, isNull);
        expect(model.icon, isNull);
        expect(model.color, isNull);
      },
    );

    test('accepts colours with and without # and with alpha', () {
      expect(parseHexColor('112233'), 0xFF112233);
      expect(parseHexColor('#80112233'), 0x80112233);
      expect(parseHexColor(null), isNull);
    });
  });

  group('AreaOfLifeRepositoryImpl (local first)', () {
    late AppDatabase db;
    late FakeRemote remote;
    late AreaOfLifeRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      remote = FakeRemote();
      repository = AreaOfLifeRepositoryImpl(
        remote,
        AreaOfLifeLocalDataSourceImpl(db),
      );
    });

    tearDown(() => db.close());

    Future<List<AreaOfLife>> saved() async =>
        (await repository.watchAreas().first).getOrElse(() => []);

    test('nothing is saved before the first update', () async {
      expect(await saved(), isEmpty);
    });

    test('the first update saves the server rows, in id order', () async {
      remote.rows = [area(2, 'Work'), area(1, 'Health')];
      expect(await repository.refreshAreas(), const Right(unit));
      final areas = await saved();
      expect(areas.map((a) => a.title), ['Health', 'Work']);
      expect(areas.first.color, 0xFF112233);
    });

    test('a later update changes, adds and removes rows', () async {
      remote.rows = [area(1, 'Health'), area(2, 'Work')];
      await repository.refreshAreas();

      remote.rows = [area(1, 'Wellbeing'), area(3, 'Family')];
      await repository.refreshAreas();

      final areas = await saved();
      expect(areas.map((a) => a.title), ['Wellbeing', 'Family']);
      expect(areas.map((a) => a.id), [1, 3]);
    });

    test('the saved areas follow the update on their own (stream)', () async {
      final seen = <List<String>>[];
      final sub = repository.watchAreas().listen(
        (r) => seen.add(r.getOrElse(() => []).map((a) => a.title).toList()),
      );
      await Future<void>.delayed(Duration.zero);
      remote.rows = [area(1, 'Health')];
      await repository.refreshAreas();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.first, isEmpty);
      expect(seen.last, ['Health']);
    });

    test(
      'a failed update keeps what is saved and reports the failure',
      () async {
        remote.rows = [area(1, 'Health')];
        await repository.refreshAreas();

        remote.fail = true;
        final result = await repository.refreshAreas();
        expect(result.isLeft(), isTrue);
        result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
        expect((await saved()).map((a) => a.title), ['Health']);
      },
    );

    test('an empty answer never wipes the saved areas', () async {
      remote.rows = [area(1, 'Health')];
      await repository.refreshAreas();

      remote.rows = [];
      expect(await repository.refreshAreas(), const Right(unit));
      expect((await saved()).map((a) => a.title), ['Health']);
    });
  });
}
