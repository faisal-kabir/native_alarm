import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../main.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../create_alarm/domain/entities/alarm_draft.dart';
import '../../../create_alarm/domain/entities/alarm_schedule.dart';
import '../../../create_alarm/presentation/widgets/schedule_cards.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/presentation/widgets/reason_emblem.dart';

/// One saved alarm on My Alarms (radius 28):
/// * the Reason (its area as a 40 disc and its name) and the on / off switch;
/// * the time of its next ring, large ("6:30"), with an orange "AM";
/// * "Next ring · Tomorrow" ("Today", "Tomorrow" or the day's name), or "Off · won't
///   ring" while it is switched off;
/// * the seven days (S M T W T F S): the days it repeats on orange, the day of its
///   next ring circled in white.
/// Switched off, everything under the Reason dims.
class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.reason,
    required this.now,
    required this.onEnabledChanged,
  });

  final Alarm alarm;

  /// The Reason it plays (null until the cached list has it: then the name it was
  /// saved with is shown).
  final Reason? reason;

  /// The time "next ring" is counted from.
  final DateTime now;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final on = alarm.enabled;
    final next = on ? nextRingOf(alarm, now) : alarm.time;
    final time = AlarmTime.fromMinutes(next.hour * 60 + next.minute);
    // The alarm counts days 1 = Mon .. 7 = Sun; the names count 0 = Sun.
    final days = {for (final d in alarm.repeatWeekdays) d % 7};
    final name = reason?.name ?? alarm.label ?? '';
    final today = DateTime(now.year, now.month, now.day);
    final daysAway = DateTime(
      next.year,
      next.month,
      next.day,
    ).difference(today).inDays;
    final when = switch (daysAway) {
      0 => strings.my_alarms_today,
      1 => strings.my_alarms_tomorrow,
      _ => strings.day_names.split(',')[next.weekday % 7],
    };
    final status = on
        ? strings.my_alarms_next_ring(when)
        : strings.my_alarms_off_note;

    return Semantics(
      container: true,
      label: strings.my_alarms_alarm_semantics(
        time.label,
        repeatLabel(days, repeatWordsOf(strings)),
        name,
        status,
      ),
      child: Container(
        padding: REdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: AppColor.cardColor,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  ReasonEmblem(
                    areaName: reason?.areaTitle ?? name,
                    areaColor: reason?.area?.color,
                    areaIcon: reason?.area?.icon,
                    disc: true,
                    size: 40,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  AppSwitch(value: on, onChanged: onEnabledChanged),
                ],
              ),
            ),
            ExcludeSemantics(
              child: AnimatedOpacity(
                opacity: on ? 1 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6.h),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: time.clock),
                          WidgetSpan(child: SizedBox(width: 8.w)),
                          TextSpan(
                            text: time.meridiem,
                            style: TextStyle(
                              fontSize: 22.spMin,
                              fontWeight: Dimension.textSemiBold,
                              letterSpacing: 0,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                      style: textTheme.titleLarge!.copyWith(
                        fontSize: 64.spMin,
                        height: 1.1,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                        color: AppColor.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge!.copyWith(
                        fontSize: 16.spMin,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _Days(
                      days: days,
                      next: on ? next.weekday % 7 : null,
                      letters: strings.day_letters.split(','),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The seven days as 30 circles, 7 apart: repeat days orange with black letters, the
/// others grey; the next ring's day has a white ring around it.
class _Days extends StatelessWidget {
  const _Days({required this.days, required this.next, required this.letters});

  final Set<int> days;
  final int? next;
  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    final style = appTheme(context).textTheme.labelLarge!;
    return Wrap(
      spacing: 3.w,
      runSpacing: 3.w,
      children: [
        for (var d = 0; d < 7; d++)
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: d == next
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.white, width: 2.r),
                  )
                : null,
            child: Container(
              width: 30.r,
              height: 30.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days.contains(d)
                    ? AppColor.primary
                    : AppColor.controlFill,
              ),
              child: Text(
                letters[d],
                style: style.copyWith(
                  color: days.contains(d)
                      ? AppColor.onPrimary
                      : AppColor.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
