import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/error/exceptions.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_bloc.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_event.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_state.dart';
import 'package:eala/features/reasons/data/datasources/reason_local_data_source.dart';
import 'package:eala/features/reasons/data/datasources/reason_remote_data_source.dart';
import 'package:eala/features/reasons/data/repositories/reason_repository_impl.dart';
import 'package:eala/features/reasons/domain/entities/new_reason.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/entities/reason_name.dart';
import 'package:eala/features/reasons/domain/usecases/rename_reason_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/watch_reasons_usecase.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_event.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `reason` and `user` tables, in memory.
class FakeReasonRemote implements ReasonRemoteDataSource {
  FakeReasonRemote({this.userId = 7, this.names = const []});

  final int userId;
  final List<String> names;
  bool offline = false;
  final List<Map<String, Object?>> inserted = [];
  final List<(int, String)> updates = [];
  String? lastPrefix;

  void _check() {
    if (offline) throw const ServerException('offline');
  }

  @override
  Future<int> fetchOwnUserId() async {
    _check();
    return userId;
  }

  @override
  Future<List<String>> fetchNamesStartingWith(int userId, String base) async {
    _check();
    lastPrefix = base;
    return names.where((n) => n.startsWith(base)).toList();
  }

  @override
  Future<int> insertReason(int userId, String name, NewReason reason) async {
    _check();
    inserted.add({
      'user_id': userId,
      'area_id': reason.areaId,
      'name': name,
      'purpose': reason.purpose,
      'why': reason.why,
      'sound_type_id': reason.soundTypeId,
      'voice_id': reason.voiceId,
      'length': reason.lengthSeconds,
    });
    return 40 + inserted.length;
  }

  @override
  Future<void> updateName(int id, String name) async {
    _check();
    updates.add((id, name));
  }
}

const newReason = NewReason(
  areaId: 3,
  baseName: 'Health',
  purpose: 'Sleep well',
  why: 'I feel better',
  soundTypeId: 2,
  voiceId: 5,
  lengthSeconds: 45,
  areaTitle: 'Health & body',
  areaColor: 0xFF30D158,
  soundTitle: 'Calm',
);

void main() {
  group('nextReasonName', () {
    test('a new name is used as it is', () {
      expect(nextReasonName('Health', const []), 'Health');
      expect(nextReasonName(' Health ', const ['Work']), 'Health');
    });

    test('a used name gets one more than the highest number', () {
      expect(nextReasonName('Health', const ['Health']), 'Health 2');
      expect(
        nextReasonName('Health', const ['Health', 'Health 2', 'Health 5']),
        'Health 6',
      );
      // Numbered ones count even when the plain name was renamed away.
      expect(nextReasonName('Health', const ['Health 3']), 'Health 4');
    });

    test('names that only start the same do not count', () {
      expect(
        nextReasonName('Health', const [
          'Healthy',
          'Health club 9',
          'Health x',
        ]),
        'Health',
      );
    });
  });

  group('ReasonRepositoryImpl', () {
    late AppDatabase db;
    late FakeReasonRemote remote;
    late ReasonRepositoryImpl repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      remote = FakeReasonRemote(names: const ['Health', 'Health 2']);
      repository = ReasonRepositoryImpl(remote, ReasonLocalDataSourceImpl(db));
    });

    tearDown(() => db.close());

    Future<void> insert(String id, String name, int minute) {
      return db
          .into(db.reasonsTable)
          .insert(
            ReasonsTableCompanion.insert(
              reasonId: id,
              name: name,
              areaName: 'Area',
              toneName: 'Tone',
              createdAt: Value(DateTime(2026, 11, 5, 4, minute)),
            ),
          );
    }

    test('the list is the saved reasons, oldest first', () async {
      await insert('b', 'Second', 5);
      await insert('a', 'First', 1);
      final first = await repository.watchReasons().first;
      expect(first.getOrElse(() => []).map((r) => r.id), ['a', 'b']);
    });

    test(
      'create: saved for the user with the next free name, then on the device',
      () async {
        final result = await repository.createReason(newReason);

        expect(remote.lastPrefix, 'Health');
        expect(remote.inserted.single, {
          'user_id': 7,
          'area_id': 3,
          'name': 'Health 3',
          'purpose': 'Sleep well',
          'why': 'I feel better',
          'sound_type_id': 2,
          'voice_id': 5,
          'length': 45,
        });
        const expected = Reason(
          id: '41',
          name: 'Health 3',
          areaName: 'Health & body',
          areaColor: 0xFF30D158,
          toneName: 'Calm',
        );
        expect(result.getOrElse(() => throw 'failed'), expected);
        final list = await repository.watchReasons().first;
        expect(list.getOrElse(() => []), [expected]);
      },
    );

    test('create offline fails and saves nothing on the device', () async {
      remote.offline = true;
      final result = await repository.createReason(newReason);
      expect(result.isLeft(), isTrue);
      final list = await repository.watchReasons().first;
      expect(list.getOrElse(() => throw 'failed'), isEmpty);
    });

    test('rename updates the server row by id and the device copy', () async {
      await insert('41', 'Health', 1);
      final result = await repository.renameReason('41', 'Mornings');
      expect(result.isRight(), isTrue);
      expect(remote.updates, [(41, 'Mornings')]);
      final list = await repository.watchReasons().first;
      expect(list.getOrElse(() => []).single.name, 'Mornings');
    });

    test('rename offline keeps the old name on the device', () async {
      await insert('41', 'Health', 1);
      remote.offline = true;
      final result = await repository.renameReason('41', 'Mornings');
      expect(result.isLeft(), isTrue);
      final list = await repository.watchReasons().first;
      expect(list.getOrElse(() => []).single.name, 'Health');
    });

    test('ReasonsBloc follows the list: a new reason shows up', () async {
      final bloc = ReasonsBloc(WatchReasonsUseCase(repository))
        ..add(const LoadReasonsEvent());
      final states = <ReasonsState>[];
      final sub = bloc.stream.listen(states.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repository.createReason(newReason);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.first, isA<ReasonsLoading>());
      expect((states[1] as ReasonsLoaded).reasons, isEmpty);
      expect((states.last as ReasonsLoaded).reasons.single.name, 'Health 3');
      await sub.cancel();
      await bloc.close();
    });

    test('ReasonReadyBloc: a failed rename puts the old name back', () async {
      await insert('41', 'Health', 1);
      final bloc = ReasonReadyBloc(RenameReasonUseCase(repository))
        ..add(const ReasonReadyStartedEvent('41', 'Health'));
      await Future<void>.delayed(Duration.zero);
      remote.offline = true;
      bloc.add(const ReasonRenamedEvent('Mornings'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        bloc.state,
        const ReasonReadyState(id: '41', name: 'Health', renameFailures: 1),
      );

      remote.offline = false;
      bloc.add(const ReasonRenamedEvent(' Mornings '));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.name, 'Mornings');
      expect(remote.updates, [(41, 'Mornings')]);
      await bloc.close();
    });
  });
}
