import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../constants/app_constant.dart';
import '../speech/dictation_controller.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';
import 'rise_in.dart';

/// The panel that replaces a text field while the user speaks: the live transcript,
/// then a pill with a discard button, the live loudness meter and the stop button,
/// then a caption. It arrives in 240 ms (fade, 8 up, 0.98 → 1).
///
/// Performance: the meter repaints on its own ticker inside its own layer, the
/// transcript re-lays-out only when a word changes (and for the 200-260 ms a new word
/// brightens), and the blinking caret is a [FadeTransition] that never rebuilds text.
class DictationBar extends StatefulWidget {
  const DictationBar({super.key, required this.controller});

  final DictationController controller;

  @override
  State<DictationBar> createState() => _DictationBarState();
}

class _DictationBarState extends State<DictationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();
  late final Animation<double> _t = CurvedAnimation(
    parent: _in,
    curve: RiseIn.curve,
  );

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final strings = appLanguage(context);
    return FadeTransition(
      opacity: _t,
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 8.h * (1 - _t.value)),
          child: Transform.scale(scale: 0.98 + 0.02 * _t.value, child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: c,
              builder: (_, _) =>
                  DictationTranscript(said: c.said, saying: c.saying),
            ),
            SizedBox(height: 10.h),
            Container(
              height: 56.h,
              padding: REdgeInsets.fromLTRB(12, 9, 9, 9),
              decoration: BoxDecoration(
                color: AppColor.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppConstant.pillRadius),
              ),
              child: Row(
                children: [
                  _RoundButton(
                    label: strings.dictation_discard,
                    size: 32.r,
                    color: AppColor.surfaceSecondary,
                    icon: Assets.icons.voice.close,
                    iconSize: 15.r,
                    iconColor: AppColor.textSecondary,
                    pressedScale: 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      c.cancel();
                    },
                  ),
                  SizedBox(width: 10.w),
                  Expanded(child: LiveMeter(level: c.level)),
                  SizedBox(width: 10.w),
                  _RoundButton(
                    label: strings.dictation_stop,
                    size: 38.r,
                    color: AppColor.primary,
                    icon: Assets.icons.voice.stop,
                    iconSize: 21.r,
                    iconColor: AppColor.onPrimary,
                    pressedScale: 0.92,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      c.commit();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              strings.dictation_listening,
              textAlign: TextAlign.center,
              style: appTheme(context).textTheme.bodySmall!
                  .copyWith(height: 20.3 / 14, color: AppColor.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatefulWidget {
  const _RoundButton({
    required this.label,
    required this.size,
    required this.color,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.pressedScale,
    required this.onTap,
  });

  final String label;
  final double size;
  final Color color;
  final SvgGenImage icon;
  final double iconSize;
  final Color iconColor;
  final double pressedScale;
  final VoidCallback onTap;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
            child: AppSvgIcon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// The scrolling loudness meter: 44 bars sampled ~22 times a second, the newest next to
/// the stop button; each bar eases to its new height in 90 ms, left bars faded. It
/// reads [level] on its own ticker and repaints only its own layer, so nothing above it
/// rebuilds. With reduced motion the bars stand still.
class LiveMeter extends StatefulWidget {
  const LiveMeter({super.key, required this.level});

  final ValueListenable<double> level;

  static const bars = 44;
  static const sampleMs = 44;
  static const easeMs = 90;
  static const floor = 0.06;

  @override
  State<LiveMeter> createState() => _LiveMeterState();
}

class _LiveMeterState extends State<LiveMeter>
    with SingleTickerProviderStateMixin {
  final _from = List<double>.filled(LiveMeter.bars, LiveMeter.floor);
  final _to = List<double>.filled(LiveMeter.bars, LiveMeter.floor);
  final _now = ValueNotifier<int>(0); // ms since start; repaints the painter
  int _sampledAt = -LiveMeter.sampleMs;
  late final Ticker _ticker = createTicker(_onTick);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _from.fillRange(0, LiveMeter.bars, 0.34);
      _to.fillRange(0, LiveMeter.bars, 0.34);
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMilliseconds;
    if (t - _sampledAt >= LiveMeter.sampleMs) {
      final k = _progress(t);
      for (var i = 0; i < LiveMeter.bars; i++) {
        _from[i] = _from[i] + (_to[i] - _from[i]) * k;
      }
      for (var i = 0; i < LiveMeter.bars - 1; i++) {
        _to[i] = _to[i + 1];
      }
      _to[LiveMeter.bars - 1] = math.max(LiveMeter.floor, widget.level.value);
      _sampledAt = t;
    }
    _now.value = t;
  }

  double _progress(int t) =>
      ((t - _sampledAt) / LiveMeter.easeMs).clamp(0.0, 1.0);

  @override
  void dispose() {
    _ticker.dispose();
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: 30.h,
          child: CustomPaint(
            painter: _MeterPainter(
              repaint: _now,
              from: _from,
              to: _to,
              progress: () => _progress(_now.value),
              gap: 2.5.w,
              corner: 2.r,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({
    required Listenable repaint,
    required this.from,
    required this.to,
    required this.progress,
    required this.gap,
    required this.corner,
  }) : super(repaint: repaint);

  final List<double> from;
  final List<double> to;
  final double Function() progress;
  final double gap;
  final double corner;

  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    const n = LiveMeter.bars;
    final w = math.max(2.0, (size.width - gap * (n - 1)) / n);
    final step = (size.width - w) / (n - 1);
    final k = progress();
    final cy = size.height / 2;
    for (var i = 0; i < n; i++) {
      final s = from[i] + (to[i] - from[i]) * k;
      final h = size.height * s;
      _paint.color = AppColor.primary.withValues(alpha: 0.35 + (i / n) * 0.65);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * step, cy - h / 2, w, h),
          Radius.elliptical(corner, corner * s),
        ),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) => false;
}

/// The words as they are spoken: one paragraph pinned to its bottom line, 2 to 4 lines
/// tall, fading in at the top. Settled words are white, the newest one brightens over
/// 260 ms, the word being said sits at 42 %, and an orange caret blinks after them.
class DictationTranscript extends StatefulWidget {
  const DictationTranscript({
    super.key,
    required this.said,
    required this.saying,
  });

  final List<String> said;
  final String saying;

  @override
  State<DictationTranscript> createState() => _DictationTranscriptState();
}

class _DictationTranscriptState extends State<DictationTranscript>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();

  // The newest settled word: 0.42 -> 1 over 260 ms.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  // The word being said: 0 -> 0.42 over 200 ms.
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  // The caret: 0.9 for 45 %, down to 0.15 by 70 %, held; every 1.05 s.
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  late final Animation<double> _caretOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.9), weight: 45),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.9,
        end: 0.15,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 25,
    ),
    TweenSequenceItem(tween: ConstantTween(0.15), weight: 30),
  ]).animate(_caret);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _caret.value = 0;
    } else if (!_caret.isAnimating) {
      _caret.repeat();
    }
  }

  @override
  void didUpdateWidget(DictationTranscript old) {
    super.didUpdateWidget(old);
    if (widget.said.length != old.said.length && widget.said.isNotEmpty) {
      _settle.forward(from: 0);
    }
    final newWord =
        widget.saying.isNotEmpty &&
        (old.saying.isEmpty || widget.said.length != old.said.length);
    if (newWord) _arrive.forward(from: 0);
    // Pin the newest line to the bottom before it is seen; no smooth scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _settle.dispose();
    _arrive.dispose();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = appTheme(context).textTheme.bodyLarge!.copyWith(
      fontSize: 17.spMin,
      height: 1.5,
      letterSpacing: 0,
      color: AppColor.textColor,
    );
    final said = widget.said;
    final settled = said.length > 1
        ? said.sublist(0, said.length - 1).join(' ')
        : '';
    final newest = said.isEmpty ? '' : said.last;
    final saying = widget.saying;
    final fade = 18.h;

    // Built once per word change; the blink below never rebuilds it.
    final caret = Padding(
      padding: REdgeInsets.only(left: 3),
      child: Transform.translate(
        offset: Offset(0, 0.14 * 17.spMin),
        child: FadeTransition(
          opacity: _caretOpacity,
          child: Container(
            width: 2.w,
            height: 17.spMin,
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 50.h, maxHeight: 96.h),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (b) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [AppColor.transparent, AppColor.onPrimary],
          stops: [0, b.height <= 0 ? 1 : (fade / b.height).clamp(0.0, 1.0)],
        ).createShader(b),
        child: SingleChildScrollView(
          controller: _scroll,
          padding: REdgeInsets.fromLTRB(2, 2, 2, 0),
          child: Semantics(
            liveRegion: true,
            label: [...said, saying].where((w) => w.isNotEmpty).join(' '),
            excludeSemantics: true,
            child: AnimatedBuilder(
              animation: Listenable.merge([_settle, _arrive]),
              builder: (_, _) => Text.rich(
                TextSpan(
                  style: style,
                  children: [
                    if (settled.isNotEmpty) TextSpan(text: '$settled '),
                    if (newest.isNotEmpty)
                      TextSpan(
                        text: newest,
                        style: TextStyle(
                          color: AppColor.textColor.withValues(
                            alpha:
                                0.42 +
                                0.58 * Curves.easeOut.transform(_settle.value),
                          ),
                        ),
                      ),
                    if (newest.isNotEmpty && saying.isNotEmpty)
                      const TextSpan(text: ' '),
                    if (saying.isNotEmpty)
                      TextSpan(
                        text: saying,
                        style: TextStyle(
                          color: AppColor.textColor.withValues(
                            alpha:
                                0.42 * Curves.easeOut.transform(_arrive.value),
                          ),
                        ),
                      ),
                    if (said.isEmpty && saying.isEmpty)
                      TextSpan(
                        text: '…',
                        style: TextStyle(
                          color: AppColor.textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: caret,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
