import 'package:flutter/material.dart';

/// Every colour the app uses. Widgets read colours from here (or from the theme),
/// never as literals. Values come from the design tokens (`tokens.css`, iOS dark).
abstract final class AppColor {
  // Brand
  static const Color primary = Color(0xFFFF9A3C); // --accent-fill, gold/orange
  static const Color onPrimary = Color(0xFF000000);

  // Surfaces
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardColor = Color(0xFF1C1C1E); // --ios-card
  static const Color surfaceSecondary = Color(0xFF2C2C2E);
  // Empty place in the alarm meter.
  static const Color slotFree = Color(0xFF3A3A3C);

  // Text
  static const Color titleColor = Color(0xFFF7F5F1); // large screen titles
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99EBEBF5); // rgba(235,235,245,.6)
  static const Color textMuted = Color(0x4DEBEBF5); // rgba(235,235,245,.3)
  static const Color iconColor = Color(0xFFFFFFFF);

  // Floating tab bar (glass)
  static const Color tabIdle = Color(0xEBFFFFFF); // rgba(255,255,255,.92)
  // Tint of the liquid glass tab bar: near-black and mostly clear.
  static const Color glassTint = Color(0x1A101012);
  static const Color tabLensTop = Color(0x29FFFFFF); // the selected tab's lens

  // Choice lists and step screens
  static const Color selectRing = Color(0xCC545458); // rgba(84,84,88,.8)
  static const Color progressTrack = Color(0x1AFFFFFF); // rgba(255,255,255,.1)
  // Big composer text field: placeholder, the rule under it, quiet labels.
  static const Color fieldHint = Color(0x47F7F5F1); // rgba(247,245,241,.28)
  static const Color fieldRule = Color(0x80545458); // rgba(84,84,88,.5)
  static const Color textTertiary = Color(0x73EBEBF5); // rgba(235,235,245,.45)
  // Outline of the round play button before its row is chosen.
  static const Color playIdleBorder = Color(
    0x2EEBEBF5,
  ); // rgba(235,235,245,.18)

  // Success (the "reason is ready" seal).
  static const Color success = Color(0xFF30D158);

  // Alarm mark on a reason whose alarm is switched off.
  static const Color badgeOff = Color(0xFF3A3A3C);

  // Settings
  static const Color danger = Color(0xFFFF453A);
  static const Color divider = Color(0xA6545458); // rgba(84,84,88,.65)
  static const Color toggleOn = Color(0xFF30D158);
  static const Color toggleOff = Color(0x52787880); // rgba(120,120,128,.32)
  // The warm glow at the bottom of the Settings screen, light to dark.
  static const Color horizonLight = Color(0xFFF4C9A2);
  static const Color horizonMid = Color(0xFFE7B563);
  static const Color horizonDark = Color(0xFFC96B4B);

  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  /// A tint the server sent as an ARGB int (an area's, a voice's); the brand colour
  /// when it sent none.
  static Color tintOf(int? argb) => argb == null ? primary : Color(argb);
}
