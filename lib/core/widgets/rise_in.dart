import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The app's entrance motion: fades [child] in while it lifts [dy] up into place, once,
/// after [delay] ([duration], [RiseIn.curve]). [blur] adds a soft focus-in (in logical
/// pixels) that exists only while it moves. With [enabled] false, or when the system
/// asks for reduced motion, the child is simply shown.
///
/// Built for lists of many items: the motion is a [RiseTransition] (see there), and when
/// the motion is off no controller or timer is created at all.
///
/// The one entrance animation of the app: use it (or [RiseTransition] when the page
/// drives its own timeline) instead of writing another fade-and-lift.
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    this.enabled = true,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.dy = 8,
    this.blur = 0,
    required this.child,
  });

  final bool enabled;
  final Duration delay;
  final Duration duration;

  /// How far below its place the child starts (scaled with `.h`).
  final double dy;

  /// Blur sigma at the start; 0 = none.
  final double blur;
  final Widget child;

  /// The curve the app uses for things that settle into place.
  static const Curve curve = Cubic(0.22, 1, 0.36, 1);

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _t;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decided once, on first build: reduced motion or disabled means no animation.
    if (_controller != null || !widget.enabled) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller = controller;
    _t = CurvedAnimation(parent: controller, curve: RiseIn.curve);
    _timer = Timer(widget.delay, () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return widget.child;
    return RiseTransition(
      animation: t,
      dy: widget.dy,
      blur: widget.blur,
      child: widget.child,
    );
  }
}

/// The fade-and-lift of [RiseIn], driven by an [animation] the caller owns (0 = below
/// and invisible, 1 = in place), e.g. one window of a page's own timeline.
///
/// Cheap per frame: the fade is a [FadeTransition] (an opacity layer, no rebuild), only
/// the translate rebuilds, and the blur is dropped as soon as it is too small to see.
class RiseTransition extends StatelessWidget {
  const RiseTransition({
    super.key,
    required this.animation,
    this.dy = 8,
    this.blur = 0,
    required this.child,
  });

  final Animation<double> animation;

  /// How far below its place the child starts (scaled with `.h`).
  final double dy;

  /// Blur sigma at the start; 0 = none.
  final double blur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lift = dy.h;
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) {
          final left = 1 - animation.value;
          final moved = Transform.translate(
            offset: Offset(0, lift * left),
            child: child,
          );
          final sigma = blur * left;
          if (sigma < 0.05) return moved;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: moved,
          );
        },
      ),
    );
  }
}
