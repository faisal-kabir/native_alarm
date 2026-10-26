// lib/features/alarm/domain/entities/transcript.dart
import 'transcript_word.dart';

/// Represents a transcript for a specific audio track.
class Transcript {
  final String audioId;
  final int version;
  final List<TranscriptWord> words;

  const Transcript({required this.audioId, required this.version, required this.words});

  factory Transcript.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'] as List<dynamic>? ?? [];
    return Transcript(
      audioId: (json['audioTrackId'] ?? json['audioId'] ?? json['id'] ?? '') as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      words: wordsJson.map((e) => TranscriptWord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
