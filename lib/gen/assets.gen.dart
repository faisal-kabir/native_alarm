/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsAudioGen {
  const $AssetsAudioGen();

  /// File path: assets/audio/demo.aiff
  String get demo => 'assets/audio/demo.aiff';

  /// File path: assets/audio/demo_alarm_message.mp3
  String get demoAlarmMessage => 'assets/audio/demo_alarm_message.mp3';

  /// List of all assets
  List<String> get values => [demo, demoAlarmMessage];
}

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// Directory path: assets/icons/area
  $AssetsIconsAreaGen get area => const $AssetsIconsAreaGen();

  /// File path: assets/icons/info.svg
  SvgGenImage get info => const SvgGenImage('assets/icons/info.svg');

  /// Directory path: assets/icons/page
  $AssetsIconsPageGen get page => const $AssetsIconsPageGen();

  /// File path: assets/icons/quote.svg
  SvgGenImage get quote => const SvgGenImage('assets/icons/quote.svg');

  /// Directory path: assets/icons/tab
  $AssetsIconsTabGen get tab => const $AssetsIconsTabGen();

  /// List of all assets
  List<SvgGenImage> get values => [info, quote];
}

class $AssetsTranscriptsGen {
  const $AssetsTranscriptsGen();

  /// File path: assets/transcripts/demo_alarm_message.json
  String get demoAlarmMessage => 'assets/transcripts/demo_alarm_message.json';

  /// List of all assets
  List<String> get values => [demoAlarmMessage];
}

class $AssetsIconsAreaGen {
  const $AssetsIconsAreaGen();

  /// File path: assets/icons/area/business.svg
  SvgGenImage get business =>
      const SvgGenImage('assets/icons/area/business.svg');

  /// File path: assets/icons/area/career.svg
  SvgGenImage get career => const SvgGenImage('assets/icons/area/career.svg');

  /// File path: assets/icons/area/family.svg
  SvgGenImage get family => const SvgGenImage('assets/icons/area/family.svg');

  /// File path: assets/icons/area/fitness.svg
  SvgGenImage get fitness => const SvgGenImage('assets/icons/area/fitness.svg');

  /// File path: assets/icons/area/growth.svg
  SvgGenImage get growth => const SvgGenImage('assets/icons/area/growth.svg');

  /// File path: assets/icons/area/healing.svg
  SvgGenImage get healing => const SvgGenImage('assets/icons/area/healing.svg');

  /// File path: assets/icons/area/health.svg
  SvgGenImage get health => const SvgGenImage('assets/icons/area/health.svg');

  /// File path: assets/icons/area/money.svg
  SvgGenImage get money => const SvgGenImage('assets/icons/area/money.svg');

  /// File path: assets/icons/area/relationships.svg
  SvgGenImage get relationships =>
      const SvgGenImage('assets/icons/area/relationships.svg');

  /// File path: assets/icons/area/study.svg
  SvgGenImage get study => const SvgGenImage('assets/icons/area/study.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    business,
    career,
    family,
    fitness,
    growth,
    healing,
    health,
    money,
    relationships,
    study,
  ];
}

class $AssetsIconsPageGen {
  const $AssetsIconsPageGen();

  /// File path: assets/icons/page/alarm_badge.svg
  SvgGenImage get alarmBadge =>
      const SvgGenImage('assets/icons/page/alarm_badge.svg');

  /// File path: assets/icons/page/alarm_off_badge.svg
  SvgGenImage get alarmOffBadge =>
      const SvgGenImage('assets/icons/page/alarm_off_badge.svg');

  /// File path: assets/icons/page/chevron.svg
  SvgGenImage get chevron => const SvgGenImage('assets/icons/page/chevron.svg');

  /// File path: assets/icons/page/plus.svg
  SvgGenImage get plus => const SvgGenImage('assets/icons/page/plus.svg');

  /// List of all assets
  List<SvgGenImage> get values => [alarmBadge, alarmOffBadge, chevron, plus];
}

class $AssetsIconsTabGen {
  const $AssetsIconsTabGen();

  /// File path: assets/icons/tab/alarm.svg
  SvgGenImage get alarm => const SvgGenImage('assets/icons/tab/alarm.svg');

  /// File path: assets/icons/tab/alarm_on.svg
  SvgGenImage get alarmOn => const SvgGenImage('assets/icons/tab/alarm_on.svg');

  /// File path: assets/icons/tab/reasons.svg
  SvgGenImage get reasons => const SvgGenImage('assets/icons/tab/reasons.svg');

  /// File path: assets/icons/tab/reasons_on.svg
  SvgGenImage get reasonsOn =>
      const SvgGenImage('assets/icons/tab/reasons_on.svg');

  /// File path: assets/icons/tab/settings.svg
  SvgGenImage get settings =>
      const SvgGenImage('assets/icons/tab/settings.svg');

  /// File path: assets/icons/tab/settings_on.svg
  SvgGenImage get settingsOn =>
      const SvgGenImage('assets/icons/tab/settings_on.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    alarm,
    alarmOn,
    reasons,
    reasonsOn,
    settings,
    settingsOn,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsAudioGen audio = $AssetsAudioGen();
  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const AssetGenImage logo = AssetGenImage('assets/logo.png');
  static const $AssetsTranscriptsGen transcripts = $AssetsTranscriptsGen();

  /// List of all assets
  static List<AssetGenImage> get values => [logo];
}

class AssetGenImage {
  const AssetGenImage(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
