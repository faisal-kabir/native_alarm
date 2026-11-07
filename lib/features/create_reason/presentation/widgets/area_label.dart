import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/cached_svg_icon.dart';
import '../../../../core/widgets/suggestion_list.dart';

/// An area of life as a small spaced-capitals label ("HEALTH"), with its icon in front
/// when [icon] is given, in the area's tint mixed into white. Used above a reason's
/// text (purpose step, the reason card).
class AreaLabel extends StatelessWidget {
  const AreaLabel({super.key, required this.title, this.color, this.icon});

  final String title;

  /// The area's ARGB tint from the server (brand colour when null).
  final int? color;

  /// The area icon's server path; no icon when null.
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(AppColor.white, AppColor.tintOf(color), 0.7)!;
    final icon = this.icon;
    final label = SuggestionLabel(title, color: ink);
    if (icon == null) return label;
    return SizedBox(
      height: 16.h,
      child: Row(
        children: [
          CachedSvgIcon(
            path: icon,
            size: 16.r,
            color: ink,
            fallback: const SizedBox.shrink(),
          ),
          SizedBox(width: 8.w),
          Flexible(child: label),
        ],
      ),
    );
  }
}
