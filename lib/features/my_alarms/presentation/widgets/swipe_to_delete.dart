import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';

/// Letting an alarm go: not a button hidden behind the card - the card itself answers
/// the finger. Dragged left, the light drains out of it (saturation 35 %, brightness
/// 75 %, opacity 62 % at the line) and a ring opens in the space it leaves, filling
/// red as the finger nears the line (38 % of the width); past it the ring completes
/// and a firmer tap says so. Let go past the line (or tap the open ring) and [confirm]
/// is asked while the card rests open: yes and the card fades and shrinks to 96 %
/// (340 ms), its height closes (300 ms after 220) and [onDelete] runs at 520 ms; no
/// and it springs home. Let go after the ring has formed and it rests open with the
/// ring to tap; before that, home. A tap on an open card, or anywhere else, puts it
/// back. Horizontal only, so the list still scrolls; a screen reader gets a [label]
/// action instead. Reduced motion: no glides, it simply goes.
class SwipeToDelete extends StatefulWidget {
  const SwipeToDelete({
    super.key,
    required this.child,
    required this.onDelete,
    required this.confirm,
    required this.label,
  });

  final Widget child;

  /// Runs once the card has gone.
  final VoidCallback onDelete;

  /// Asks first; true goes, false brings the card home.
  final Future<bool> Function() confirm;

  /// The spoken action: "Delete alarm at 6:30 AM".
  final String label;

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete>
    with TickerProviderStateMixin {
  // Logical sizes (scaled with .r where drawn).
  static const _r = 21.0; // the ring's radius
  static const _startAt = 34.0; // travel before the ring begins to fill
  static const _commit = 0.38; // of the width: the line
  static const _amp = 1.7; // the card moves this much faster at first

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 40,
  );

  double get _open => (2 * _r + 6 + 8 + 10).r; // 66: where an open card rests
  double get _start => _startAt.r;
  double get _knee => _open * (1 - 1 / _amp);
  double get _limit => math.max(_start + 20.r, _width * _commit);

  /// Where the card is drawn for a finger travel of [raw] (<= 0): 1.7 x the finger
  /// up to the resting place, then 1:1.
  double _toCard(double raw) {
    final d = math.max(0.0, -raw);
    return -(d <= _open / _amp ? d * _amp : d + _knee);
  }

  double _toRaw(double card) {
    final c = math.max(0.0, -card);
    return -(c <= _open ? c / _amp : c - _knee);
  }

  // The finger's travel; unbounded so the spring may overshoot.
  late final AnimationController _raw = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _lit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final AnimationController _gone = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  final _timers = <Timer>[];

