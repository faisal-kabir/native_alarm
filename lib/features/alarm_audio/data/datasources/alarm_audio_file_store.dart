import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/alarm_audio.dart';

/// The name a downloaded file gets: the row, which file, and a fingerprint of the
/// server's [path] and [updatedAt], so a new path or a newer row means a new name
/// (download again) and the old file can be deleted. Keeps the file's extension
/// (`.mp3`, `.svg`, ...) so players and decoders know the type.
String alarmAudioFileName(
  AlarmAudioKind kind,
  int id,
  String part,
  String path,
  String? updatedAt,
) {
  // FNV-1a (32 bit): short, and the same on every device and run.
  var hash = 0x811C9DC5;
  for (final unit in '$path|${updatedAt ?? ''}'.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  final file = path.split('?').first.split('/').last;
  final dot = file.lastIndexOf('.');
  final extension = dot <= 0 ? '' : file.substring(dot).toLowerCase();
  final safe = RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)
      ? extension
      : '';
  return '${kind.table}-$id-$part-${hash.toRadixString(16)}$safe';
}

/// The folder (in the app's own support folder, never cleared by the system) that
/// holds the downloaded icon and audio files.
abstract class AlarmAudioFileStore {
  /// The folder's full path.
  Future<String> folder();

  Future<bool> exists(String name);

  /// Downloads [url] into the file [name]; the file appears only when it is complete.
  /// Throws [ServerException] when it could not be downloaded.
  Future<void> download(String url, String name);

  /// Deletes every file in the folder that is not one of [keep].
  Future<void> deleteAllBut(Set<String> keep);
}

@LazySingleton(as: AlarmAudioFileStore)
class AlarmAudioFileStoreImpl implements AlarmAudioFileStore {
  Future<Directory>? _directory;

  Future<Directory> _folder() => _directory ??= () async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/alarm_audio').create(recursive: true);
  }();

  @override
  Future<String> folder() async => (await _folder()).path;

  @override
  Future<bool> exists(String name) async =>
      File('${await folder()}/$name').exists();

  @override
  Future<void> download(String url, String name) async {
    final folder = await this.folder();
    final partial = File('$folder/$name.part');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw ServerException('HTTP ${response.statusCode} for $url');
      }
      await response
          .pipe(partial.openWrite())
          .timeout(const Duration(minutes: 2));
      await partial.rename('$folder/$name');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    } finally {
      client.close(force: true);
      try {
        if (await partial.exists()) await partial.delete();
      } on FileSystemException {
        // Left behind: removed by the next deleteAllBut.
      }
    }
  }

  @override
  Future<void> deleteAllBut(Set<String> keep) async {
    try {
      await for (final entity in (await _folder()).list()) {
        final name = entity.uri.pathSegments.last;
        if (entity is File && !keep.contains(name)) await entity.delete();
      }
    } on FileSystemException catch (e) {
      throw CacheException(e.message);
    }
  }
}
