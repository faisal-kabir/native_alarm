import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_color.dart';

/// The shared motion and shape of every choice list (framer-motion springs).
abstract final class SelectionMotion {
  /// The selection border sliding from row to row.
  static const borderSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 36,
  );

  /// A check / filled state springing in, with a small overshoot.
  static const checkSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 24,
  );

  /// A chosen marker gliding between options in a row (the sound dials).
  static const pickerSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 32,
  );

  /// Corner radius of a choice card (scaled with `.r` where used).
  static const double radius = 12;
}

/// The app's selection border: ONE orange 1 dp border drawn above [child] that
/// springs from the old selected row to the new one when [selectedId] changes, even
/// across headings or groups. Tapping again mid-flight sets off from wherever it is;
/// the first selection just appears; with reduced motion every change jumps.
///
/// Wrap the whole list once, and each selectable row in a [SlidingBorderTarget] with
/// its id. `AnimatedSelectList` uses it for flat lists; grouped lists (voices) use it
/// directly.
class SlidingBorderScope extends StatefulWidget {
  const SlidingBorderScope({
    super.key,
    required this.selectedId,
    required this.child,
  });

  final Object? selectedId;
  final Widget child;

  static SlidingBorderScopeState? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScopeData>()?.state;

  @override
  State<SlidingBorderScope> createState() => SlidingBorderScopeState();
}

class SlidingBorderScopeState extends State<SlidingBorderScope>
    with SingleTickerProviderStateMixin {
  final _stackKey = GlobalKey();
  final _rowKeys = <Object, GlobalKey>{};

  // 0 -> 1 between [_from] and [_to]; unbounded so the spring may overshoot.
  late final AnimationController _move = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  Rect? _from;
  Rect? _to;

  /// Where the border is drawn right now (null = nothing selected).
  @visibleForTesting
  Rect? get indicatorRect {
    if (_to == null) return null;
    if (_from == null) return _to;
    return Rect.lerp(_from, _to, _move.value);
  }

  GlobalKey _keyFor(Object id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  Rect? _rectOf(Object? id) {
    if (id == null) return null;
    final row = _rowKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (row == null || stack == null || !row.hasSize) return null;
    return row.localToGlobal(Offset.zero, ancestor: stack) & row.size;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
  }

  @override
  void didUpdateWidget(SlidingBorderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      // Rows are laid out after this build; slide once their rects are known.
      WidgetsBinding.instance.addPostFrameCallback((_) => _slideToSelected());
    }
  }

  void _jumpToSelected() {
    if (!mounted) return;
    setState(() {
      _from = null;
      _to = _rectOf(widget.selectedId);
      _move.value = 1;
    });
  }

  void _slideToSelected() {
    if (!mounted) return;
    final target = _rectOf(widget.selectedId);
    final current = indicatorRect;
    if (target == null ||
        current == null ||
        MediaQuery.disableAnimationsOf(context)) {
      _jumpToSelected();
      return;
    }
    _from = current;
    _to = target;
    _move
      ..value = 0
      ..animateWith(SpringSimulation(SelectionMotion.borderSpring, 0, 1, 0));
  }

  /// Keeps the border on its row if the layout changes while it is at rest
  /// (rotation, text scale, rows arriving from the server).
  void _followLayout() {
    if (!mounted || _move.isAnimating) return;
    final target = _rectOf(widget.selectedId);
    if (target != _to || _from != null) {
      setState(() {
        _from = null;
        _to = target;
        _move.value = 1;
      });
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _followLayout());
    return _ScopeData(
      state: this,
      child: Stack(
        key: _stackKey,
        children: [
          widget.child,
          // Drawn above the rows, never taking taps, on its own layer: while the
          // border springs only it repaints, not the rows.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BorderPainter(this, SelectionMotion.radius.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeData extends InheritedWidget {
  const _ScopeData({required this.state, required super.child});

  final SlidingBorderScopeState state;

  @override
  bool updateShouldNotify(_ScopeData old) => state != old.state;
}

/// Marks one selectable row of a [SlidingBorderScope] so the border can find it. Put it
/// outside any entrance transform of the row, so the border measures where the row
/// rests.
class SlidingBorderTarget extends StatelessWidget {
  const SlidingBorderTarget({super.key, required this.id, required this.child});

  final Object id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = SlidingBorderScope._maybeOf(context);
    if (scope == null) return child;
    return KeyedSubtree(key: scope._keyFor(id), child: child);
  }
}

/// The orange 1 dp border, fully inside the card, at the scope's current rect.
class _BorderPainter extends CustomPainter {
  _BorderPainter(this.state, this.radius) : super(repaint: state._move);

  final SlidingBorderScopeState state;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = state.indicatorRect;
    if (r == null) return;
    canvas.drawRRect(
      // A 1 dp stroke centred 0.5 dp in lies fully inside the card.
      RRect.fromRectAndRadius(r.deflate(0.5), Radius.circular(radius - 0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColor.primary
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_BorderPainter old) => true;
}
