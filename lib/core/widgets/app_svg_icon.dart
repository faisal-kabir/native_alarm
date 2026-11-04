import 'package:flutter/material.dart';

import '../../gen/assets.gen.dart';

/// A square SVG icon from `Assets.icons`, tinted with [color]. The SVG files are
/// drawn in white, so any colour can be applied.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(this.icon, {super.key, required this.size, this.color});

  final SvgGenImage icon;

  /// Width and height, already scaled by the caller (e.g. `23.r`).
  final double size;

  /// Defaults to the theme's icon colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color;
    return icon.svg(
      width: size,
      height: size,
      excludeFromSemantics: true,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
