// The logic of "When it rings" in the alarm editor, with no widgets (a port of the
// web's schedule.js and repeatLabel, so the app and the design agree on every case).
//
// A simple alarm is one time on some days. "6:30 on weekdays, 8:00 at the weekend"
// gains `byDay`: a time for each day it rings. The editor shows that as CARDS, each a
// time and its days:
//   * one card is the plain alarm;
//   * "Add another time" makes a card for the days that have none; with every day
//     taken it splits the weekend off the week. It starts at the last card's time;
//   * a day belongs to at most one card: tapping it puts it in THIS card (leaving the
//     card that had it), tapping it in its own card turns it off;
//   * with two or more cards, a card whose last day leaves goes with it;
//   * days in no card do not ring; no days at all is a one-off alarm ("Once").
// While `byDay` exists, `days` and the top-level time mirror it. [finalize] turns a list
// whose days all share one time back into a simple alarm.

import '../../../alarm/domain/entities/alarm.dart';
import 'alarm_draft.dart';

const _allDays = [0, 1, 2, 3, 4, 5, 6];
int _mondayFirst(int d) => (d + 6) % 7;
List<int> _sorted(Iterable<int> days) => [...days]..sort();

/// An alarm as cards (ids from [newId]): weekdays before the weekend, as a week reads.
List<ScheduleCard> groupDays(AlarmDraft alarm, String Function() newId) {
  final byDay = alarm.byDay;
  if (byDay == null) {
    return [
      ScheduleCard(id: newId(), time: alarm.time, days: _sorted(alarm.days)),
    ];
  }
  final groups = <AlarmTime, List<int>>{};
  for (final d in _sorted(byDay.keys)) {
    groups.putIfAbsent(byDay[d]!, () => []).add(d);
  }
  if (groups.isEmpty) {
    return [ScheduleCard(id: newId(), time: alarm.time, days: const [])];
  }
  final list = [
    for (final e in groups.entries)
      ScheduleCard(id: newId(), time: e.key, days: e.value),
  ];
  int first(ScheduleCard c) =>
      c.days.map(_mondayFirst).reduce((a, b) => a < b ? a : b);
  list.sort((a, b) => first(a).compareTo(first(b)));
  return list;
}

/// The draft that [cards] describe. One card is a plain alarm; more are a `byDay` list.
AlarmDraft fromCards(AlarmDraft draft, List<ScheduleCard> cards) {
  if (cards.isEmpty) {
    return draft.withSchedule(time: draft.time, days: const []);
  }
  if (cards.length == 1) {
    return draft.withSchedule(
      time: cards[0].time,
      days: _sorted(cards[0].days),
    );
  }
  final byDay = <int, AlarmTime>{
    for (final c in cards)
      for (final d in c.days) d: c.time,
  };
  final days = _sorted(byDay.keys);
  return draft.withSchedule(
    time: days.isEmpty ? draft.time : byDay[days.first]!,
    days: days,
    byDay: byDay,
  );
}

/// Back to one time: the one most days already have (the earliest day wins a tie).
AlarmDraft collapse(AlarmDraft draft) {
  final byDay = draft.byDay;
  if (byDay == null) return draft;
  final days = _sorted(byDay.keys);
  if (days.isEmpty) return draft.withSchedule(time: draft.time, days: const []);
  final count = <AlarmTime, int>{};
  for (final d in days) {
    count[byDay[d]!] = (count[byDay[d]!] ?? 0) + 1;
  }
  var best = byDay[days.first]!;
  for (final d in days) {
    final t = byDay[d]!;
    if (count[t]! > count[best]!) best = t;
  }
  return draft.withSchedule(time: best, days: days);
}

/// On save: a list whose days all have the same time, or none, is a simple alarm.
AlarmDraft finalize(AlarmDraft draft) {
  final byDay = draft.byDay;
  if (byDay == null) return draft;
  return byDay.values.toSet().length <= 1 ? collapse(draft) : draft;
}

/// Days no card has: they do not ring.
List<int> freeDays(List<ScheduleCard> cards) => [
  for (final d in _allDays)
    if (!cards.any((c) => c.days.contains(d))) d,
];

