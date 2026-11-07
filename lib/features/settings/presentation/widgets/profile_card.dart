import 'package:flutter/material.dart';

import '../../../../core/utils/text_utils.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// The account card: a 78-tall card (radius 22), a 46 avatar with the name's initial
/// (or "?" while no name is set), the name, a subtitle line and a chevron.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.onTap,
  });

  /// Empty while the user has not set one.
  final String name;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final trimmed = name.trim();
    final title = trimmed.isEmpty ? strings.settings_set_your_name : trimmed;
    final initial = trimmed.isEmpty ? '?' : initialOf(trimmed);
    return Semantics(
      button: true,
      label: strings.settings_profile_semantics(title, subtitle),
      excludeSemantics: true,
      child: Material(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(22.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 78.h),
            child: Padding(
              padding: REdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46.r,
                    height: 46.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Text(
                      initial,
                      style: textTheme.headlineMedium!.copyWith(
                        fontSize: 19.spMin,
                        color: AppColor.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),
                  AppSvgIcon(
                    Assets.icons.page.chevron,
                    size: 17.r,
                    color: AppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
