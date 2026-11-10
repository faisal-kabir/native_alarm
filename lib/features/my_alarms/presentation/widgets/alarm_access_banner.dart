import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// "Alarm access is off / Enable Alarm Access": shown above the list while the system
/// has not granted alarm access. A card like the others (radius 20): a 36 red tile
/// with the crossed-out alarm, the two lines, a chevron. It rises in when it appears.
class AlarmAccessBanner extends StatelessWidget {
  const AlarmAccessBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final title = strings.my_alarms_access_title;
    final action = strings.create_alarm_blocked_action;
    return RiseIn(
      dy: -6,
      child: Semantics(
        button: true,
        label: '$title. $action',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: REdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColor.cardColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColor.danger.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: AppSvgIcon(
                    Assets.icons.alarmOff,
                    size: 18.r,
                    color: AppColor.danger,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium!.copyWith(
                          fontSize: 16.spMin,
                          fontWeight: Dimension.textSemiBold,
                          color: AppColor.titleColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 15.spMin,
                          letterSpacing: -0.2,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
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
    );
  }
}