/// Whether "Add another time" has somewhere to put a new card.
bool canAddCard(List<ScheduleCard> cards) =>
    freeDays(cards).isNotEmpty ||
    (cards.length == 1 && cards[0].days.length == 7);

/// A new card for the days with no time yet; with every day taken, the weekend is
/// split off the week. It starts at the last card's time.
List<ScheduleCard> addCard(List<ScheduleCard> cards, String id) {
  if (!canAddCard(cards)) return cards;
  final last = cards.last;
  final free = freeDays(cards);
  if (free.isNotEmpty) {
    return [...cards, ScheduleCard(id: id, time: last.time, days: free)];
  }
  const weekend = [0, 6];
  return [
    ...cards.sublist(0, cards.length - 1),
    last.copyWith(
      days: [
        for (final d in last.days)
          if (!weekend.contains(d)) d,
      ],
    ),
    ScheduleCard(id: id, time: last.time, days: weekend),
  ];
}

/// Tap a day in a card: it joins that card (leaving whichever had it), or, if it was
/// already there, goes off. With several cards, one left with no day is dropped.
List<ScheduleCard> toggleCardDay(List<ScheduleCard> cards, String id, int day) {
  ScheduleCard? owner;
  for (final c in cards) {
    if (c.days.contains(day)) owner = c;
  }
  List<int> without(ScheduleCard c) => [
    for (final d in c.days)
      if (d != day) d,
  ];
  final next = [
    for (final c in cards)
      if (c.id == id)
        c.copyWith(
          days: owner?.id == id ? without(c) : _sorted([...c.days, day]),
        )
      else if (c.id == owner?.id)
        c.copyWith(days: without(c))
      else
        c,
  ];
  if (next.length <= 1) return next;
  return [
    for (final c in next)
      if (c.days.isNotEmpty) c,
  ];
}

/// Change one card's time.
List<ScheduleCard> setCardTime(
  List<ScheduleCard> cards,
  String id,
  AlarmTime time,
) => [for (final c in cards) c.id == id ? c.copyWith(time: time) : c];

/// When [draft] rings next after [now]: the soonest of its days at their times, or
/// (no days) today at its time, else tomorrow.
DateTime nextRing(AlarmDraft draft, DateTime now) {
  DateTime at(DateTime day, AlarmTime t) => DateTime(
    day.year,
    day.month,
    day.day,
    t.minutesOfDay ~/ 60,
    t.minutesOfDay % 60,
  );
  final today = DateTime(now.year, now.month, now.day);
  if (draft.days.isEmpty) {
    final ring = at(today, draft.time);
    return ring.isAfter(now)
        ? ring
        : at(today.add(const Duration(days: 1)), draft.time);
  }
  DateTime? best;
  // Today counts only if its time is still ahead; a week on, it always is.
  for (var offset = 0; offset <= 7; offset++) {
    final day = today.add(Duration(days: offset));
    final d = day.weekday % 7; // DateTime: Mon = 1 .. Sun = 7 -> Sun = 0
    if (!draft.days.contains(d)) continue;
    final ring = at(day, draft.byDay?[d] ?? draft.time);
    if (ring.isAfter(now) && (best == null || ring.isBefore(best))) best = ring;
  }
  return best!;
}

/// An editor day (0 = Sun .. 6 = Sat) as the alarm counts it (1 = Mon .. 7 = Sun).
int alarmWeekday(int day) => day == 0 ? 7 : day;

/// The saved alarm the editor's [draft] makes (finalized first: equal times are a
/// simple alarm): days 1 = Mon .. 7 = Sun, `dayTimes` in minutes after midnight per
/// day, its next ring after [now], [title] (the Reason's name) as its label. [id],
/// [audioTrackId] and [remoteId] are the caller's (a new alarm's or the one edited).
Alarm alarmFromDraft(
  AlarmDraft draft, {
  required String id,
  required String title,
  required DateTime now,
  required String audioTrackId,
  int? remoteId,
}) {
  final d = finalize(draft);
  return Alarm(
    id: id,
    enabled: d.enabled,
    time: nextRing(d, now),
    repeatWeekdays: [for (final day in d.days) alarmWeekday(day)]..sort(),
    audioTrackId: audioTrackId,
    ringtoneId: d.alarmSoundId?.toString() ?? 'default',
    label: title,
    missionName: title,
    reasonId: d.reasonId,
    soundTrackId: d.soundTrackId,
    alarmSoundId: d.alarmSoundId,
    ringAgain: d.again,
    dayTimes: d.byDay?.map(
      (day, time) => MapEntry(alarmWeekday(day), time.minutesOfDay),
    ),
    remoteId: remoteId,
  );
}

