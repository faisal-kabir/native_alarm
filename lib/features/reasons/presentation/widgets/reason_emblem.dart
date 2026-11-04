import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// Whether an alarm plays a reason: none = no badge, on = orange, off = grey.
enum ReasonAlarmBadge { none, on, off }

/// The area mark: a 46 rounded square (radius 15) in the area's tint at 15 %, showing
/// the first letter of the area's name in the full tint. [areaColor] is the server's
/// ARGB tint (the brand colour when it sent none). [badge] adds the alarm mark
/// (22 + 2.5 black ring) hanging off the lower-right corner.
class ReasonEmblem extends StatelessWidget {
  const ReasonEmblem({
    super.key,
    required this.areaName,
    this.areaColor,
    this.badge = ReasonAlarmBadge.none,
  });

  final String areaName;
  final int? areaColor;
  final ReasonAlarmBadge badge;

  @override
  Widget build(BuildContext context) {
    final tint = areaColor == null ? AppColor.primary : Color(areaColor!);
    final trimmed = areaName.trim();
    final initial = trimmed.isEmpty
        ? ''
        : trimmed.characters.first.toUpperCase();
    return SizedBox(
      width: 46.r,
      height: 46.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Text(
              initial,
              style: appTheme(context).textTheme.headlineMedium!
                  .copyWith(fontSize: 21.spMin, color: tint),
            ),
          ),
          if (badge != ReasonAlarmBadge.none)
            Positioned(
              right: -7.8.r,
              bottom: -7.8.r,
              child: _AlarmBadgeMark(on: badge == ReasonAlarmBadge.on),
            ),
        ],
      ),
    );
  }
}

class _AlarmBadgeMark extends StatelessWidget {
  const _AlarmBadgeMark({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27.r, // 22 + 2 x 2.5 ring
      height: 27.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColor.primary : AppColor.badgeOff,
        border: Border.all(color: AppColor.backgroundColor, width: 2.5.r),
      ),
      child: AppSvgIcon(
        on ? Assets.icons.alarm : Assets.icons.page.alarmOffBadge,
        size: 15.r,
        color: on ? AppColor.onPrimary : AppColor.textSecondary,
      ),
    );
  }
}
