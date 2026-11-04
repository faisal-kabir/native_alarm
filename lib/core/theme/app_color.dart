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
  static const Color tabBarFill = Color(0x611E1E20); // rgba(30,30,32,.38)
  static const Color tabBarBorder = Color(0x1FFFFFFF);
  static const Color tabBarGlossTop = Color(0x12FFFFFF);
  static const Color tabBarGlossBottom = Color(0x05FFFFFF);
  static const Color tabLensTop = Color(0x29FFFFFF);
  static const Color tabLensBottom = Color(0x14FFFFFF);

  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;
}