/// A saved [alarm] as the editor opens it: its schedule ([alarmDraftOf]) and every
/// other choice (Reason, sounds, ring again, on / off).
AlarmDraft editorDraftOf(Alarm alarm) {
  final schedule = alarmDraftOf(alarm);
  return AlarmDraft(
    time: schedule.time,
    days: schedule.days,
    byDay: schedule.byDay,
    reasonId: alarm.reasonId,
    soundTrackId: alarm.soundTrackId,
    alarmSoundId: alarm.alarmSoundId,
    again: alarm.ringAgain,
    enabled: alarm.enabled,
  );
}

/// A saved [alarm]'s schedule as the editor's draft (time, days, a time per day).
AlarmDraft alarmDraftOf(Alarm alarm) {
  AlarmTime at(int minutes) => AlarmTime.fromMinutes(minutes);
  final dayTimes = alarm.dayTimes;
  return AlarmDraft(
    time: at(alarm.time.hour * 60 + alarm.time.minute),
    // The alarm counts 1 = Mon .. 7 = Sun, the editor 0 = Sun .. 6 = Sat.
    days: [for (final d in alarm.repeatWeekdays) d % 7],
    byDay: dayTimes == null
        ? null
        : {for (final e in dayTimes.entries) e.key % 7: at(e.value)},
  );
}

/// When a saved [alarm] rings next after [now], by the same rule as [nextRing].
DateTime nextRingOf(Alarm alarm, DateTime now) =>
    nextRing(alarmDraftOf(alarm), now);

// ------------------------------------------------------------ naming the days

/// The words [repeatLabel] uses (from the app's strings).
class RepeatWords {
  const RepeatWords({
    required this.once,
    required this.everyDay,
    required this.weekdays,
    required this.weekends,
    required this.everySingle,
    required this.everyExcept,
    required this.dayShort,
  });

  final String once;
  final String everyDay;
  final String weekdays;
  final String weekends;

  /// "Every Mon" for one day (gets the short name).
  final String Function(String day) everySingle;

  /// "Every day except Mon Wed" (gets the missing days, space-separated).
  final String Function(String days) everyExcept;

  /// Sun .. Sat.
  final List<String> dayShort;
}

/// What a set of days is called, in as few words as it can be said in: no days is
/// "Once" (it does ring, once); a run of three or more is a range ("Mon–Sat", wrap
/// counts); a set with few gaps names the gaps; anything else is listed. The shortest
/// wins and the list breaks ties.
String repeatLabel(Iterable<int> days, RepeatWords w) {
  if (days.isEmpty) return w.once;
  final sorted = _sorted(days);
  if (sorted.length == 7) return w.everyDay;
  final joined = sorted.join(',');
  if (joined == '1,2,3,4,5') return w.weekdays;
  if (joined == '0,6') return w.weekends;
  if (sorted.length == 1) return w.everySingle(w.dayShort[sorted[0]]);

  final candidates = <String>[];
  final start = _runStart(sorted);
  if (start != -1 && sorted.length >= 3) {
    candidates.add(
      '${w.dayShort[start]}–${w.dayShort[(start + sorted.length - 1) % 7]}',
    );
  }
  final missing = [
    for (final d in _allDays)
      if (!sorted.contains(d)) d,
  ];
  if (missing.isNotEmpty && missing.length < sorted.length - 1) {
    candidates.add(w.everyExcept(missing.map((d) => w.dayShort[d]).join(' ')));
  }
  candidates.add(sorted.map((d) => w.dayShort[d]).join(' '));
  return candidates.reduce((best, c) => c.length < best.length ? c : best);
}

int _runStart(List<int> sorted) {
  final set = sorted.toSet();
  for (final start in sorted) {
    var run = true;
    for (var i = 0; i < sorted.length; i++) {
      if (!set.contains((start + i) % 7)) {
        run = false;
        break;
      }
    }
    if (run) return start;
  }
  return -1;
}
