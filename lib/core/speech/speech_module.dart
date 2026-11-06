import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Provides the one speech recogniser of the app (the plugin keeps its listeners from
/// the first `initialize`, so there must be a single instance).
@module
abstract class SpeechModule {
  @lazySingleton
  SpeechToText get speechToText => SpeechToText();
}
