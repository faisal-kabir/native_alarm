import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// The loading ("skeleton") shimmer: paints [child]'s shapes in [baseColor] with a soft
/// [highlightColor] band sweeping across them, over and over. Draw the placeholder
/// shapes in any opaque colour; only their outline is used.
///
/// Sweeping stops when the system asks for reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = AppColor.surfaceSecondary,
    this.highlightColor = AppColor.slotFree,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Its own layer: the sweep repaints only the placeholder, not the page around it.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
            stops: const [0.3, 0.5, 0.7],
            // Starts fully left of the child and ends fully right of it.
            transform: _SlideGradient(_controller.value * 2 - 1),
          ).createShader(bounds),
          child: child,
        ),
      ),
    );
  }
}

/// Moves a gradient sideways by [slide] times the width it is painted on.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.slide);

  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}
