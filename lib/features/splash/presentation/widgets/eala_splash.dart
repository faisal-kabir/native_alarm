import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../main.dart';
import 'eala_mark_painter.dart';
import 'splash_timeline.dart';

/// Shows the splash over [child] once per app run: the first time it is built (a cold
/// start). Opening the home screen again later never shows it again.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  /// Whether this run has had its splash; tests set it to start without one.
  @visibleForTesting
  static bool shown = false;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  late bool _splash;

  @override
  void initState() {
    super.initState();
    _splash = !SplashGate.shown;
    SplashGate.shown = true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_splash) EalaSplash(onDone: () => setState(() => _splash = false)),
      ],
    );
  }
}

/// The splash: on true black the word "eala" is written letter by letter from the middle
/// (orange "e", white "a l a"), then the "e" turns once and becomes the alarm mark, rings
/// with a light haptic tick, and the word and the black let go to the home screen under
/// it. Timings live in [SplashTimeline].
///
/// Calls [onDone] at the end (3.9 s), 250 ms after a tap (a tap skips), 200 ms in with
/// reduced motion (the finished word at once, no motion), or at once when a full page
/// covers it (the app opened by an alarm: the message page comes first).
///
/// Cheap by the app's rules: one clock drives everything through transitions made
/// once; the letters are laid out once and only move, fade and turn; the mark repaints
/// on its own layer; blur only while a letter rises.
class EalaSplash extends StatefulWidget {
  const EalaSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<EalaSplash> createState() => _EalaSplashState();
}

