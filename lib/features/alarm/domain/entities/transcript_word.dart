// lib/features/alarm/domain/entities/transcript_word.dart
import 'package:equatable/equatable.dart';

/// Represents a single word with start and end timestamps (in milliseconds)
/// from a transcript file.
class TranscriptWord extends Equatable {
  final String text;
  final int startMs;
  final int endMs;

  const TranscriptWord({
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  @override
  List<Object?> get props => [text, startMs, endMs];

  factory TranscriptWord.fromJson(Map<String, dynamic> json) => TranscriptWord(
        text: (json['word'] ?? json['text'] ?? '') as String,
        startMs: (json['startMs'] as num).toInt(),
        endMs: (json['endMs'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'startMs': startMs,
        'endMs': endMs,
      };
}
