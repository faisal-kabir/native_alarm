import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'speech_recognizer.dart';

/// What the dictation UI shows: listening or not, the words already said, the word
/// being said now, and a 0..1 loudness [level]. A text field owns one (like a
/// `TextEditingController`) and sets [onFinished] to receive the sentence.
abstract class DictationController extends ChangeNotifier {
  bool _listening = false;
  List<String> _said = const [];
  String _saying = '';
  final ValueNotifier<double> _level = ValueNotifier(0);

  /// Called with the whole sentence when a take ends and is kept.
  ValueChanged<String>? onFinished;

  bool get listening => _listening;

  /// Words fully said so far.
  List<String> get said => _said;

  /// The word being said right now (provisional), or ''.
  String get saying => _saying;

  /// Loudness 0..1, as often as the recogniser reports it. Separate from the rest, so
  /// a fast-changing level never rebuilds the transcript.
  ValueListenable<double> get level => _level;

  /// Starts a take. Returns false when speech input is not available.
  Future<bool> start();

  /// Stops early and keeps what was said.
  void commit();

  /// Stops and throws the take away.
  void cancel();

  @protected
  void begin() {
    _listening = true;
    _said = const [];
    _saying = '';
    _level.value = 0;
    notifyListeners();
  }

  @protected
  void setWords(List<String> said, String saying) {
    if (listEquals(said, _said) && saying == _saying) return;
    _said = List.unmodifiable(said);
    _saying = saying;
    notifyListeners();
  }

  @protected
  void setLevel(double v) => _level.value = v.clamp(0.0, 1.0);

  /// Ends the take; with [keep] the words (settled + the one being said) go to
  /// [onFinished].
  @protected
  void finish({required bool keep}) {
    if (!_listening) return;
    final out = [..._said, if (_saying.isNotEmpty) _saying].join(' ').trim();
    _listening = false;
    _said = const [];
    _saying = '';
    _level.value = 0;
    notifyListeners();
    if (keep && out.isNotEmpty) onFinished?.call(out);
  }

  @override
  void dispose() {
    _level.dispose();
    super.dispose();
  }
}

/// [DictationController] on the device's real speech recogniser.
@Injectable(as: DictationController)
class SpeechDictationController extends DictationController {
  final SpeechRecognizer recognizer;

  SpeechDictationController(this.recognizer);

  @override
  Future<bool> start() async {
    if (listening) return true;
    final ok = await recognizer.start(
      onWords: _onWords,
      onLevel: setLevel,
      onEnd: () => finish(keep: true),
    );
    if (ok) begin();
    return ok;
  }

  void _onWords(String text, bool isFinal) {
    if (!listening) return;
    final words = text.split(' ')..removeWhere((w) => w.isEmpty);
    if (isFinal) {
      setWords(words, '');
      finish(keep: true);
      return;
    }
    setWords(
      words.isEmpty ? const [] : words.sublist(0, words.length - 1),
      words.isEmpty ? '' : words.last,
    );
  }

  @override
  void commit() {
    finish(keep: true);
    recognizer.stop();
  }

  @override
  void cancel() {
    finish(keep: false);
    recognizer.cancel();
  }

  @override
  void dispose() {
    if (listening) recognizer.cancel();
    super.dispose();
  }
}
