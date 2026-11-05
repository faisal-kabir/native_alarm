import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_color.dart';
import 'shimmer.dart';

/// Placeholder for [AnimatedSelectList] while its rows load for the first time: the
/// same size and spacing as real rows, so nothing jumps when the data arrives. The
/// shapes inside the cards shimmer.
class SelectListSkeleton extends StatelessWidget {
  const SelectListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        children: [
          _rows(
            (_) => Container(
              height: 62.h,
              decoration: BoxDecoration(
                color: AppColor.cardColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          // The same rows again, holding only the grey shapes, drawn as one shimmer.
          Shimmer(child: _rows(_shapes)),
        ],
      ),
    );
  }

  Widget _rows(WidgetBuilder row) => Column(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) SizedBox(height: 8.h),
        Builder(builder: row),
      ],
    ],
  );

  Widget _shapes(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    return SizedBox(
      height: 62.h,
      child: Padding(
        padding: REdgeInsets.fromLTRB(12, 10, 14, 10),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(130.w, 13.h),
                  SizedBox(height: 8.h),
                  bar(200.w, 10.h),
                ],
              ),
            ),
            SizedBox(width: 13.w),
            Container(
              width: 28.r,
              height: 28.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
