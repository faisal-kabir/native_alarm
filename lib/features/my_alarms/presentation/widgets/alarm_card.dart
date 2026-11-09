import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../create_alarm/domain/entities/alarm_draft.dart';
import '../../../create_alarm/domain/entities/alarm_schedule.dart';
import '../../../create_alarm/presentation/widgets/schedule_cards.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/presentation/widgets/reason_emblem.dart';

/// When [alarm] rings next, in the one phrase a card uses: inside a day the countdown
/// ("Next ring · in 8 hr 52 min"), past it the day ("Next ring · Wednesday"); a one-off
/// says so ("Rings Tomorrow · once"), since it has no days to draw. "Off" while it is
/// switched off, and "Won't ring · Alarm access is off" while [blocked].
String alarmRingsLabel(
  Alarm alarm,
  DateTime now,
  AppLocalizations strings, {
  bool blocked = false,
}) {
  if (blocked) return strings.my_alarms_blocked;
  if (!alarm.enabled) return strings.my_alarms_off;
  final next = nextRingOf(alarm, now);
  final until = next.difference(now);
  final String when;
  if (until < const Duration(days: 1)) {
    final minutes = (until.inSeconds / 60).round();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    when = h == 0
        ? strings.my_alarms_in_minutes(m)
        : m == 0
        ? strings.my_alarms_in_hours(h)
        : strings.my_alarms_in_hours_minutes(h, m);
  } else {
    final days = DateTime(
      next.year,
      next.month,
      next.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    when = days == 1
        ? strings.my_alarms_tomorrow
        : strings.day_names.split(',')[next.weekday % 7];
  }
  return alarm.repeatWeekdays.isEmpty
      ? strings.my_alarms_rings_once(when)
      : strings.my_alarms_next_ring(when);
}

/// One saved alarm on My Alarms, in two sizes: [hero] (the next alarm, under "Next
/// alarm") and a row (every other alarm, under "All alarms").
/// * the Reason (a 28 disc in its area's colour and its name) and the on / off switch;
/// * the time it rings next, light and large, with "AM" / "PM" (orange on the hero);
/// * when that is ([alarmRingsLabel]);
/// * the seven days (S M T W T F S): its days orange, the next ring's day ringed in
///   white; a one-off has none.
/// Switched off, the card stays solid and only its contents turn grey (the days too).
/// [blocked] (switched on, but the system has not granted alarm access) promises no
/// ring and marks no day; the switch keeps the person's choice.
class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.reason,
    required this.now,
    required this.onEnabledChanged,
    this.hero = false,
    this.blocked = false,
  });

  final Alarm alarm;

  /// The Reason it plays (null until the cached list has it: then the name it was
  /// saved with is shown).
  final Reason? reason;

  /// The time "next ring" is counted from.
  final DateTime now;
  final ValueChanged<bool> onEnabledChanged;
  final bool hero;
  final bool blocked;

  static const Duration _fade = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final on = alarm.enabled;
    final blocked = on && this.blocked;
    final next = nextRingOf(alarm, now);
    final time = AlarmTime.fromMinutes(next.hour * 60 + next.minute);
    // The alarm counts days 1 = Mon .. 7 = Sun; the names count 0 = Sun.
    final days = {for (final d in alarm.repeatWeekdays) d % 7};
    final name = reason?.name ?? alarm.label ?? '';
    final meta = alarmRingsLabel(alarm, now, strings, blocked: blocked);
    final ink = on ? AppColor.white : AppColor.textSecondary;

    return Semantics(
      container: true,
      label: strings.my_alarms_alarm_semantics(
        time.label,
        repeatLabel(days, repeatWordsOf(strings)),
        name,
        blocked ? strings.my_alarms_blocked_semantics : meta,
      ),
      child: Container(
        padding: hero
            ? REdgeInsets.fromLTRB(16, 20, 16, 18)
            : REdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.cardColor,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 31.h,
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          if (name.isNotEmpty) ...[
                            ReasonEmblem(
                              areaName: reason?.areaTitle ?? name,
                              areaColor: reason?.area?.color,
                              areaIcon: reason?.area?.icon,
                              disc: true,
                              size: 28,
                              muted: !on,
                            ),
                            SizedBox(width: 9.w),
                          ],
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: _fade,
                              style: textTheme.titleMedium!.copyWith(
                                fontSize: 15.spMin,
                                fontWeight: Dimension.textSemiBold,
                                letterSpacing: -0.2,
                                color: ink,
                              ),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  AppSwitch(
                    value: on,
                    label: strings.my_alarms_switch_semantics(time.label),
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onEnabledChanged(v);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: hero ? 12.h : 8.h),
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: _fade,
                    style: textTheme.titleLarge!.copyWith(
                      fontSize: (hero ? 56 : 44).spMin,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      letterSpacing: hero ? -2.2 : -1.6,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: ink,
                    ),
                    child: Text(time.clock),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedDefaultTextStyle(
                    duration: _fade,
                    style: textTheme.titleLarge!.copyWith(
                      fontSize: (hero ? 19 : 16).spMin,
                      height: 1,
                      fontWeight: Dimension.textSemiBold,
                      letterSpacing: 0,
                      color: hero && on
                          ? AppColor.primary
                          : AppColor.textSecondary,
                    ),
                    child: Text(time.meridiem),
                  ),
                ],
              ),
            ),
            SizedBox(height: hero ? 8.h : 5.h),
            ExcludeSemantics(
              child: Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 15.spMin,
                  height: 17.5 / 15,
                  letterSpacing: -0.2,
                  color: AppColor.textSecondary,
                ),
              ),
            ),
            if (days.isNotEmpty) ...[
              SizedBox(height: 13.h),
              ExcludeSemantics(
                child: _Days(
                  days: days,
                  small: !hero,
                  off: !on,
                  next: on && !blocked ? next.weekday % 7 : null,
                  letters: strings.day_letters.split(','),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The seven days, reporting rather than asking: a day it rings is orange with black
/// letters, the next one to ring wears a 1.5 white ring 2 off it, the rest are #2C2C2E
/// with grey letters. Switched off, its days stay marked in grey (#3A3A3C). 30 (gap 6,
/// letters 13) or [small] 27 (gap 5, 12).
class _Days extends StatelessWidget {
  const _Days({
    required this.days,
    required this.small,
    required this.off,
    required this.next,
    required this.letters,
  });

  final Set<int> days;
  final bool small;
  final bool off;
  final int? next;
  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    final size = (small ? 27 : 30).r;
    final style = appTheme(context).textTheme.labelLarge!.copyWith(
      fontSize: (small ? 12 : 13).spMin,
      height: 1.2,
      fontWeight: Dimension.textSemiBold,
      letterSpacing: 0,
    );
    return Row(
      children: [
        for (var d = 0; d < 7; d++) ...[
          if (d > 0) SizedBox(width: (small ? 5 : 6).w),
          CustomPaint(
            foregroundPainter: d == next ? const _NextRing() : null,
            child: AnimatedContainer(
              duration: AlarmCard._fade,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days.contains(d)
                    ? (off ? AppColor.slotFree : AppColor.primary)
                    : AppColor.surfaceSecondary,
              ),
              child: Text(
                letters[d],
                style: style.copyWith(
                  color: days.contains(d)
                      ? (off ? AppColor.textSecondary : AppColor.onPrimary)
                      : (off ? AppColor.textMuted : AppColor.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A 1.5 white ring, 2 outside the day.
class _NextRing extends CustomPainter {
  const _NextRing();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 1.5.r;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2 + 2.r + stroke / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColor.white,
    );
  }

  @override
  bool shouldRepaint(_NextRing old) => false;
}
