import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_color.dart';
import 'dimension.dart';

/// App-wide theme. The design is dark only (iOS dark tokens). Text uses the system
/// font (SF Pro on iOS, Roboto on Android), so no fontFamily is set.
///
/// Every text style sets letterSpacing, otherwise Material 3's default tracking
/// (e.g. 0.4 on bodySmall) is merged in and the text looks wider than designed.
///
/// Text roles used by the screens:
/// * headlineLarge  – large screen title ("My Alarms")
/// * headlineSmall  – section header ("Your alarms")
/// * titleLarge     – card title ("Set your first alarm")
/// * titleMedium    – list row title (a reason's name)
/// * titleSmall     – quiet add-row label ("New Reason")
/// * bodyLarge      – list row subtitle ("Health · Encouraging")
/// * bodyMedium     – regular body text
/// * bodySmall      – supporting, muted text under a title
/// * labelLarge     – small secondary label ("Up to 3")
/// * labelSmall     – tab bar label
abstract final class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColor.primary,
      onPrimary: AppColor.onPrimary,
      secondary: AppColor.primary,
      onSecondary: AppColor.onPrimary,
      surface: AppColor.cardColor,
      onSurface: AppColor.textColor,
    ),
    primaryColor: AppColor.primary,
    primaryColorDark: AppColor.textColor,
    primaryColorLight: AppColor.textColor,
    scaffoldBackgroundColor: AppColor.backgroundColor,
    dividerColor: AppColor.transparent,
    canvasColor: AppColor.cardColor,
    splashFactory: NoSplash.splashFactory,
    // Android gets the iOS slide too (iOS already uses it by default): a new page slides
    // in from the right and goes back out to the right, for every route.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
    ),
    hoverColor: AppColor.transparent,
    splashColor: AppColor.transparent,
    highlightColor: AppColor.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: AppColor.slotFree,
      cursorColor: AppColor.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(
        color: AppColor.textMuted,
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColor.backgroundColor,
      iconTheme: const IconThemeData(color: AppColor.iconColor),
      titleTextStyle: TextStyle(
        color: AppColor.textColor,
        fontSize: 20.spMin,
        fontWeight: Dimension.textMedium,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColor.cardColor,
    ),
    cardTheme: CardThemeData(
      color: AppColor.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
    ),
    buttonTheme: const ButtonThemeData(buttonColor: AppColor.primary),
    iconTheme: const IconThemeData(color: AppColor.iconColor),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: AppColor.titleColor,
        fontSize: 34.spMin,
        height: 40.8 / 34,
        fontWeight: Dimension.textBold,
        letterSpacing: 0.3,
        decorationColor: AppColor.titleColor,
      ),
      headlineMedium: TextStyle(
        color: AppColor.textColor,
        fontSize: 24.spMin,
        fontWeight: Dimension.textBold,
        letterSpacing: 0,
        decorationColor: AppColor.textColor,
      ),
      headlineSmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 20.spMin,
        fontWeight: Dimension.textBold,
        letterSpacing: -0.3,
        decorationColor: AppColor.textColor,
      ),
      displaySmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
        letterSpacing: 0,
        decorationColor: AppColor.textColor,
      ),
      titleLarge: TextStyle(
        color: AppColor.textColor,
        fontSize: 21.spMin,
        height: 25.2 / 21,
        fontWeight: Dimension.textRegular,
        letterSpacing: -0.3,
        decorationColor: AppColor.textColor,
      ),
      titleMedium: TextStyle(
        color: AppColor.titleColor,
        fontSize: 17.spMin,
        height: 20 / 17,
        fontWeight: Dimension.textSemiBold,
        letterSpacing: -0.4,
        decorationColor: AppColor.titleColor,
      ),
      titleSmall: TextStyle(
        color: AppColor.textColor,
        fontSize: 16.5.spMin,
        fontWeight: Dimension.textSemiBold,
        letterSpacing: -0.2,
        decorationColor: AppColor.textColor,
      ),
      bodyLarge: TextStyle(
        color: AppColor.textSecondary,
        fontSize: 15.spMin,
        height: 17.5 / 15,
        fontWeight: Dimension.textRegular,
        letterSpacing: -0.2,
        decorationColor: AppColor.textSecondary,
      ),
      bodyMedium: TextStyle(
        color: AppColor.textColor,
        fontSize: 14.spMin,
        fontWeight: Dimension.textRegular,
        letterSpacing: 0,
        decorationColor: AppColor.textColor,
      ),
      bodySmall: TextStyle(
        color: AppColor.textMuted,
        fontSize: 14.spMin,
        height: 16.5 / 14,
        fontWeight: Dimension.textRegular,
        letterSpacing: 0,
        decorationColor: AppColor.textMuted,
      ),
      labelLarge: TextStyle(
        color: AppColor.textSecondary,
        fontSize: 14.spMin,
        fontWeight: Dimension.textSemiBold,
        letterSpacing: 0,
        decorationColor: AppColor.textSecondary,
      ),
      labelSmall: TextStyle(
        color: AppColor.tabIdle,
        fontSize: 10.5.spMin,
        height: 12 / 10.5,
        fontWeight: Dimension.textSemiBold,
        letterSpacing: 0.05,
        decorationColor: AppColor.tabIdle,
      ),
    ),
  );
}
