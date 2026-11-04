import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// "▬ ▬ ▬  Up to 3 ⓘ": one pill per alarm place, gold while used, then the limit
/// and an info icon. Tapping it explains how alarms work.
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
                    color: i < used ? AppColor.primary : AppColor.slotFree,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ],
              SizedBox(width: 10.w),
              Text(
                strings.my_alarms_slot_meter_label(total),
                style: appTheme(context).textTheme.labelLarge,
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
