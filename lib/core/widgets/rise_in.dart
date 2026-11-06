import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The app's entrance motion: fades [child] in while it lifts [dy] up into place, once,
/// after [delay] (600 ms, cubic 0.22 / 1 / 0.36 / 1). With [enabled] false, or when the
/// system asks for reduced motion, the child is simply shown.
///
/// Built for lists of many items: the fade is a [FadeTransition] (an opacity layer, no
/// rebuild per frame) and only the cheap translate rebuilds; when the motion is off no
/// controller or timer is created at all.
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    this.enabled = true,
    this.delay = Duration.zero,
    this.dy = 8,
    required this.child,
  });

  final bool enabled;
  final Duration delay;

  /// How far below its place the child starts (scaled with `.h`).
  final double dy;
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
      duration: const Duration(milliseconds: 600),
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
    final dy = widget.dy.h;
    return FadeTransition(
      opacity: t,
      child: AnimatedBuilder(
        animation: t,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, dy * (1 - t.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
