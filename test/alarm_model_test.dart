import 'package:flutter_test/flutter_test.dart';
import 'package:native_alarm/features/alarm/data/models/alarm_model.dart';
import 'package:native_alarm/features/alarm/domain/entities/alarm.dart';

void main() {
  group('Alarm & AlarmModel Tests', () {
    test('AlarmModel JSON serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final model = AlarmModel(
        id: 'test_123',
        enabled: true,
        time: now,
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Test Alarm',
      );

      final json = model.toJson();
      final fromJson = AlarmModel.fromJson(json);

      expect(fromJson.id, model.id);
      expect(fromJson.enabled, model.enabled);
      expect(
        fromJson.time.millisecondsSinceEpoch ~/ 1000,
        model.time.millisecondsSinceEpoch ~/ 1000,
      );
      expect(fromJson.audioTrackId, model.audioTrackId);
      expect(fromJson.label, model.label);
    });

    test('Alarm entity converts to and from AlarmModel correctly', () {
      final now = DateTime.now();
      final alarm = Alarm(
        id: 'alarm_abc',
        enabled: true,
        time: now,
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Wake Up',
      );

      final model = alarm.toModel();
      final convertedBack = Alarm.fromModel(model);

      expect(convertedBack.id, alarm.id);
      expect(convertedBack.enabled, alarm.enabled);
      expect(convertedBack.audioTrackId, alarm.audioTrackId);
      expect(convertedBack.label, alarm.label);
    });
  });
}
