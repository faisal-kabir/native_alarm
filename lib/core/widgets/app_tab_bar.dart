import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../constants/app_constant.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// One tab of [AppTabBar].
class AppTabItem {
  const AppTabItem({required this.label, required this.icon});

  final String label;
  final SvgGenImage icon;
}

/// The floating glass tab bar: a 70-tall pill, 24 from each side and 16 above the
/// bottom safe area. Tabs share the width; the active one sits on a "lens" pill.
/// Use it as `Scaffold.bottomNavigationBar` with `extendBody: true`.
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
    final pill = BorderRadius.circular(AppConstant.pillRadius.r);
    return SafeArea(
      top: false,
      child: Padding(
        padding: REdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ClipRRect(
          borderRadius: pill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 70.h,
              padding: REdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: pill,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColor.tabBarGlossTop, AppColor.tabBarGlossBottom],
                ),
                color: AppColor.tabBarFill,
                border: Border.all(color: AppColor.tabBarBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _Tab(
                        item: items[i],
                        active: i == selectedIndex,
                        onTap: () => onSelected?.call(i),
                      ),
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

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final AppTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColor.primary : AppColor.tabIdle;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // expand: the lens is positioned against the full tab height, not the label's.
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (active)
              Positioned(
                left: 2.w,
                right: 2.w,
                top: 6.h,
                bottom: 6.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppConstant.pillRadius.r,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColor.tabLensTop, AppColor.tabLensBottom],
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(item.icon, size: 23.r, color: color),
                  SizedBox(height: 2.h),
                  Text(
                    item.label,
                    style: appTheme(context).textTheme.labelSmall!
                        .copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
