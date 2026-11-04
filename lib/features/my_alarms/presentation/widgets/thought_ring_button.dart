import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// Today's-thought ring: a 40 circle (44 tap target) with a gold border and a 23 gold
/// quote badge at its lower right.
class ThoughtRingButton extends StatelessWidget {
  const ThoughtRingButton({super.key, this.onTap, this.image});

  final VoidCallback? onTap;

  /// Today's scene shown inside the ring; a plain dark circle when null.
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: appLanguage(context).my_alarms_thought_semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44.r,
          height: 44.r,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 2.r,
                top: 2.r,
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.surfaceSecondary,
                    image: image == null
                        ? null
                        : DecorationImage(image: image!, fit: BoxFit.cover),
                    border: Border.all(color: AppColor.primary, width: 2.r),
                  ),
                ),
              ),
              Positioned(
                left: 21.r,
                top: 19.r,
                child: Container(
                  width: 23.r,
                  height: 23.r,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.primary,
                  ),
                  child: AppSvgIcon(
                    Assets.icons.quote,
                    size: 14.r,
                    color: AppColor.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
