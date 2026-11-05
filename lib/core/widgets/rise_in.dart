import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The app's entrance motion: fades [child] in while it lifts [dy] up into place, once,
/// after [delay] (600 ms, cubic 0.22 / 1 / 0.36 / 1). With [enabled] false the child is
/// simply shown.
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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: widget.enabled ? 0 : 1,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: RiseIn.curve,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.dy.h * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
