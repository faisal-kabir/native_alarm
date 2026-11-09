import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A card that changes place in its list travels there on a soft spring (210 / 30)
/// instead of jumping, so the eye follows which one moved (an alarm switched on that
/// now rings first, one switched off that gives up the top). FLIP: after each frame it
/// measures where it is laid out in [scope]; when that has moved it is drawn at the
/// old place and glides to the new one. Position only, so the words never stretch.
/// Reduced motion: it simply moves.
class Glide extends StatefulWidget {
  const Glide({super.key, required this.scope, required this.child});

  /// The key of the column the card lives in: places are measured against it.
  final GlobalKey scope;
  final Widget child;

  @override
  State<Glide> createState() => _GlideState();
}

class _GlideState extends State<Glide> with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 210,
    damping: 30,
  );

  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  double _from = 0; // where the glide starts, relative to the laid-out place
  double? _last; // the laid-out place after the last frame
  bool _queued = false;

  double get _offset => _from * (1 - _c.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _measure() {
    _queued = false;
    if (!mounted) return;
    final me = context.findRenderObject();
    final scope = widget.scope.currentContext?.findRenderObject();
    if (me is! RenderBox ||
        scope is! RenderBox ||
        !me.attached ||
        !scope.attached) {
      return;
    }
    final y = me.localToGlobal(Offset.zero, ancestor: scope).dy;
    final was = _last;
    _last = y;
    if (was == null || (was - y).abs() < 0.5) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    // Start where the card is drawn right now, so a second move continues the first.
    _from = was + _offset - y;
    _c.value = 0;
    _c.animateWith(SpringSimulation(_spring, 0, 1, 0));
  }

  @override
  Widget build(BuildContext context) {
    if (!_queued) {
      _queued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _offset), child: child),
    );
  }
}
