import 'package:flutter/material.dart';

import '../../gen/assets.gen.dart';
import 'app_svg_icon.dart';

/// The back arrow of every top bar: the forward chevron turned round. [size] is
/// already scaled by the caller (e.g. `22.r`).
class BackChevron extends StatelessWidget {
  const BackChevron({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 2,
      child: AppSvgIcon(Assets.icons.page.chevron, size: size, color: color),
    );
  }
}
