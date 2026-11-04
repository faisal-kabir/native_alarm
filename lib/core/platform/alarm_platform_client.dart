import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

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
@lazySingleton
class AlarmPlatformClient {
  static final MethodChannel _methodChannel = MethodChannel(
    Platform.isIOS ? 'app/alarm' : 'com.eala.app/alarm',
  );
  static final EventChannel _eventChannel = EventChannel(
    Platform.isIOS ? 'app/alarm_events' : 'com.eala.app/alarm_events',
  );

  /// One native subscription for the whole app. Each `receiveBroadcastStream()`
  /// call replaces the previous one on the native side, so a second client used to
  /// silently take all events away from the first.
  static final Stream<Map<String, dynamic>> _events = _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => Map<String, dynamic>.from(event as Map))
      .asBroadcastStream();

  /// Stream of native events, shared by every listener.
  Stream<Map<String, dynamic>> get events => _events;

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

  /// Android only: which permissions the alarm screen still needs
  /// (`notifications`, `fullScreenIntent`, `overlay`, `exactAlarm`).
  /// Everything is reported as granted on iOS.
  Future<Map<String, bool>> getAlarmScreenPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod(
        'getAlarmScreenPermissions',
      );
      return Map<String, bool>.from(result ?? {});
    } catch (_) {
      return {};
    }
  }

  /// Android only: opens the settings page of the next missing permission.
  Future<void> requestAlarmScreenPermissions() async {
    try {
      await _methodChannel.invokeMethod('requestAlarmScreenPermissions');
    } catch (_) {}
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

  /// Kept for existing callers; the shared event stream lives as long as the app.
  void dispose() {}
}
