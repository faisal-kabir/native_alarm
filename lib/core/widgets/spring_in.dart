import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Pops [child] in once, on a [spring]: it grows from 60 % and fades in (the spring may
/// overshoot a little, which is the point), after [delay]. With reduced motion it is
/// simply there. Used for things that appear in place: a button that swaps in, a seal.
///
/// Cheap per frame: [FadeTransition] and [ScaleTransition] only (no rebuild).
class SpringIn extends StatefulWidget {
  const SpringIn({
    super.key,
    required this.spring,
    this.delay = Duration.zero,
    required this.child,
  });

  final SpringDescription spring;
  final Duration delay;
  final Widget child;

  @override
  State<SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<SpringIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
  );
  late final Animation<double> _scale = _c.drive(
    Tween<double>(begin: 0.6, end: 1),
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    void start() => _c.animateWith(SpringSimulation(widget.spring, 0, 1, 0));
    if (widget.delay == Duration.zero) {
      start();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) start();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The fade layer clamps an overshoot above 1 by itself.
    return FadeTransition(
      opacity: _c,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
