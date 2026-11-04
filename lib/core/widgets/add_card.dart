import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// The one way to add something, on every list (Alarms, Reasons).
///
/// [first] true (the list is empty): a big card with a gold round plus, [title] and
/// [subtitle]. [first] false (there are items above): a quiet 58-tall row with a
/// small gold plus tile and [label]. The whole card is the button.
class AddCard extends StatelessWidget {
  const AddCard({
    super.key,
    required this.first,
    required this.title,
    required this.subtitle,
    required this.label,
    this.onTap,
  });

  final bool first;

  /// Empty-state headline.
  final String title;

  /// Empty-state second line.
  final String subtitle;

  /// Row label when the list is not empty.
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: first ? title : label,
      excludeSemantics: true,
      child: Material(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: first ? _empty(context) : _row(context),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 158.h),
      child: Padding(
        padding: REdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54.r,
              height: 54.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primary,
              ),
              child: AppSvgIcon(
                Assets.icons.page.plus,
                size: 26.r,
                color: AppColor.onPrimary,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            SizedBox(height: 10.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context) {
    return SizedBox(
      height: 58.h,
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppSvgIcon(
                Assets.icons.page.plus,
                size: 20.r,
                color: AppColor.primary,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appTheme(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
