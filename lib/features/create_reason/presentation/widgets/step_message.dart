import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../main.dart';

/// A centred note under a step's heading (nothing loaded, offline), with an optional
/// text button ("Try again"). Shared by the Create Reason steps.
class StepMessage extends StatelessWidget {
  const StepMessage({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(text, textAlign: TextAlign.center, style: textTheme.bodySmall),
          if (actionLabel != null) ...[
            SizedBox(height: 16.h),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: REdgeInsets.all(8),
                child: Text(
                  actionLabel!,
                  style: textTheme.labelLarge!.copyWith(
                    color: AppColor.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
