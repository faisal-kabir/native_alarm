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
///
/// [file] is a copy the app downloaded itself (e.g. an alarm sound's icon): it is
/// painted from there, with no lookup and no network, and the server copy is used
/// only if it is gone.
class CachedSvgIcon extends StatefulWidget {
  const CachedSvgIcon({
    super.key,
    required this.path,
    required this.size,
    required this.color,
    required this.fallback,
    this.file,
  });

  /// The file's path on the server (or a full URL).
  final String path;

  /// A full path of the same icon already on the device.
  final String? file;

  /// Width and height, already scaled by the caller (e.g. `20.r`).
  final double size;
  final Color color;
  final Widget fallback;

  @override
  State<CachedSvgIcon> createState() => _CachedSvgIconState();
}

class _CachedSvgIconState extends State<CachedSvgIcon> {
  /// Files already found on the device during this run, by URL. An icon shown again (a
  /// step coming back, a list rebuilding) paints at once: no cache lookup, no blank
  /// frame. Only paths are kept (a few dozen icons at most).
  static final Map<String, File> _known = {};

  late String _url = mediaUrl(widget.path);
  late Future<File> _file = _find(_url, widget.file);

  static Future<File> _find(String url, String? own) {
    final known = _known[url];
    if (known != null) return Future.value(known);
    if (own != null) {
      final file = File(own);
      if (file.existsSync()) return Future.value(_known[url] = file);
    }
    return DefaultCacheManager()
        .getSingleFile(url)
        .then((f) => _known[url] = f);
  }

  @override
  void didUpdateWidget(CachedSvgIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.file != widget.file) {
      if (oldWidget.file != widget.file) _known.remove(mediaUrl(widget.path));
      _url = mediaUrl(widget.path);
      _file = _find(_url, widget.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<File>(
        future: _file,
        initialData: _known[url],
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
            errorBuilder: (_, _, _) {
              // The file went away (cache cleanup): look it up again next time.
              _known.remove(url);
              return widget.fallback;
            },
          );
        },
      ),
    );
  }
}
