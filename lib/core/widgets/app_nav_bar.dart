import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../theme/app_color.dart';
import 'back_chevron.dart';

/// A pushed screen's top bar: "‹ [backLabel]" on the left (orange), the [title] centred
/// (17, semibold) and an optional [trailing] widget on the right, 50 tall.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final tap = textTheme.bodyLarge!.copyWith(
      fontSize: 17.spMin,
      letterSpacing: 0,
      color: AppColor.primary,
    );
    return SizedBox(
      height: 50.h,
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Under the buttons, so it never takes a tap from them.
            IgnorePointer(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium!.copyWith(
                  fontSize: 17.spMin,
                  letterSpacing: 0,
                  color: AppColor.textColor,
                ),
              ),
            ),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: strings.common_back,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBack,
                    child: SizedBox(
                      height: 44.h,
                      child: Padding(
                        padding: REdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BackChevron(size: 21.r, color: AppColor.primary),
                            SizedBox(width: 3.w),
                            Text(backLabel, style: tap),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ?trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
