import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_color.dart';
import 'splash_timeline.dart';

/// Eala's alarm mark, drawn from paths on a 512 grid, as the splash builds it.
///
/// [time] is the splash clock (0 → 1 over [SplashTimeline.hold]); the mark's own "e",
/// the bells and the legs arrive as it passes the turn. Repaints with [time] only,
/// on its own layer (the caller puts it behind a [RepaintBoundary]).
class EalaMarkPainter extends CustomPainter {
  EalaMarkPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  // The "e": a bowl with a half circle cut out (even-odd) and a curved tail.
  static final Path _bowl = Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(131, 271)
    ..arcToPoint(const Offset(381, 271), radius: const Radius.circular(125))
    ..close()
    ..moveTo(204, 225)
    ..arcToPoint(const Offset(308, 225), radius: const Radius.circular(52))
    ..close();
  static final Path _tail = Path()
    ..moveTo(341.7, 316.5)
    ..arcToPoint(const Offset(170.3, 316.5), radius: const Radius.circular(99));

  // The bells and legs, on a 32 grid (scaled to the 512 one when painted).
  static final Path _bellL = Path()
    ..moveTo(3.4, 9.6)
    ..arcToPoint(const Offset(9.8, 3.0), radius: const Radius.circular(6.2))
    ..cubicTo(10.5, 3.0, 10.8, 3.8, 10.3, 4.3)
    ..lineTo(4.7, 9.9)
    ..cubicTo(4.2, 10.4, 3.4, 10.2, 3.4, 9.6)
    ..close();
  static final Path _bellR = Path()
    ..moveTo(28.6, 9.6)
    ..arcToPoint(
      const Offset(22.2, 3.0),
      radius: const Radius.circular(6.2),
      clockwise: false,
    )
    ..cubicTo(21.5, 3.0, 21.2, 3.8, 21.7, 4.3)
    ..lineTo(27.3, 9.9)
    ..cubicTo(27.8, 10.4, 28.6, 10.2, 28.6, 9.6)
    ..close();
  static final Path _legL = Path()
    ..moveTo(8.2, 27.4)
    ..lineTo(6.4, 29.6);
  static final Path _legR = Path()
    ..moveTo(23.8, 27.4)
    ..lineTo(25.6, 29.6);

  @override
  void paint(Canvas canvas, Size size) {
    // Seconds since the "e" began to turn; nothing to draw before its own "e" shows.
    final m = time.value * SplashTimeline.hold - SplashTimeline.turn;
    final eo = SplashTimeline.markE(m);
    if (eo <= 0) return;

    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final color = AppColor.primary.withValues(alpha: eo);
    canvas.drawPath(_bowl, Paint()..color = color);
    canvas.drawPath(
      _tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48
        ..color = color,
    );

    canvas.translate(74.18, 75.54);
    canvas.scale(11.364);
    _bell(canvas, _bellL, SplashTimeline.bell(m, 0.62), 35, 0.85);
    _bell(canvas, _bellR, SplashTimeline.bell(m, 0.68), -35, 0.15);
    _leg(canvas, _legL, SplashTimeline.leg(m, 0.78));
    _leg(canvas, _legR, SplashTimeline.leg(m, 0.82));
    canvas.restore();
  }

  /// A bell grows from nothing about its lower inner corner, tilted [deg] and settling.
  void _bell(Canvas canvas, Path p, double s, double deg, double ox) {
    if (s <= 0) return;
    final b = p.getBounds();
    final o = Offset(b.left + b.width * ox, b.top + b.height * 0.85);
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(deg * (1 - s) * math.pi / 180);
    canvas.scale(s);
    canvas.translate(-o.dx, -o.dy);
    canvas.drawPath(
      p,
      Paint()..color = AppColor.primary.withValues(alpha: s.clamp(0.0, 1.0)),
    );
    canvas.restore();
  }

  void _leg(Canvas canvas, Path p, double k) {
    if (k <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = AppColor.primary.withValues(alpha: k.clamp(0.0, 1.0));
    for (final metric in p.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * k), paint);
    }
  }

  @override
  bool shouldRepaint(EalaMarkPainter old) => old.time != time;
}
