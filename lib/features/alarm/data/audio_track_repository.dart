import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/entities/audio_track.dart';
import '../domain/entities/transcript.dart';

class AudioTrackRepository {
  static const List<AudioTrack> predefinedTracks = [
    AudioTrack(
      id: 'morning_message',
      title: 'Morning Motivation',
      assetPath: 'assets/audio/demo_alarm_message.mp3',
      transcriptPath: 'assets/transcripts/demo_alarm_message.json',
      duration: Duration(milliseconds: 3556),
    ),
  ];

  static Future<Transcript> loadTranscript(String transcriptPath) async {
    final jsonString = await rootBundle.loadString(transcriptPath);
    final data = json.decode(jsonString) as Map<String, dynamic>;
    return Transcript.fromJson(data);
  }
}
