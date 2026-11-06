import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// The round 36 play / stop button for audio previews (voices today, any sample
/// later). Outlined with a play triangle when idle; filled orange with a black icon
/// when [filled] (its row is chosen) or [playing]. While [playing], four [PlayBars]
/// dance inside it (a stop square with reduced motion).
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.label,
    required this.filled,
    required this.playing,
    required this.onTap,
  });

  /// Screen reader label ("Hear Astra" / "Stop Astra").
  final String label;
  final bool filled;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = filled || playing;
    final fg = on ? AppColor.onPrimary : AppColor.textSecondary;
    final Widget content;
    if (playing && !MediaQuery.disableAnimationsOf(context)) {
      content = PlayBars(color: fg);
    } else if (playing) {
      content = AppSvgIcon(Assets.icons.voice.stop, size: 12.r, color: fg);
    } else {
      // The triangle's optical centre is a touch left of its box.
      content = Transform.translate(
        offset: Offset(-1.r, 0),
        child: AppSvgIcon(Assets.icons.voice.play, size: 15.r, color: fg),
      );
    }
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36.r,
          height: 36.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? AppColor.primary
                : AppColor.primary.withValues(alpha: 0),
            border: Border.all(
              color: on ? AppColor.transparent : AppColor.playIdleBorder,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// "Now playing": four bars in a 14-tall box dancing 4 → 13 → 6 → 11 → 4 over
/// 0.9 s, each 0.12 s after the one before. Painted (no widget rebuilds) on its own
/// layer, and only while it is on screen.
class PlayBars extends StatefulWidget {
  const PlayBars({super.key, required this.color});

  final Color color;

  @override
  State<PlayBars> createState() => _PlayBarsState();
}

class _PlayBarsState extends State<PlayBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(17.5.r, 14.r), // 4 bars of 2.5 with 2.5 between them
          painter: _BarsPainter(_c, widget.color),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.t, this.color) : super(repaint: t);

  final Animation<double> t;
  final Color color;

  static final _height = TweenSequence<double>([
    for (final (a, b) in const [
      (4.0, 13.0),
      (13.0, 6.0),
      (6.0, 11.0),
      (11.0, 4.0),
    ])
      TweenSequenceItem(
        tween: Tween<double>(
          begin: a,
          end: b,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height / 14;
    final w = 2.5 * unit;
    final paint = Paint()..color = color;
    for (var i = 0; i < 4; i++) {
      final h = _height.transform((t.value - i * 0.12 / 0.9) % 1) * unit;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 2 * w, (size.height - h) / 2, w, h),
          Radius.circular(2 * unit),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.color != color;
}
