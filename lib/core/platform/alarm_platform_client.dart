// lib/core/platform/alarm_platform_client.dart
import 'dart:async';
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
  static const MethodChannel _methodChannel = MethodChannel('com.native_alarm/alarm');
  static const EventChannel _eventChannel = EventChannel('com.native_alarm/alarm_events');

  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

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
    final result = await _methodChannel.invokeMethod<bool>('hasNotificationPermission');
    return result ?? true;
  }

  Future<void> stopAlarm({String audioTrackId = 'morning_message'}) async {
    await _methodChannel.invokeMethod('stopAlarm', {'audioTrackId': audioTrackId});
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
    await _methodChannel.invokeMethod('seekCustomAudio', {'positionMs': positionMs});
  }

  Future<void> stopCustomAudio() async {
    await _methodChannel.invokeMethod('stopCustomAudio');
  }

  Future<Map<String, dynamic>> getPlaybackState() async {
    final result = await _methodChannel.invokeMethod('getPlaybackState');
    return Map<String, dynamic>.from(result ?? {});
  }

  void dispose() {
    _eventController.close();
  }
}
