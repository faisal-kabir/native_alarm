import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../theme/app_color.dart';
import 'rise_in.dart';

/// The big heading of a step screen. Words between `*stars*` in [text] are drawn in the
/// brand colour ("What do you want to *wake up for*?"), and the heading rises in.
class HighlightedTitle extends StatelessWidget {
  const HighlightedTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final base = appTheme(context).textTheme.headlineLarge!.copyWith(
      fontSize: 28.spMin,
      height: 31.36 / 28,
      letterSpacing: -0.56,
      color: AppColor.textColor,
    );
    final parts = text.split('*');
    return RiseIn(
      delay: const Duration(milliseconds: 50),
      dy: 14,
      child: Semantics(
        header: true,
        child: Text.rich(
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
      ),
    );
  }
}
