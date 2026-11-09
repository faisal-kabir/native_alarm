import 'package:equatable/equatable.dart';

import '../../../alarm/domain/entities/alarm.dart';

abstract class MyAlarmsEvent extends Equatable {
  const MyAlarmsEvent();

  @override
  List<Object?> get props => [];
}

/// Switches off one-off alarms that have rung and checks alarm access (sent on open
/// and whenever the app comes back); the list itself follows [WatchMyAlarmsEvent].
class LoadMyAlarmsEvent extends MyAlarmsEvent {
  const LoadMyAlarmsEvent();
}

/// Follows the saved alarms, so a change made anywhere (the editor, a Reason deleted
/// with its alarm) shows at once.
class WatchMyAlarmsEvent extends MyAlarmsEvent {
  const WatchMyAlarmsEvent();
}

/// Follows the cached reasons, so each alarm shows the Reason it plays.
class WatchMyAlarmsReasonsEvent extends MyAlarmsEvent {
  const WatchMyAlarmsReasonsEvent();
}

/// An alarm card's switch.
class MyAlarmsAlarmToggledEvent extends MyAlarmsEvent {
  final Alarm alarm;
  final bool enabled;

  const MyAlarmsAlarmToggledEvent(this.alarm, {required this.enabled});

  @override
  List<Object?> get props => [alarm, enabled];
}

/// "Enable Alarm Access": the system's prompt (or its settings), then access is
/// checked again.
class MyAlarmsAccessRequestedEvent extends MyAlarmsEvent {
  const MyAlarmsAccessRequestedEvent();
}

/// A card was swiped away and the delete confirmed: the alarm goes everywhere.
class MyAlarmsAlarmDeletedEvent extends MyAlarmsEvent {
  final Alarm alarm;

  const MyAlarmsAlarmDeletedEvent(this.alarm);

  @override
  List<Object?> get props => [alarm];
}
