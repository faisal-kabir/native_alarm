import 'package:eala/core/platform/alarm_schedule_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmScheduleOptions', () {
    test('defaults: 2 repeats every 10 seconds, no custom tune', () {
      final map = const AlarmScheduleOptions().toMap();
      expect(map['repeatCount'], 2);
      expect(map['repeatIntervalSec'], 10);
      expect(map.containsKey('tuneAsset'), isFalse);
    });

    test('repeatCount 0 is sent as 0 (no internal alarms)', () {
      expect(const AlarmScheduleOptions(repeatCount: 0).toMap()['repeatCount'], 0);
    });

    test('optional texts and tune are included only when set', () {
      final map = const AlarmScheduleOptions(
        tuneAsset: 'assets/audio/tune.mp3',
        title: 'Wake up',
        stopHintText: 'slide to stop',
      ).toMap();
      expect(map['tuneAsset'], 'assets/audio/tune.mp3');
      expect(map['title'], 'Wake up');
      expect(map['stopHintText'], 'slide to stop');
      expect(map.containsKey('subtitle'), isFalse);
    });
  });
}
