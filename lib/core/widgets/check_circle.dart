import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';
import 'sliding_border.dart';

/// The round "chosen" mark of a choice card: an empty ring, or filled orange with a
/// black check that springs in (a small overshoot) when [on] turns true. It goes at
/// once when [on] turns false. With reduced motion the check just appears.
class CheckCircle extends StatefulWidget {
  const CheckCircle({
    super.key,
    required this.on,
    this.size = 28,
    this.iconSize = 15,
  });

  final bool on;

  /// Circle and check sizes before scaling (`.r` is applied here).
  final double size;
  final double iconSize;

  @override
  State<CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<CheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _check = AnimationController.unbounded(
    vsync: this,
    value: widget.on ? 1 : 0,
  );

  @override
  void didUpdateWidget(CheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on && !oldWidget.on) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _check.value = 1;
      } else {
        _check
          ..value = 0
          ..animateWith(SpringSimulation(SelectionMotion.checkSpring, 0, 1, 0));
      }
    } else if (!widget.on && oldWidget.on) {
      _check.value = 0;
    }
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
      width: widget.size.r,
      height: widget.size.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColor.primary : AppColor.primary.withValues(alpha: 0),
        border: Border.all(
          color: on
              ? AppColor.selectRing.withValues(alpha: 0)
              : AppColor.selectRing,
          width: 1.5.r,
        ),
      ),
      child: on
          ? AnimatedBuilder(
              animation: _check,
              builder: (_, child) => Transform.scale(
                scale: _check.value.clamp(0.0, 2.0),
                child: child,
              ),
              child: AppSvgIcon(
                Assets.icons.check,
                size: widget.iconSize.r,
                color: AppColor.onPrimary,
              ),
            )
          : null,
    );
  }
}
