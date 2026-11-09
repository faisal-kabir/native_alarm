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
  /// The saved alarms, as saved (the page lays them out: `arrangeAlarms`).
  final List<Alarm> alarms;

  /// The cached reasons (each alarm shows the one it plays).
  final List<Reason> reasons;

  /// How many alarms are allowed.
  final int alarmLimit;

  /// The system has not granted alarm access: nothing can ring (the list dims, a
  /// banner asks for it, a switched-on card says it won't ring).
  final bool accessDenied;

  /// Go up by one each time a switch could not be changed / an alarm could not be
  /// deleted (the page says so).
  final int toggleFailures;
  final int deleteFailures;

  const MyAlarmsLoaded({
    required this.alarms,
    required this.alarmLimit,
    this.reasons = const [],
    this.accessDenied = false,
    this.toggleFailures = 0,
    this.deleteFailures = 0,
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
    bool? accessDenied,
    int? toggleFailures,
    int? deleteFailures,
  }) => MyAlarmsLoaded(
    alarms: alarms ?? this.alarms,
    reasons: reasons ?? this.reasons,
    alarmLimit: alarmLimit,
    accessDenied: accessDenied ?? this.accessDenied,
    toggleFailures: toggleFailures ?? this.toggleFailures,
    deleteFailures: deleteFailures ?? this.deleteFailures,
  );

  @override
  List<Object?> get props => [
    alarms,
    reasons,
    alarmLimit,
    accessDenied,
    toggleFailures,
    deleteFailures,
  ];
}

class MyAlarmsFailure extends MyAlarmsState {
  final String message;

  const MyAlarmsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
