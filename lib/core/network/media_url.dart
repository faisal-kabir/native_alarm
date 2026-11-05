import '../constants/app_constant.dart';

/// The full URL of a file the server stores (icons, images, ...).
///
/// The database keeps only the file's **path** (e.g. `icons/health.svg`); the address
/// it lives under is [AppConstant.baseUrl]. Every widget that shows a server file
/// (`CachedSvgIcon` today, images later) calls this, so the base URL is added in one
/// place only. A value that already is a full `http(s)` URL is returned unchanged.
String mediaUrl(String path) {
  final value = path.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final base = AppConstant.baseUrl;
  final left = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final right = value.startsWith('/') ? value.substring(1) : value;
  return '$left/$right';
}
