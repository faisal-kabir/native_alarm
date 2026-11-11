import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../domain/entities/reason.dart';
import 'reason_emblem.dart';

/// A goal as a row: a card at least 78 tall (radius 14), 16 padding, the voice's 46 face,
/// two text lines (the name, then "Voice · Tone") and a chevron. Tapping opens the reason; it does not play it.
class ReasonRow extends StatelessWidget {
  const ReasonRow({
    super.key,
    required this.reason,
    this.badge = ReasonAlarmBadge.none,
    this.onTap,
  });

  final Reason reason;
  final ReasonAlarmBadge badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final voice = reason.voice?.name ?? '';
    final tone = reason.toneTitle;
    final note = switch (badge) {
      ReasonAlarmBadge.none => '',
      ReasonAlarmBadge.on => strings.reason_alarm_on_note,
      ReasonAlarmBadge.off => strings.reason_alarm_off_note,
    };
    return Semantics(
      button: true,
      label: strings.reason_row_semantics(reason.name, voice, tone, note),
      excludeSemantics: true,
      child: Material(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // At least 78 tall, but grows with the text when the user enlarges it.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 78.h),
            child: Padding(
              padding: REdgeInsets.all(16),
              child: Row(
                children: [
                  ReasonEmblem(
                    voice: reason.voice,
                    name: reason.name,
                    badge: badge,
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          strings.reason_row_subtitle(voice, tone),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 13.w),
                  AppSvgIcon(
                    Assets.icons.page.chevron,
                    size: 16.r,
                    color: AppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
