import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:injectable/injectable.dart';

/// Plays short audio samples from the server (a voice's preview), one at a time.
/// A screen owns one (`instance<SamplePlayer>()`) and disposes it.
abstract class SamplePlayer {
  /// Fires when the current sample finishes by itself.
  Stream<void> get onComplete;

  /// Plays [url] from the start, stopping whatever played before. The file is kept on
  /// the device, so a sample heard once plays again offline. Throws when it can not
  /// be loaded or played.
  Future<void> play(String url);

  Future<void> stop();

  Future<void> dispose();
}

@Injectable(as: SamplePlayer)
class CachedSamplePlayer implements SamplePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    await _player.stop();
    await _player.play(DeviceFileSource(file.path));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
