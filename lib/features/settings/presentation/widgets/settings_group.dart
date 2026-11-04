import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';

/// A rounded card holding rows split by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.cardColor,
      borderRadius: BorderRadius.circular(22.r),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColor.divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
