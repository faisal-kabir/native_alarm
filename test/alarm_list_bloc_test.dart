import 'package:eala/core/usecase/usecase.dart';
import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/alarm/domain/usecases/get_alarms_usecase.dart';
import 'package:eala/features/alarm/presentation/bloc/alarm_list_event.dart';
import 'package:eala/features/alarm/presentation/bloc/alarm_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

Alarm _alarm(String id, DateTime time, {bool enabled = true}) => Alarm(
  id: id,
  enabled: enabled,
  time: time,
  audioTrackId: 'morning_message',
  ringtoneId: 'default',
  label: 'Label $id',
  missionName: 'Mission $id',
);

void main() {
  group('GetAlarmsUseCase', () {
    test('switches off one-time alarms whose time has passed', () async {
      final repo = FakeAlarmRepository();
      final now = DateTime.now();
      await repo.saveAlarm(
        _alarm('past', now.subtract(const Duration(hours: 1))),
      );
      await repo.saveAlarm(_alarm('future', now.add(const Duration(hours: 1))));

      final result = await GetAlarmsUseCase(repo)(NoParams());
      final alarms = result.getOrElse(() => []);

      expect(alarms.firstWhere((a) => a.id == 'past').enabled, isFalse);
      expect(alarms.firstWhere((a) => a.id == 'future').enabled, isTrue);
      // Persisted, not only returned.
      expect(repo.store['past']!.enabled, isFalse);
    });
  });

  group('AlarmListBloc', () {
    test('loads saved alarms (they survive a new bloc = app restart)', () async {
      final repo = FakeAlarmRepository();
      final time = DateTime.now().add(const Duration(hours: 2));

      final first = buildAlarmListBloc(repo);
      first.add(SaveAlarmEvent(_alarm('a1', time)));
      await first.stream.firstWhere((s) => s is AlarmListLoaded);
      await first.close();

      final second = buildAlarmListBloc(repo)..add(const LoadAlarmsEvent());
      final loaded =
          await second.stream.firstWhere((s) => s is AlarmListLoaded)
              as AlarmListLoaded;
      expect(loaded.alarms.map((a) => a.id), ['a1']);
      expect(loaded.alarms.single.missionName, 'Mission a1');
      await second.close();
    });

    test('save updates an existing alarm and delete removes it', () async {
      final repo = FakeAlarmRepository();
      final time = DateTime.now().add(const Duration(hours: 2));
      final bloc = buildAlarmListBloc(repo);

      bloc.add(SaveAlarmEvent(_alarm('a1', time)));
      bloc.add(SaveAlarmEvent(_alarm('a1', time, enabled: false)));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repo.store['a1']!.enabled, isFalse);
      expect(repo.store.length, 1);

      bloc.add(const DeleteAlarmEvent('a1'));
      final state =
          await bloc.stream.firstWhere(
                (s) => s is AlarmListLoaded && s.alarms.isEmpty,
              )
              as AlarmListLoaded;
      expect(state.alarms, isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(repo.store, isEmpty);
      await bloc.close();
    });
  });
}
