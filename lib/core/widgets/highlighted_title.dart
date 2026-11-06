import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../theme/app_color.dart';
import 'rise_in.dart';

/// The big heading of a step screen. Words between `*stars*` in [text] are drawn in the
/// brand colour ("What do you want to *wake up for*?"), and the heading rises in.
class HighlightedTitle extends StatelessWidget {
  const HighlightedTitle(
    this.text, {
    super.key,
    this.fontSize = 28,
    this.textAlign = TextAlign.start,
    this.animate = true,
  });

  final String text;

  final TextAlign textAlign;

  /// False when the caller runs its own entrance (the ready screen's timeline).
  final bool animate;

  /// 28 on list steps, 32 on text steps. Line height 1.12, tracking -0.02 em.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final base = appTheme(context).textTheme.headlineLarge!.copyWith(
      fontSize: fontSize.spMin,
      height: 1.12,
      letterSpacing: -0.02 * fontSize,
      color: AppColor.textColor,
    );
    final parts = text.split('*');
    final title = Semantics(
      header: true,
      child: Text.rich(
        textAlign: textAlign,
        TextSpan(
          style: base,
          children: [
            for (var i = 0; i < parts.length; i++)
              if (parts[i].isNotEmpty)
                TextSpan(
                  text: parts[i],
                  style: i.isOdd
                      ? const TextStyle(color: AppColor.primary)
                      : null,
                ),
          ],
        ),
      ),
    );
    if (!animate) return title;
    return RiseIn(
      delay: const Duration(milliseconds: 50),
      dy: 14,
      child: title,
    );
  }
}
