import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../theme/app_color.dart';
import '../theme/dimension.dart';

/// The quiet text-only action under a [PillButton] ("Save for later", "Cancel"): 44 tall,
/// full width, grey medium text, no fill.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: 44.h,
          alignment: Alignment.center,
          child: Text(
            label,
            style: appTheme(context).textTheme.bodyLarge!.copyWith(
              fontSize: 15.5.spMin,
              fontWeight: Dimension.textMedium,
              letterSpacing: 0,
              color: AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
