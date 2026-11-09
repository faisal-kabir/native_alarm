import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// "▬ ▬ ▬  Up to 3 ⓘ": one pill per alarm place, then the limit; once there is an
/// alarm, the used places are white and it reads "1 of 3"; full, a check and white
/// "3 of 3" (a finished state, not a refusal); then an info icon. Tapping it explains
/// the limit.
class SlotMeter extends StatelessWidget {
  const SlotMeter({
    super.key,
    required this.used,
    required this.total,
    this.onTap,
  });

  final int used;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final full = used >= total;
    return Semantics(
      button: true,
      label: strings.my_alarms_slot_meter_semantics(total),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 44.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) SizedBox(width: 5.w),
                Container(
                  width: 14.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: i < used ? AppColor.white : AppColor.slotFree,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ],
              SizedBox(width: 10.w),
              if (full) ...[
                AppSvgIcon(
                  Assets.icons.check,
                  size: 13.r,
                  color: AppColor.white,
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                used == 0
                    ? strings.my_alarms_slot_meter_label(total)
                    : strings.my_alarms_slot_meter_used(used, total),
                style: appTheme(context).textTheme.labelLarge!
                    .copyWith(color: full ? AppColor.white : null),
              ),
              SizedBox(width: 5.w),
              AppSvgIcon(
                Assets.icons.info,
                size: 15.r,
                color: AppColor.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
