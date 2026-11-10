import 'dart:async';

import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/error/exceptions.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/alarm/domain/usecases/watch_alarms_usecase.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_bloc.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_event.dart';
import 'package:eala/features/create_reason/presentation/bloc/reason_ready_state.dart';
import 'package:eala/features/reasons/data/datasources/reason_local_data_source.dart';
import 'package:eala/features/reasons/data/datasources/reason_remote_data_source.dart';
import 'package:eala/features/reasons/data/models/reason_model.dart';
import 'package:eala/features/reasons/data/repositories/reason_repository_impl.dart';
import 'package:eala/features/reasons/domain/entities/new_reason.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/entities/reason_draft.dart';
import 'package:eala/features/reasons/domain/entities/reason_name.dart';
import 'package:eala/features/reasons/domain/usecases/refresh_reasons_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/rename_reason_usecase.dart';
import 'package:eala/features/reasons/domain/usecases/watch_reasons_usecase.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_event.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

/// A `reason` row as the server answers [reasonSelect]: area, sound and voice joined.
Map<String, dynamic> serverRow(
  int id,
  String name, {
  String createdAt = '2026-11-05T04:00:00Z',
  int areaId = 3,
  String purpose = 'Sleep well',
  String? why = 'I feel better',
  int soundTypeId = 2,
  int voiceId = 5,
  int length = 45,
}) => {
  'id': id,
  'name': name,
  'created_at': createdAt,
  'area_id': areaId,
  'purpose': purpose,
  'why': why,
  'sound_type_id': soundTypeId,
  'voice_id': voiceId,
  'length': length,
  'area_of_life': {
    'id': areaId,
    'name': 'Health',
    'title': 'Health & body',
    'color': '#30D158',
    'icon': 'icons/health.svg',
  },
  'sound_type': {'id': soundTypeId, 'title': 'Calm'},
  'voice': {
    'id': voiceId,
    'name': 'Astra',
    'voice_id': 'v_astra',
    'voice_group': {'id': 1, 'title': 'Warm', 'description': 'Kind'},
  },
};

/// The `reason` and `user` tables, in memory: answers like the server (joined rows).
class FakeReasonRemote implements ReasonRemoteDataSource {
  FakeReasonRemote({this.userId = 7, this.names = const []});

  final int userId;
  final List<String> names;
  bool offline = false;
  final Map<int, Map<String, dynamic>> rows = {};
  final List<Map<String, Object?>> inserted = [];
  final List<(int, Map<String, Object?>)> updates = [];
  String? lastPrefix;

  /// Holds [fetchReasons]'s answer until completed (to test overlapping writes).
  Completer<void>? fetchGate;

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
  Future<Map<String, dynamic>> insertReason(
    int userId,
    String name,
    ReasonDraft draft,
  ) async {
    _check();
    final columns = {
      'user_id': userId,
      'name': name,
      ...reasonDraftColumns(draft),
    };
    inserted.add(columns);
    final id = 40 + inserted.length;
    return rows[id] = serverRow(
      id,
      name,
      areaId: draft.areaId,
      purpose: draft.purpose,
      why: columns['why'] as String?,
      soundTypeId: draft.soundTypeId,
      voiceId: draft.voiceId,
      length: draft.lengthSeconds,
    );
  }

  @override
  Future<Map<String, dynamic>> updateReason(
    int id,
    Map<String, Object?> changes,
  ) async {
    _check();
    updates.add((id, changes));
    return rows[id] = {...rows[id]!, ...changes};
  }

  /// Rows the server lets this user delete (row-level security); others stay.
  bool mayDelete = true;

