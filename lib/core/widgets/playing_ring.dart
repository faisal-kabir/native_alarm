import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_color.dart';

/// A thin orange ring around a round [child] (an avatar) that breathes while its
/// sound plays: 55 % → 100 % → 55 %, 1.4 s each way. The controller runs only while
/// [active] (and never with reduced motion), and the ring repaints on its own layer.
class PlayingRing extends StatefulWidget {
  const PlayingRing({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<PlayingRing> createState() => _PlayingRingState();
}

class _PlayingRingState extends State<PlayingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlayingRing old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spread = 1.5.r;
    // Same tree whether active or not, so the avatar inside is never rebuilt anew.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (widget.active)
                BoxShadow(
                  spreadRadius: spread,
                  color: AppColor.primary.withValues(
                    alpha: 0.55 + 0.45 * Curves.easeInOut.transform(_c.value),
                  ),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
