import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_alarm/core/platform/alarm_platform_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlarmPlatformClient Tests', () {
    late AlarmPlatformClient client;
    final List<MethodCall> methodCalls = [];

    setUp(() {
      methodCalls.clear();
      // Intercept calls on both possible channel names
      for (final channelName in ['app/alarm', 'com.native_alarm/alarm']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(channelName), (
              MethodCall call,
            ) async {
              methodCalls.add(call);
              if (call.method == 'consumeAlarmLaunch') {
                return {
                  'launchedFromAlarm': true,
                  'trackId': 'demo_alarm_message',
                  'isPlaying': true,
                  'positionMs': 1200,
                  'durationMs': 3556,
                };
              } else if (call.method == 'getPlaybackState') {
                return {
                  'state': 'customAudioPlaying',
                  'positionMs': 1500,
                  'durationMs': 3556,
                  'audioTrackId': 'demo_alarm_message',
                  'alarmId': 'test_alarm_1',
                };
              }
              return null;
            });
      }

      client = AlarmPlatformClient();
    });

    tearDown(() {
      for (final channelName in ['app/alarm', 'com.native_alarm/alarm']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(channelName), null);
      }
      client.dispose();
    });

    test(
      'consumeAlarmLaunch invokes native method and parses result',
      () async {
        final result = await client.consumeAlarmLaunch();
        expect(result['launchedFromAlarm'], true);
        expect(result['trackId'], 'demo_alarm_message');
        expect(result['isPlaying'], true);
        expect(result['positionMs'], 1200);
        expect(result['durationMs'], 3556);
        expect(
          methodCalls.any((call) => call.method == 'consumeAlarmLaunch'),
          true,
        );
      },
    );

    test('getPlaybackState returns current state', () async {
      final state = await client.getPlaybackState();
      expect(state['state'], 'customAudioPlaying');
      expect(state['positionMs'], 1500);
      expect(state['audioTrackId'], 'demo_alarm_message');
    });

    test(
      'pause, resume, seek, stop methods invoke correct platform channels',
      () async {
        await client.pause();
        await client.resume();
        await client.seek(500);
        await client.stop();

        final calledMethods = methodCalls.map((c) => c.method).toList();
        expect(
          calledMethods.contains('pauseCustomAudio') ||
              calledMethods.contains('pause'),
          true,
        );
        expect(
          calledMethods.contains('resumeCustomAudio') ||
              calledMethods.contains('resume'),
          true,
        );
        expect(
          calledMethods.contains('seekCustomAudio') ||
              calledMethods.contains('seek'),
          true,
        );
        expect(
          calledMethods.contains('stopCustomAudio') ||
              calledMethods.contains('stop'),
          true,
        );
      },
    );

    test('scheduleAlarm passes missionName and alarm parameters through MethodChannel', () async {
      final alarmData = {
        'alarmId': 'mission_alarm_456',
        'timeMs': 1700000000000,
        'audioTrackId': 'morning_message',
        'missionName': 'Start Morning Mission',
      };

      await client.scheduleAlarm(alarmData);

      final scheduleCall = methodCalls.firstWhere(
        (call) => call.method == 'scheduleAlarm',
      );
      expect(scheduleCall, isNotNull);
      final args = scheduleCall.arguments as Map;
      expect(args['alarmId'], 'mission_alarm_456');
      expect(args['missionName'], 'Start Morning Mission');
      expect(args['audioTrackId'], 'morning_message');
    });
  });
}
