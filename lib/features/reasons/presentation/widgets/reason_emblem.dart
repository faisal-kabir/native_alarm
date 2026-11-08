import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/cached_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// Whether an alarm plays a reason: none = no badge, on = orange, off = grey.
enum ReasonAlarmBadge { none, on, off }

/// The area mark: a 46 rounded square (radius 15) in the area's tint at 15 %, showing
/// the area's icon ([areaIcon], its server path) in the full tint, or the first letter
/// of its name when it has none or it can not be loaded. [areaColor] is the server's
/// ARGB tint (the brand colour when it sent none). [badge] adds the alarm mark
/// (22 + 2.5 black ring) hanging off the lower-right corner.
///
/// [disc] is the reason screen's header look: a 46 circle (the tint at 22 % over the
/// card) with the icon in the tint mixed into white.
class ReasonEmblem extends StatelessWidget {
  const ReasonEmblem({
    super.key,
    required this.areaName,
    this.areaColor,
    this.areaIcon,
    this.badge = ReasonAlarmBadge.none,
    this.disc = false,
  });

  final String areaName;
  final int? areaColor;
  final String? areaIcon;
  final ReasonAlarmBadge badge;
  final bool disc;

  @override
  Widget build(BuildContext context) {
    final tint = AppColor.tintOf(areaColor);
    final ink = disc ? Color.lerp(AppColor.white, tint, 0.85)! : tint;
    final letter = Text(
      initialOf(areaName),
      style: appTheme(context).textTheme.headlineMedium!
          .copyWith(fontSize: (disc ? 19 : 21).spMin, color: ink),
    );
    final icon = areaIcon;
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
            decoration: disc
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                      tint.withValues(alpha: 0.22),
                      AppColor.cardColor,
                    ),
                  )
                : BoxDecoration(
                    color: tint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
            child: icon == null || icon.isEmpty
                ? letter
                : CachedSvgIcon(
                    path: icon,
                    size: (disc ? 21 : 22).r,
                    color: ink,
                    fallback: Center(child: letter),
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
