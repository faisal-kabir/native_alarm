import 'package:equatable/equatable.dart';

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
  /// How many alarms exist (fills that many meter pills).
  final int alarmCount;

  /// How many alarms are allowed.
  final int alarmLimit;

  const MyAlarmsLoaded({required this.alarmCount, required this.alarmLimit});

  @override
  List<Object?> get props => [alarmCount, alarmLimit];
}

class MyAlarmsFailure extends MyAlarmsState {
  final String message;

  const MyAlarmsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
