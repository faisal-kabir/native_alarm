import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_alarm/features/alarm/domain/entities/transcript.dart';
import 'package:native_alarm/features/alarm/domain/entities/transcript_word.dart';

void main() {
  group('Transcript and TranscriptWord Model Tests', () {
    test('TranscriptWord fromJson correctly maps word and timing fields', () {
      final json = {'word': 'Good', 'startMs': 0, 'endMs': 181};
      final word = TranscriptWord.fromJson(json);

      expect(word.text, 'Good');
      expect(word.startMs, 0);
      expect(word.endMs, 181);
    });

    test('Transcript parses the actual demo_alarm_message.json file', () {
      final file = File('assets/transcripts/demo_alarm_message.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Transcript JSON file must exist in assets/transcripts/',
      );

      final jsonContent =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final transcript = Transcript.fromJson(jsonContent);

      expect(transcript.audioId, 'morning_message');
      expect(transcript.words.length, 12);
      expect(transcript.words.first.text, 'Good');
      expect(transcript.words.first.startMs, 0);
      expect(transcript.words.last.text, 'mind.');
      expect(transcript.words.last.endMs, 3552);

      // Verify chronological ordering of words
      for (int i = 0; i < transcript.words.length - 1; i++) {
        expect(
          transcript.words[i].startMs <= transcript.words[i + 1].startMs,
          isTrue,
        );
      }
    });
  });
}
