import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// A page's scrolling body with the app's "there is more below" hint: a 28 round
/// chevron, 12 from the right and 10 from the bottom, that fades and lifts in while
/// the content can scroll further down (220 ms) and goes at the end. A form page uses
/// it (a reason's screen, the alarm editor).
class HintedScrollView extends StatefulWidget {
  const HintedScrollView({
    super.key,
    required this.padding,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  State<HintedScrollView> createState() => _HintedScrollViewState();
}

class _HintedScrollViewState extends State<HintedScrollView> {
  bool _moreBelow = false;

  bool _onScroll(ScrollMetrics m) {
    if (m.axis != Axis.vertical) return false;
    // 24 dp of slack: a few dp of overflow is rounding, not content.
    final more = m.maxScrollExtent > 24 && m.pixels < m.maxScrollExtent - 24;
    if (more != _moreBelow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && more != _moreBelow) setState(() => _moreBelow = more);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Metrics: the content grew or shrank; scroll: the user moved it.
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) => _onScroll(n.metrics),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) => _onScroll(n.metrics),
            child: SingleChildScrollView(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
        Positioned(
          right: 12.w,
          bottom: 10.h,
          child: _ScrollHint(visible: _moreBelow),
        ),
      ],
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 220);
    return IgnorePointer(
      child: Semantics(
        label: visible ? appLanguage(context).common_more_below : null,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.15),
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            child: Container(
              width: 28.r,
              height: 28.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.surfaceSecondary.withValues(alpha: 0.88),
              ),
              // The forward chevron turned to point down.
              child: RotatedBox(
                quarterTurns: 1,
                child: AppSvgIcon(
                  Assets.icons.page.chevron,
                  size: 14.r,
                  color: AppColor.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
