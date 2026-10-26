import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Represents the possible native states of an alarm or playback.
enum AlarmState {
  idle,
  scheduled,
  ringing,
  alarmDismissed,
  customAudioPlaying,
  customAudioPaused,
  customAudioStopped,
  completed,
  error,
}

/// A thin wrapper around platform channels to communicate with native code.
class AlarmPlatformClient {
  static final MethodChannel _methodChannel = MethodChannel(
    Platform.isIOS ? 'app/alarm' : 'com.native_alarm/alarm',
  );
  static final EventChannel _eventChannel = EventChannel(
    Platform.isIOS ? 'app/alarm_events' : 'com.native_alarm/alarm_events',
  );

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  AlarmPlatformClient() {
    _eventChannel.receiveBroadcastStream().listen(_handleNativeEvent);
  }

  void _handleNativeEvent(dynamic event) {
    if (event is Map) {
      _eventController.add(Map<String, dynamic>.from(event));
    }
  }

  /// Stream of native events.
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  // ----- MethodChannel calls -----
  Future<void> scheduleAlarm(Map<String, dynamic> alarmData) async {
    await _methodChannel.invokeMethod('scheduleAlarm', alarmData);
  }

  Future<void> cancelAlarm(String alarmId) async {
    await _methodChannel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
  }

  Future<void> dismissAlarm() async {
    await _methodChannel.invokeMethod('dismissAlarm');
  }

  Future<void> requestNotificationPermission() async {
    await _methodChannel.invokeMethod('requestNotificationPermission');
  }

  Future<bool> hasNotificationPermission() async {
    final result = await _methodChannel.invokeMethod<bool>(
      'hasNotificationPermission',
    );
    return result ?? true;
  }

  Future<void> stopAlarm({String audioTrackId = 'morning_message'}) async {
    await _methodChannel.invokeMethod('stopAlarm', {
      'audioTrackId': audioTrackId,
    });
  }

  Future<void> startCustomAudio(String audioId) async {
    await _methodChannel.invokeMethod('startCustomAudio', {'audioId': audioId});
  }

  Future<void> pauseCustomAudio() async {
    await _methodChannel.invokeMethod('pauseCustomAudio');
  }

  Future<void> resumeCustomAudio() async {
    await _methodChannel.invokeMethod('resumeCustomAudio');
  }

  Future<void> seekCustomAudio(int positionMs) async {
    await _methodChannel.invokeMethod('seekCustomAudio', {
      'positionMs': positionMs,
    });
  }

  Future<void> stopCustomAudio() async {
    await _methodChannel.invokeMethod('stopCustomAudio');
  }

  // Direct aliases conforming to requirement 5
  Future<void> pause() => pauseCustomAudio();
  Future<void> resume() => resumeCustomAudio();
  Future<void> seek(int positionMs) => seekCustomAudio(positionMs);
  Future<void> stop() => stopCustomAudio();

  Future<Map<String, dynamic>> getPlaybackState() async {
    final result = await _methodChannel.invokeMethod('getPlaybackState');
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Consumes the pending alarm launch flag and returns playback status.
  Future<Map<String, dynamic>> consumeAlarmLaunch() async {
    try {
      final result = await _methodChannel.invokeMethod('consumeAlarmLaunch');
      return Map<String, dynamic>.from(result ?? {});
    } catch (_) {
      return {'launchedFromAlarm': false};
    }
  }

  /// Retrieves stored debug logs from native UserDefaults.
  Future<List<String>> getDebugLogs() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getDebugLogs',
      );
      return result?.map((e) => e.toString()).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _eventController.close();
  }
}