  bool _armed = false;
  bool _openNow = false;
  bool _removed = false;
  bool _asking = false;
  bool _started = false;
  double _origin = 0;
  double _travel = 0;
  double _width = 360;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _raw.dispose();
    _lit.dispose();
    _gone.dispose();
    super.dispose();
  }

  void _later(int ms, VoidCallback f) => _timers.add(
    Timer(Duration(milliseconds: ms), () {
      if (mounted) f();
    }),
  );

  void _settle(double toCardX, {double velocity = 0}) {
    final open = toCardX != 0;
    setState(() => _openNow = open);
    open ? _lit.forward() : _lit.reverse();
    final target = _toRaw(toCardX);
    if (_still) {
      _raw.value = target;
    } else {
      _raw.animateWith(SpringSimulation(_spring, _raw.value, target, velocity));
    }
  }

  void _dragStart(DragStartDetails d) {
    if (_removed) return;
    _origin = _raw.value;
    _travel = 0;
    _started = false;
    _raw.stop();
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_removed) return;
    _travel += d.delta.dx;
    _raw.value = math.min(0.0, _origin + _travel);
    final v = -_toCard(_raw.value);
    if (v > _start && !_started) {
      _started = true;
      HapticFeedback.selectionClick();
    }
    if (v <= _start) _started = false;
    final armed = v >= _limit;
    if (armed != _armed) {
      setState(() => _armed = armed);
      if (armed) HapticFeedback.mediumImpact();
    }
  }

  void _dragEnd(DragEndDetails d) {
    if (_removed) return;
    final v = -_toCard(_raw.value);
    final vx = d.velocity.pixelsPerSecond.dx;
    if (v >= _limit || (vx < -1500 && v > _limit * 0.7)) {
      _remove();
      return;
    }
    setState(() => _armed = false);
    // Past the point where the ring has formed it stays; short of it, home.
    final keep = vx > 600 ? false : (v > _start - 14.r || vx < -600);
    _settle(keep ? -_open : 0, velocity: vx);
  }

  Future<void> _remove() async {
    if (_removed || _asking) return;
    _asking = true;
    setState(() => _armed = false);
    _settle(-_open);
    final ok = await widget.confirm();
    _asking = false;
    if (!mounted) return;
    if (!ok) {
      _settle(0);
      return;
    }
    setState(() => _removed = true);
    HapticFeedback.heavyImpact();
    if (_still) {
      _gone.value = 1;
      widget.onDelete();
      return;
    }
    _raw.animateTo(
      _toRaw(-_width * 0.18),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
    );
    _gone.forward();
    _later(520, widget.onDelete);
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) {
        if (_openNow && !_asking && !_removed) _settle(0);
      },
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth.isFinite) _width = c.maxWidth;
          return AnimatedBuilder(
            animation: Listenable.merge([_raw, _lit, _gone]),
            builder: (context, _) {
              // The height closes 220 ms into the 520 ms (300 ms long).
              final collapse = Curves.easeOutQuint.transform(
                ((_gone.value * 520 - 220) / 300).clamp(0.0, 1.0),
              );
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: 1 - collapse,
                child: _body(_toCard(_raw.value)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _body(double x) {
    final limit = _limit;
    final fill = ((-x - _start) / (limit - _start)).clamp(0.0, 1.0);
    final dim = (-x / limit).clamp(0.0, 1.0);
    final ring = 26.r;
    final ringOpacity = _removed ? 0.0 : ((-x - ring) / ring).clamp(0.0, 1.0);
    final ringScale =
        0.8 + 0.2 * ((-x - ring) / (_open - ring)).clamp(0.0, 1.0);
    final lit = Curves.easeOut.transform(_lit.value);

    var card = widget.child;
    if (!_removed && dim > 0) {
      card = Opacity(
        opacity: 1 - 0.38 * dim,
        child: ColorFiltered(colorFilter: _drain(dim), child: card),
      );
    }
    if (_removed) {
      final k = Curves.easeInOut.transform(
        (_gone.value * 520 / 340).clamp(0.0, 1.0),
      );
      card = Opacity(
        opacity: 1 - k,
        child: Transform.scale(scale: 1 - 0.04 * k, child: card),
      );
    }
    final box = (2 * _r + 6).r;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: widget.label): _remove,
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The ring, in the space the card leaves.
          Positioned(
            right: 6.r,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: ringOpacity,
                child: Transform.scale(
                  scale: ringScale,
                  child: IgnorePointer(
                    ignoring: !(_openNow && !_removed),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _remove,
                      child: SizedBox.square(
                        dimension: box,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size.square(box),
                              painter: _RingPainter(math.max(fill, lit)),
                            ),
                            AnimatedScale(
                              scale: _armed ? 1.12 : 1,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutBack,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: (2 * _r - 4).r,
                                height: (2 * _r - 4).r,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _armed || _openNow
                                      ? Color.alphaBlend(
                                          AppColor.danger.withValues(
                                            alpha: 0.22,
                                          ),
                                          AppColor.cardColor,
                                        )
                                      : AppColor.transparent,
                                ),
                                child: AppSvgIcon(
                                  Assets.icons.settings.trash,
                                  size: 24.r,
                                  color: AppColor.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _dragStart,
            onHorizontalDragUpdate: _dragUpdate,
            onHorizontalDragEnd: _dragEnd,
            child: Transform.translate(
              offset: Offset(x, 0),
              child: Stack(
                children: [
                  card,
                  // An open card is put back by a tap, and the tap goes no further.
                  if (_openNow)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _settle(0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// saturate(1 - .65 d) then brightness(1 - .25 d), as one colour matrix.
  static ColorFilter _drain(double d) {
    final s = 1 - 0.65 * d;
    final b = 1 - 0.25 * d;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    return ColorFilter.matrix([
      (lr + (1 - lr) * s) * b, (lg - lg * s) * b, (lb - lb * s) * b, 0, 0, //
      (lr - lr * s) * b, (lg + (1 - lg) * s) * b, (lb - lb * s) * b, 0, 0, //
      (lr - lr * s) * b, (lg - lg * s) * b, (lb + (1 - lb) * s) * b, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
  }
}

/// A 2 track (white at 18 %) and a 2.5 red arc that fills from the top.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.fill);

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = 21.r;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.r
        ..color = AppColor.white.withValues(alpha: 0.18),
    );
    if (fill <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * fill.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5.r
        ..strokeCap = StrokeCap.round
        ..color = AppColor.danger,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fill != fill;
}
