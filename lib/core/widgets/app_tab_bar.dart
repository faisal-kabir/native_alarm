import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// One tab of [AppTabBar].
class AppTabItem {
  const AppTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;

  /// Outline icon of an unselected tab.
  final SvgGenImage icon;

  /// Solid icon of the selected tab.
  final SvgGenImage activeIcon;
}

/// The floating iOS 26 "liquid glass" bottom tab bar: a frosted glass pill that
/// refracts what is behind it, with a glass lens under the selected tab. When the
/// selection changes the lens slides to the new tab; it keeps its size (no jelly
/// stretch or magnified icon).
///
/// Must sit inside a `GlassScaffold` (as `bottomBar`) so the glass has a layer to
/// draw on. The package is set up once in `main()` (`LiquidGlassWidgets`).
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<AppTabItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final labelStyle = appTheme(context).textTheme.labelSmall!;
    return GlassTabBar.bottom(
      tabs: [
        for (final item in items)
          GlassTab(
            label: item.label,
            semanticLabel: item.label,
            icon: AppSvgIcon(item.icon, size: 23.r, color: AppColor.tabIdle),
            activeIcon: AppSvgIcon(
              item.activeIcon,
              size: 23.r,
              color: AppColor.primary,
            ),
          ),
      ],
      selectedIndex: selectedIndex,
      onTabSelected: (index) => onSelected?.call(index),
      horizontalPadding: 24.w,
      verticalPadding: 16.h,
      barHeight: 70.h,
      iconSize: 23.r,
      labelFontSize: 10.5.spMin,
      selectedIconColor: AppColor.primary,
      unselectedIconColor: AppColor.tabIdle,
      selectedLabelColor: AppColor.primary,
      unselectedLabelColor: AppColor.tabIdle,
      selectedLabelStyle: labelStyle.copyWith(color: AppColor.primary),
      unselectedLabelStyle: labelStyle,
      // The lens slides to the selected tab but nothing grows: no magnified icon, no
      // jelly expansion of the lens, no swelling of the bar when it is pressed.
      magnification: 1.0,
      indicatorExpansion: EdgeInsets.zero,
      pressScale: 1.0,
      indicatorColor: AppColor.tabLensTop,
      // Dark, mostly clear glass: on a black screen the pill must not turn grey.
      settings: const LiquidGlassSettings(
        glassColor: AppColor.glassTint,
        thickness: 24,
        blur: 2,
        lightIntensity: 0.55,
        saturation: 1.2,
      ),
    );
  }
}
