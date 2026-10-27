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

    test('AlarmModel JSON serialization and deserialization roundtrip with missionName', () {
      final now = DateTime.now();
      final model = AlarmModel(
        id: 'test_mission_1',
        enabled: true,
        time: now,
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Mission Alarm',
        missionName: 'Start Morning Mission',
      );

      final json = model.toJson();
      expect(json['missionName'], 'Start Morning Mission');

      final fromJson = AlarmModel.fromJson(json);
      expect(fromJson.id, model.id);
      expect(fromJson.missionName, 'Start Morning Mission');
    });

    test('Old alarms without missionName deserialize safely with null (backward compatible)', () {
      final legacyJson = {
        'id': 'legacy_alarm_999',
        'enabled': true,
        'time': DateTime.now().toIso8601String(),
        'repeatWeekdays': [1, 2, 3],
        'audioTrackId': 'morning_message',
        'ringtoneId': 'default',
        'label': 'Old Saved Alarm',
      };

      final model = AlarmModel.fromJson(legacyJson);
      expect(model.id, 'legacy_alarm_999');
      expect(model.missionName, isNull);

      final entity = Alarm.fromModel(model);
      expect(entity.missionName, isNull);
      // Fallback behavior verification
      final effectiveMission = entity.missionName ?? 'Start Morning Mission';
      expect(effectiveMission, 'Start Morning Mission');
    });

    test('Alarm entity copyWith preserves and updates missionName', () {
      final now = DateTime.now();
      final alarm = Alarm(
        id: 'alarm_copy',
        enabled: true,
        time: now,
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Original',
        missionName: 'Original Mission',
      );

      final toggled = alarm.copyWith(enabled: false);
      expect(toggled.enabled, false);
      expect(toggled.missionName, 'Original Mission');

      final updatedMission = alarm.copyWith(missionName: 'Super Morning Focus');
      expect(updatedMission.missionName, 'Super Morning Focus');
      expect(updatedMission.enabled, true);
    });
  });
}
