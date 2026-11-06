import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';
import 'rise_in.dart';

/// The top bar of a multi-step flow, 44 tall: a back button, then a thin progress line.
///
/// [progress] is 0..1 (how far through the flow the current step is); the orange fill
/// grows to it over 900 ms and wears a dot on its end. [onBack] null hides the button.
class StepTopBar extends StatelessWidget {
  const StepTopBar({super.key, required this.progress, this.onBack});

  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Padding(
        padding: REdgeInsets.fromLTRB(8, 0, 24, 0),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: appLanguage(context).common_back,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: AnimatedOpacity(
                  opacity: onBack == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: 40.r,
                    height: 40.r,
                    child: Center(
                      // The forward chevron turned around.
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: AppSvgIcon(
                          Assets.icons.page.chevron,
                          size: 22.r,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Its own layer: the 900 ms fill does not repaint the back button.
            Expanded(
              child: RepaintBoundary(child: _ProgressLine(progress: progress)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final track = 2.h;
    final dot = 8.r;
    return Semantics(
      label: appLanguage(context).common_progress,
      value: '${(p * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: dot,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: track,
                decoration: BoxDecoration(
                  color: AppColor.progressTrack,
                  borderRadius: BorderRadius.circular(track),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: p),
                duration: const Duration(milliseconds: 900),
                curve: RiseIn.curve,
                builder: (_, value, _) {
                  final fill = constraints.maxWidth * value;
                  return SizedBox(
                    width: fill + dot / 2,
                    height: dot,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          width: fill,
                          height: track,
                          decoration: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(track),
                          ),
                        ),
                        if (value > 0)
                          Positioned(
                            left: fill - dot / 2,
                            child: Container(
                              width: dot,
                              height: dot,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
