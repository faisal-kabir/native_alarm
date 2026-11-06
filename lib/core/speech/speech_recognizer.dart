import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// The device's speech recogniser (Apple Speech on iOS, Google on Android) behind a
/// small API. One listening session at a time; its callbacks belong to whoever called
/// [start] last. Use it through `DictationController`, not from widgets.
@lazySingleton
class SpeechRecognizer {
  final SpeechToText _stt;

  SpeechRecognizer(this._stt);

  void Function(String words, bool isFinal)? _onWords;
  VoidCallback? _onEnd;

  bool _initialized = false;

  /// Asks for the microphone / speech permissions the first time, then starts
  /// listening. Returns false when speech input is not available (permission denied,
  /// no recogniser on the device).
  ///
  /// [onWords] gets everything recognised so far ([isFinal] on the last result),
  /// [onLevel] the loudness 0..1, and [onEnd] fires when the recogniser stops by
  /// itself (silence, time limit, error).
  Future<bool> start({
    required void Function(String words, bool isFinal) onWords,
    required ValueChanged<double> onLevel,
    required VoidCallback onEnd,
  }) async {
    try {
      if (!_initialized) {
        _initialized = await _stt.initialize(
          onStatus: (status) {
            if (status == SpeechToText.doneStatus ||
                status == SpeechToText.notListeningStatus) {
              _onEnd?.call();
            }
          },
          onError: (_) => _onEnd?.call(),
        );
      }
      if (!_initialized) return false;
      _onWords = onWords;
      _onEnd = onEnd;
      await _stt.listen(
        onResult: (SpeechRecognitionResult r) =>
            _onWords?.call(r.recognizedWords, r.finalResult),
        onSoundLevelChange: (db) => onLevel(_toLevel(db)),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(minutes: 1),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Speech recognition failed to start: $e');
      return false;
    }
  }

  /// Stops listening; the words said so far are delivered as the final result.
  Future<void> stop() async {
    _onEnd = null;
    await _stt.stop();
  }

  /// Stops listening and drops the take.
  Future<void> cancel() async {
    _onWords = null;
    _onEnd = null;
    await _stt.cancel();
  }

  /// The plugin's sound level is in different ranges per platform (iOS about -50..0,
  /// Android about -2..10); a normal voice should land near 0.6-0.9.
  static double _toLevel(double db) {
    final v = Platform.isIOS ? (db + 50) / 50 : (db + 2) / 12;
    return v.clamp(0.0, 1.0);
  }
}
