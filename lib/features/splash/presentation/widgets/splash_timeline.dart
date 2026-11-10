import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Every time and curve of the splash, as pure functions of seconds `t` from its first
/// frame (3.9 s in all):
///
/// * 0.15 / 0.43 / 0.71 / 0.99: "e", "a", "l", "a" are written (the "a l a" wait 0.12 s
///   more); each rises out of a soft blur in 450 ms, and the word glides 500 ms so the
///   part shown stays centred.
/// * 1.74: the orange "e" makes one clockwise turn (900 ms) and becomes the alarm mark:
///   the letter fades as the mark's own "e" fades in, room opens after it, the two bells
///   spring out, the legs draw, and a light haptic tick rings it.
/// * 3.25 - 3.9: the word and then the black let go.
abstract final class SplashTimeline {
  /// When the word's first, second, third and fourth letter are written.
  static const stepAt = [0.15, 0.43, 0.71, 0.99];

  /// The turn: 0.15 + 3 × 0.28 + 0.75.
  static const turn = 1.74;

  /// Room opens for the mark after the "e".
  static const roomAt = turn + 0.6;

  /// Splash length, and how long before its end it lets go.
  static const hold = 3.9;
  static const leave = 0.65;

  /// The soft ring: the haptic tick.
  static const hapticAt = turn + 0.85;

  static const rise = Cubic(0.22, 1, 0.36, 1);
  static const spin = Cubic(0.65, 0, 0.35, 1);

  static double _unit(double x) => x.clamp(0.0, 1.0);

  /// When letter [i] starts its rise.
  static double letterStart(int i) => stepAt[i] + (i > 0 ? 0.12 : 0);

  /// 0 → 1 as letter [i] rises out of its blur (450 ms).
  static double letter(int i, double t) =>
      rise.transform(_unit((t - letterStart(i)) / 0.45));

  /// The word's slide so the part shown stays centred; [w] are the four letter widths.
  /// Each new letter starts a 500 ms glide from wherever the word is at that moment.
  static double glide(double t, List<double> w) {
    final total = w.reduce((a, b) => a + b);
    double target(int n) {
      if (n >= 4) return 0;
      var shown = 0.0;
      for (var i = 0; i < math.max(1, n); i++) {
        shown += w[i];
      }
      return (total - shown) / 2;
    }

    var from = target(0);
    var to = from;
    var start = 0.0;
    double at(double time) =>
        from + (to - from) * rise.transform(_unit((time - start) / 0.5));
    for (var n = 2; n <= 4; n++) {
      final te = stepAt[n - 1];
      if (te > t) break;
      from = at(te);
      to = target(n);
      start = te;
    }
    return at(t);
  }

  /// The "e" turn in turns: 0 → 1, clockwise.
  static double turns(double t) => spin.transform(_unit((t - turn) / 0.9));

  /// The letter "e" fading out as the mark takes its place (1 → 0).
  static double eLetter(double t) =>
      1 - Curves.easeInOut.transform(_unit((t - (turn + 0.3)) / 0.3));

  /// The gap that opens after the "e" for the mark, for a word of type size [size].
  static double room(double t, double size) =>
      size * 0.08 * rise.transform(_unit((t - roomAt) / 0.45));

  /// The word's opacity while it lets go.
  static double wordOpacity(double t) =>
      1 - Curves.easeInOut.transform(_unit((t - (hold - leave)) / 0.5));

  /// The black's opacity while it lets go.
  static double blackOpacity(double t) =>
      1 - Curves.easeInOut.transform(_unit((t - (hold - leave) - 0.1) / 0.6));

  // ---- inside the mark; [m] is seconds since the turn began ----

  /// The mark's own "e" fading in (0.3 s after the turn, 0.3 s long).
  static double markE(double m) =>
      Curves.easeInOut.transform(_unit((m - 0.3) / 0.3));

  static final _bell = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 380, damping: 13),
    0,
    1,
    0,
  );

  /// A bell's spring 0 → 1 (overshooting), [delay] seconds after the turn.
  static double bell(double m, double delay) =>
      m <= delay ? 0 : _bell.x(m - delay);

  /// A leg's draw 0 → 1, [delay] seconds after the turn, 280 ms.
  static double leg(double m, double delay) =>
      rise.transform(_unit((m - delay) / 0.28));
}
