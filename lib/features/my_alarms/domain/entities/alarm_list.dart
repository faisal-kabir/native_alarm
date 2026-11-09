import '../../../alarm/domain/entities/alarm.dart';
import '../../../create_alarm/domain/entities/alarm_schedule.dart';

/// How the Alarms tab lays out [alarms] at [now]: [next] is the switched-on alarm that
/// rings first (the large card under "Next alarm"; null when none is on), [rest] every
/// other alarm by the time of day it rings next (not by date), alarms at the same time
/// keeping the order they came in.
({Alarm? next, List<Alarm> rest}) arrangeAlarms(
  List<Alarm> alarms,
  DateTime now,
) {
  Alarm? next;
  DateTime? first;
  for (final a in alarms) {
    if (!a.enabled) continue;
    final ring = nextRingOf(a, now);
    if (first == null || ring.isBefore(first)) {
      next = a;
      first = ring;
    }
  }
  int minutes(Alarm a) {
    final t = nextRingOf(a, now);
    return t.hour * 60 + t.minute;
  }

  final rest = [
    for (final a in alarms)
      if (a.id != next?.id) a,
  ];
  final order = {for (var i = 0; i < rest.length; i++) rest[i].id: i};
  rest.sort((a, b) {
    final byTime = minutes(a).compareTo(minutes(b));
    return byTime != 0 ? byTime : order[a.id]!.compareTo(order[b.id]!);
  });
  return (next: next, rest: rest);
}
