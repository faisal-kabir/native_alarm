import 'package:equatable/equatable.dart';

import '../../domain/entities/alarm.dart';

abstract class AlarmListEvent extends Equatable {
  const AlarmListEvent();

  @override
  List<Object?> get props => [];
}

class LoadAlarmsEvent extends AlarmListEvent {
  const LoadAlarmsEvent();
}

class SaveAlarmEvent extends AlarmListEvent {
  final Alarm alarm;

  const SaveAlarmEvent(this.alarm);

  @override
  List<Object?> get props => [alarm];
}

class DeleteAlarmEvent extends AlarmListEvent {
  final String alarmId;

  const DeleteAlarmEvent(this.alarmId);

  @override
  List<Object?> get props => [alarmId];
}
