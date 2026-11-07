import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// One row of a [SettingsGroup]: icon, label, then an optional value, trailing widget
/// (a switch) and chevron. At least 52 tall; grows with the text.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.chevron = false,
    this.danger = false,
    this.onTap,
  });

  final SvgGenImage icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool chevron;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    // Row text is the 17 role without its bold weight.
    final rowText = textTheme.titleMedium!.copyWith(
      fontWeight: Dimension.textRegular,
    );
    final maxValueWidth = (1.sw - 48.w) * 0.58;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: 52.h),
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AppSvgIcon(
              icon,
              size: 22.r,
              color: danger ? AppColor.danger : AppColor.textSecondary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: danger
                    ? rowText.copyWith(
                        fontWeight: Dimension.textSemiBold,
                        color: AppColor.danger,
                      )
                    : rowText.copyWith(color: AppColor.titleColor),
              ),
            ),
            if (value != null) ...[
              SizedBox(width: 12.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxValueWidth),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: rowText.copyWith(color: AppColor.textSecondary),
                ),
              ),
            ],
            if (trailing != null) ...[SizedBox(width: 12.w), trailing!],
            if (chevron) ...[
              SizedBox(width: 12.w),
              AppSvgIcon(
                Assets.icons.page.chevron,
                size: 19.r,
                color: AppColor.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
    // A row with a switch is not a button: the switch is the control.
    if (onTap == null && trailing != null) {
      return MergeSemantics(child: content);
    }
    return InkWell(onTap: onTap, child: content);
  }
}