class _EalaSplashState extends State<EalaSplash> with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (SplashTimeline.hold * 1000).round()),
  )..addListener(_ring);

  /// The splash's own opacity: 1 until a tap skips it, then fades out.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );

  bool _started = false;
  bool _still = false;
  bool _rang = false;
  bool _done = false;
  Timer? _stillTimer;

  // The word's type size and its four letter widths, as last laid out.
  double _size = 0;
  List<double> _w = const [0, 0, 0, 0];

  /// With reduced motion the splash is this frame of the clock: the finished word.
  static const _stillAt = SplashTimeline.turn + 2;

  /// A window of the clock (seconds → value), made once; a still value without motion.
  Animation<double> _at(double Function(double t) f) =>
      _still ? AlwaysStoppedAnimation(f(_stillAt)) : _clock.drive(_Seconds(f));

  late final List<Animation<double>> _letters = [
    for (var i = 0; i < 4; i++) _at((t) => SplashTimeline.letter(i, t)),
  ];
  late final List<Animation<double>> _letterScales = [
    for (final p in _letters) p.drive(Tween(begin: 0.9, end: 1)),
  ];
  late final Animation<double> _wordX = _at(
    (t) => SplashTimeline.glide(t, _w) - SplashTimeline.room(t, _size) / 2,
  );
  late final Animation<double> _room = _at(
    (t) => SplashTimeline.room(t, _size),
  );
  late final Animation<double> _turns = _at(SplashTimeline.turns);
  late final Animation<double> _eLetter = _at(SplashTimeline.eLetter);
  late final Animation<double> _wordOpacity = _still
      ? const AlwaysStoppedAnimation(1)
      : _at(SplashTimeline.wordOpacity);
  late final Animation<double> _blackOpacity = _still
      ? const AlwaysStoppedAnimation(1)
      : _at(SplashTimeline.blackOpacity);
  late final EalaMarkPainter _mark = EalaMarkPainter(
    _still ? const AlwaysStoppedAnimation(1) : _clock,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A full page over the home screen (the message page after an alarm): no splash
    // to come back to.
    if (!TickerMode.valuesOf(context).enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }
    if (_started) return;
    _started = true;
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _stillTimer = Timer(const Duration(milliseconds: 200), _finish);
    } else {
      _clock.forward().whenComplete(_finish);
    }
  }

  @override
  void dispose() {
    _stillTimer?.cancel();
    if (!_still) {
      _clock.dispose();
      _exit.dispose();
    }
    super.dispose();
  }

  /// The light haptic tick as the mark rings, once.
  void _ring() {
    if (_rang || _clock.value * SplashTimeline.hold < SplashTimeline.hapticAt) {
      return;
    }
    _rang = true;
    HapticFeedback.lightImpact();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  /// A tap skips: the whole splash fades out in 250 ms.
  void _skip() {
    if (_done) return;
    if (_still) {
      _stillTimer?.cancel();
      _finish();
      return;
    }
    if (_exit.isAnimating) return;
    _clock.stop();
    _exit.reverse().whenComplete(_finish);
  }

  /// The width of each letter as it is set (tracking included), measured once per size.
  List<double> _measure(TextStyle style) {
    if (style.fontSize == _size) return _w;
    _size = style.fontSize!;
    return _w = [
      for (final ch in const ['e', 'a', 'l', 'a'])
        (TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout()).width,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = 84.r;
    final style = appTheme(context).textTheme.headlineLarge!.copyWith(
      fontSize: size,
      fontWeight: Dimension.textSemiBold,
      letterSpacing: size * 0.035,
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
      color: AppColor.white,
    );
    final w = _measure(style);
    final markSize = size * 1.18;

    Widget glyph(String ch, Color color) => Text(
      ch,
      softWrap: false,
      overflow: TextOverflow.visible,
      textScaler: TextScaler.noScaling,
      style: style.copyWith(color: color),
    );

    Widget letter(int i, Widget child) => SizedBox(
      width: w[i],
      height: size,
      child: _Rise(
        progress: _letters[i],
        scale: _letterScales[i],
        child: child,
      ),
    );

    final word = _SlideX(
      dx: _wordX,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The "e", which turns once about a point 60 % down it and becomes the mark.
          RotationTransition(
            turns: _turns,
            alignment: const Alignment(0, 0.2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                letter(
                  0,
                  FadeTransition(
                    opacity: _eLetter,
                    child: glyph('e', AppColor.primary),
                  ),
                ),
                Positioned(
                  left: w[0] / 2 - markSize / 2,
                  top: size * 0.58 - markSize * 0.53,
                  width: markSize,
                  height: markSize,
                  child: RepaintBoundary(child: CustomPaint(painter: _mark)),
                ),
              ],
            ),
          ),
          for (var i = 1; i < 4; i++)
            _SlideX(
              dx: _room,
              child: letter(
                i,
                glyph(const ['e', 'a', 'l', 'a'][i], AppColor.white),
              ),
            ),
        ],
      ),
    );

    Widget splash = Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _blackOpacity,
          child: const ColoredBox(color: AppColor.backgroundColor),
        ),
        FadeTransition(
          opacity: _wordOpacity,
          child: Center(
            child: Transform.translate(offset: Offset(0, -30.h), child: word),
          ),
        ),
      ],
    );
    if (!_still) splash = FadeTransition(opacity: _exit, child: splash);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Semantics(
          label: appLanguage(context).app_name,
          image: true,
          child: ExcludeSemantics(child: splash),
        ),
      ),
    );
  }
}

/// Maps the splash clock (0 → 1) to seconds and through [f].
class _Seconds extends Animatable<double> {
  const _Seconds(this.f);

  final double Function(double t) f;

  @override
  double transform(double t) => f(t * SplashTimeline.hold);
}

/// Moves [child] sideways by [dx]; only the transform changes, the child is never
/// rebuilt or laid out again.
class _SlideX extends AnimatedWidget {
  const _SlideX({required Animation<double> dx, required this.child})
    : super(listenable: dx);

  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset((listenable as Animation<double>).value, 0),
    child: child,
  );
}

/// A letter rising out of a soft blur: fades in, grows from 90 %, the blur clearing;
/// the blur exists only while it rises.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.progress,
    required this.scale,
    required this.child,
  });

  final Animation<double> progress;
  final Animation<double> scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: progress,
    child: ScaleTransition(
      scale: scale,
      child: AnimatedBuilder(
        animation: progress,
        child: child,
        builder: (context, child) {
          final p = progress.value;
          final sigma = 6 * (1 - p);
          return ImageFiltered(
            enabled: p > 0 && p < 1,
            imageFilter: ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
            child: child,
          );
        },
      ),
    ),
  );
}
