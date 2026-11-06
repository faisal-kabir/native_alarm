import 'package:equatable/equatable.dart';

/// An example line in one sound for one area of life (table `quotes_of_sound`). It is
/// a sample, never the user's own message.
class SoundQuote extends Equatable {
  final int id;
  final int areaId;
  final int soundId;
  final String text;

  const SoundQuote({
    required this.id,
    required this.areaId,
    required this.soundId,
    required this.text,
  });

  @override
  List<Object?> get props => [id, areaId, soundId, text];
}
