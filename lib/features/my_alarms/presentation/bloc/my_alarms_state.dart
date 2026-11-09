import 'package:equatable/equatable.dart';

import '../../../alarm/domain/entities/alarm.dart';
import '../../../reasons/domain/entities/reason.dart';

abstract class MyAlarmsState extends Equatable {
  const MyAlarmsState();

  @override
  List<Object?> get props => [];
}

class MyAlarmsInitial extends MyAlarmsState {
  const MyAlarmsInitial();
}

class MyAlarmsLoading extends MyAlarmsState {
  const MyAlarmsLoading();
}

class MyAlarmsLoaded extends MyAlarmsState {
  /// The saved alarms: the switched-on ones by their next ring, then the others.
  final List<Alarm> alarms;

  /// The cached reasons (each alarm shows the one it plays).
  final List<Reason> reasons;

  /// How many alarms are allowed.
  final int alarmLimit;

  /// Goes up by one each time a switch could not be changed (the page says so).
  final int toggleFailures;

  const MyAlarmsLoaded({
    required this.alarms,
    required this.alarmLimit,
    this.reasons = const [],
    this.toggleFailures = 0,
  });

  /// How many alarms exist (fills that many meter pills).
  int get alarmCount => alarms.length;

  /// The Reason [alarm] plays, once it is in the cached list.
  Reason? reasonOf(Alarm alarm) {
    for (final r in reasons) {
      if (r.id == alarm.reasonId) return r;
    }
    return null;
  }

  MyAlarmsLoaded copyWith({
    List<Alarm>? alarms,
    List<Reason>? reasons,
    int? toggleFailures,
  }) => MyAlarmsLoaded(
    alarms: alarms ?? this.alarms,
    reasons: reasons ?? this.reasons,
    alarmLimit: alarmLimit,
    toggleFailures: toggleFailures ?? this.toggleFailures,
  );

  @override
  List<Object?> get props => [alarms, reasons, alarmLimit, toggleFailures];
}

class MyAlarmsFailure extends MyAlarmsState {
  final String message;

  const MyAlarmsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
