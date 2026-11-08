import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../constants/app_constant.dart';
import '../theme/app_color.dart';

/// The main button at the bottom of a screen: a 58-tall pill, orange with black text
/// when [enabled], dark grey with faded text when not. [quiet] is the low-key enabled
/// look (dark grey with white text, e.g. "Skip for now"). It shrinks to 98 % while
/// pressed.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.enabled,
    this.quiet = false,
    this.disabledColor = AppColor.cardColor,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool quiet;

  /// The fill while not [enabled] (and of [quiet]); `AppColor.slotFree` inside a
  /// sheet, whose own fill is the card colour.
  final Color disabledColor;
  final VoidCallback? onPressed;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _down = false;

  void _set(bool value) {
    if (widget.enabled && _down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return Semantics(
      button: true,
      enabled: on,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: on ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 58.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on && !widget.quiet
                  ? AppColor.primary
                  : widget.disabledColor,
              borderRadius: BorderRadius.circular(AppConstant.pillRadius),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: appTheme(context).textTheme.titleMedium!.copyWith(
                color: !on
                    ? AppColor.textMuted
                    : widget.quiet
                    ? AppColor.textColor
                    : AppColor.onPrimary,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
