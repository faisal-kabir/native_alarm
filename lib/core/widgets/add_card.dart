import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// The empty-state "add" card shared by list screens (Alarms, Reasons): a dark card
/// with a gold round plus, a title and a short line under it. The whole card is
/// the button.
class AddCard extends StatelessWidget {
  const AddCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: Material(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: REdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    Assets.icons.plus,
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
        ),
      ),
    );
  }
}
