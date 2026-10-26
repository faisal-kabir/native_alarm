// lib/features/alarm/domain/entities/audio_track.dart
import 'package:equatable/equatable.dart';

/// Represents a bundled audio track that can be played as the custom audio after an alarm.
class AudioTrack extends Equatable {
  final String id;
  final String title;
  final String assetPath; // Path relative to assets/audio/
  final String transcriptPath; // Path relative to assets/transcripts/
  final Duration? duration; // Optional, can be derived from the file.

  const AudioTrack({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.transcriptPath,
    this.duration,
  });

  @override
  List<Object?> get props => [id, title, assetPath, transcriptPath, duration];
}
