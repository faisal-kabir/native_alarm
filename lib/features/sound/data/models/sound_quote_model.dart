import '../../../../core/utils/server_value.dart';
import '../../domain/entities/sound_quote.dart';

/// A `quotes_of_sound` row as the server sends it (snake_case keys).
class SoundQuoteModel extends SoundQuote {
  const SoundQuoteModel({
    required super.id,
    required super.areaId,
    required super.soundId,
    required super.text,
  });

  factory SoundQuoteModel.fromJson(Map<String, dynamic> json) =>
      SoundQuoteModel(
        id: (json['id'] as num).toInt(),
        areaId: (json['area_id'] as num).toInt(),
        soundId: (json['sound_id'] as num).toInt(),
        text: cleanText(json['quote']) ?? '',
      );
}