  @override
  Future<void> deleteReason(int id) async {
    _check();
    if (!mayDelete || rows.remove(id) == null) {
      throw const ServerException('Reason not deleted');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReasons() async {
    _check();
    final answer = rows.values.toList();
    await fetchGate?.future;
    return answer;
  }
}

const newReason = NewReason(
  baseName: 'Health',
  draft: ReasonDraft(
    areaId: 3,
    purpose: 'Sleep well',
    why: 'I feel better',
    soundTypeId: 2,
    voiceId: 5,
    lengthSeconds: 45,
  ),
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

  group('reasonFromJson', () {
    test('one row is the whole reason: area, sound and voice joined', () {
      final reason = reasonFromJson(serverRow(9, ' Mornings '));
      expect(reason.id, 9);
      expect(reason.name, 'Mornings');
      expect(reason.draft, newReason.draft);
      expect(reason.areaTitle, 'Health & body');
      expect(reason.area!.color, 0xFF30D158);
      expect(reason.area!.icon, 'icons/health.svg');
      expect(reason.toneTitle, 'Calm');
      expect(reason.voice!.name, 'Astra');
      expect(reason.voice!.group!.title, 'Warm');
      expect(reason.createdAt, DateTime.utc(2026, 11, 5, 4).toLocal());
    });

    test('a row without its joins still reads (ids kept, no "why")', () {
      final reason = reasonFromJson({
        'id': 3,
        'name': 'X',
        'area_id': 4,
        'sound_type_id': 5,
        'voice_id': 6,
      });
      expect((reason.area, reason.sound, reason.voice), (null, null, null));
      expect((reason.areaId, reason.soundTypeId, reason.voiceId), (4, 5, 6));
      expect((reason.why, reason.lengthSeconds), ('', 30));
      expect(reason.alarmId, isNull);
    });

    test('alarm_id says which alarm plays it', () {
      final reason = reasonFromJson({...serverRow(9, 'X'), 'alarm_id': 12});
      expect(reason.alarmId, 12);
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

    Future<List<Reason>> saved() async =>
        (await repository.watchReasons().first).getOrElse(() => throw 'failed');

    Future<Reason> create() async =>
        (await repository.createReason(newReason))
            .getOrElse(() => throw 'failed');

    test('create: next free name, saved on the server, then the whole row '
        'on the device', () async {
      final created = await create();
      expect(remote.lastPrefix, 'Health');
      expect(remote.inserted.single, {
        'user_id': 7,
        'name': 'Health 3',
        'area_id': 3,
        'purpose': 'Sleep well',
        'why': 'I feel better',
        'sound_type_id': 2,
        'voice_id': 5,
        'length': 45,
      });
      expect(created.name, 'Health 3');
      expect(created.voice!.name, 'Astra');
      expect(await saved(), [created]);
    });

    test('create offline fails and saves nothing on the device', () async {
      remote.offline = true;
      expect((await repository.createReason(newReason)).isLeft(), isTrue);
      expect(await saved(), isEmpty);
    });

    test('an empty "why" is saved as null', () {
      expect(
        reasonDraftColumns(newReason.draft.copyWith(why: '  '))['why'],
        isNull,
      );
    });

    test('rename updates the row by id; the device follows', () async {
      final id = (await create()).id;
      final result = await repository.renameReason(id, ' Mornings ');
      expect(result.getOrElse(() => throw 'failed').name, 'Mornings');
      expect(remote.updates.single.$1, id);
      expect(remote.updates.single.$2, {'name': 'Mornings'});
      expect((await saved()).single.name, 'Mornings');
    });

    test(
      'update saves every chosen value at once; the device follows',
      () async {
        final id = (await create()).id;
        final draft = newReason.draft.copyWith(
          purpose: 'Run a marathon',
          why: '',
          lengthSeconds: 30,
        );
        final result = await repository.updateReason(id, draft);
        expect(remote.updates.single.$2, reasonDraftColumns(draft));
        expect(result.getOrElse(() => throw 'failed').draft, draft);
        expect((await saved()).single.draft, draft);
      },
    );

    test('a failed update leaves the device copy as it was', () async {
      final created = await create();
      remote.offline = true;
      final result = await repository.updateReason(
        created.id,
        created.draft.copyWith(purpose: 'Something else'),
      );
      expect(result.isLeft(), isTrue);
      expect(await saved(), [created]);
    });

    test('delete removes the reason on the server, then here', () async {
      final created = await create();
      expect((await repository.deleteReason(created.id)).isRight(), isTrue);
      expect(remote.rows, isEmpty);
      expect(await saved(), isEmpty);
    });

    test('a delete the server refuses (or offline) keeps it here', () async {
      final created = await create();
      remote.mayDelete = false;
      expect((await repository.deleteReason(created.id)).isLeft(), isTrue);
      remote.mayDelete = true;
      remote.offline = true;
      expect((await repository.deleteReason(created.id)).isLeft(), isTrue);
      expect(await saved(), [created]);
    });

    test('watchReason follows one reason', () async {
      final created = await create();
      final names = <String?>[];
      final sub = repository
          .watchReason(created.id)
          .listen((r) => names.add(r.getOrElse(() => null)?.name));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repository.renameReason(created.id, 'Mornings');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(names, ['Health 3', 'Mornings']);
      await sub.cancel();
    });

    test(
      'refresh makes the device copy match the server, oldest first',
      () async {
        remote.rows[1] = serverRow(
          1,
          'Late',
          createdAt: '2026-11-05T09:00:00Z',
        );
        remote.rows[2] = serverRow(
          2,
          'Early',
          createdAt: '2026-11-05T03:00:00Z',
        );
        expect((await repository.refreshReasons()).isRight(), isTrue);
        expect([for (final r in await saved()) r.name], ['Early', 'Late']);

        // Deleted on the server (another phone): gone here too.
        remote.rows.remove(1);
        await repository.refreshReasons();
        expect([for (final r in await saved()) r.name], ['Early']);
      },
    );

    test('refresh offline keeps the saved reasons', () async {
      remote.rows[1] = serverRow(1, 'Saved');
      await repository.refreshReasons();
      remote.offline = true;
      expect((await repository.refreshReasons()).isLeft(), isTrue);
      expect((await saved()).single.name, 'Saved');
    });

    test('a reason saved while a refresh is downloading is kept', () async {
      remote.fetchGate = Completer<void>();
      // The refresh downloads the list (still without the new reason) and waits...
      final refresh = repository.refreshReasons();
      // ...while a new reason is being saved.
      final created = repository.createReason(newReason);
      remote.fetchGate!.complete();
      await refresh;
      await created;
      expect([for (final r in await saved()) r.name], ['Health 3']);
    });

    test('ReasonsBloc refreshes from the server when it starts', () async {
      remote.rows[5] = serverRow(5, 'From server');
      final bloc = ReasonsBloc(
        WatchReasonsUseCase(repository),
        RefreshReasonsUseCase(repository),
        WatchAlarmsUseCase(FakeAlarmRepository()),
      )..add(const LoadReasonsEvent());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as ReasonsLoaded).reasons.single.name, 'From server');
      await bloc.close();
    });

    test('ReasonsBloc marks each reason an alarm plays, on or off', () async {
      remote.rows[5] = serverRow(5, 'Played');
      remote.rows[6] = serverRow(6, 'Free');
      final alarms = FakeAlarmRepository();
      final bloc = ReasonsBloc(
        WatchReasonsUseCase(repository),
        RefreshReasonsUseCase(repository),
        WatchAlarmsUseCase(alarms),
      )..add(const LoadReasonsEvent());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as ReasonsLoaded).alarmOn, isEmpty);

      final alarm = Alarm(
        id: 'a',
        enabled: false,
        time: DateTime(2026, 11, 10, 6, 30),
        audioTrackId: 'm',
        ringtoneId: 'default',
        reasonId: 5,
      );
      await alarms.saveAlarm(alarm);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((bloc.state as ReasonsLoaded).alarmOn, {5: false});

      await alarms.saveAlarm(alarm.copyWith(enabled: true));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect((bloc.state as ReasonsLoaded).alarmOn, {5: true});
      await bloc.close();
    });

    test('ReasonReadyBloc: a failed rename puts the old name back', () async {
      final created = await create();
      final bloc = ReasonReadyBloc(RenameReasonUseCase(repository))
        ..add(ReasonReadyStartedEvent(created.id, created.name));
      await Future<void>.delayed(Duration.zero);
      remote.offline = true;
      bloc.add(const ReasonRenamedEvent('Mornings'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        bloc.state,
        ReasonReadyState(id: created.id, name: 'Health 3', renameFailures: 1),
      );

      remote.offline = false;
      bloc.add(const ReasonRenamedEvent(' Mornings '));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.name, 'Mornings');
      await bloc.close();
    });
  });
}
