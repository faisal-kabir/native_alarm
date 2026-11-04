import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';

/// The warm glow at the bottom of the screen: 200 tall, drawn at 35 % opacity. The web
/// draws an ellipse; a circular gradient is a close match. Place it in a [Stack].
class Horizon extends StatelessWidget {
  const Horizon({super.key});

  static const double _opacity = 0.35;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 200.h,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.36),
              radius: 1.4,
              colors: [
                AppColor.horizonLight.withValues(alpha: 0.34 * _opacity),
                AppColor.horizonMid.withValues(alpha: 0.18 * _opacity),
                AppColor.horizonDark.withValues(alpha: 0.10 * _opacity),
                AppColor.transparent,
              ],
              stops: const [0, 0.26, 0.46, 0.72],
            ),
          ),
        ),
      ),
    );
  }
}
