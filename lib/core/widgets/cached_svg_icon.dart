import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../network/media_url.dart';

/// A single-colour SVG icon that lives on the server ([path]), painted in [color].
/// [path] is what the database stores; the base URL is added here (`mediaUrl`).
///
/// The file is kept on the device by the cache manager, so an icon that was shown once
/// is still there offline and is not downloaded again. While it loads, or when it can
/// not be loaded at all, [fallback] is shown in its place (the same [size] box).
class CachedSvgIcon extends StatefulWidget {
  const CachedSvgIcon({
    super.key,
    required this.path,
    required this.size,
    required this.color,
    required this.fallback,
  });

  /// The file's path on the server (or a full URL).
  final String path;

  /// Width and height, already scaled by the caller (e.g. `20.r`).
  final double size;
  final Color color;
  final Widget fallback;

  @override
  State<CachedSvgIcon> createState() => _CachedSvgIconState();
}

class _CachedSvgIconState extends State<CachedSvgIcon> {
  late Future<File> _file = DefaultCacheManager().getSingleFile(
    mediaUrl(widget.path),
  );

  @override
  void didUpdateWidget(CachedSvgIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _file = DefaultCacheManager().getSingleFile(mediaUrl(widget.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<File>(
        future: _file,
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (file == null) {
            return snapshot.hasError ? widget.fallback : const SizedBox();
          }
          return SvgPicture.file(
            file,
            width: widget.size,
            height: widget.size,
            excludeFromSemantics: true,
            colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
            errorBuilder: (_, _, _) => widget.fallback,
          );
        },
      ),
    );
  }
}
