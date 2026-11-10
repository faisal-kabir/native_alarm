import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/platform/alarm_platform_client.dart';
import '../../../../main.dart';
import '../../data/audio_track_repository.dart';
import '../pages/alarm_ringing_page.dart';
import '../pages/synchronized_transcript_page.dart';

/// Connects the native alarm layer to the UI. Wrap the app's home screen with it:
/// it opens the message page when the user unlocks from an alarm (event or cold
/// launch), the iOS ringing page while an alarm rings in the app, and walks Android
/// users through the permissions the alarm screen needs.
///
/// Only the first mounted listener acts, so a screen pushed on top that also uses
/// it can never open the same page twice.
class AlarmEventListener extends StatefulWidget {
  const AlarmEventListener({super.key, required this.child, this.onResumed});

  final Widget child;

  /// Called whenever the app comes back to the foreground.
  final VoidCallback? onResumed;

  @override
  State<AlarmEventListener> createState() => _AlarmEventListenerState();
}

class _AlarmEventListenerState extends State<AlarmEventListener>
    with WidgetsBindingObserver {
  static _AlarmEventListenerState? _active;

  final AlarmPlatformClient _platformClient = instance<AlarmPlatformClient>();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  bool _isRingingPageOpen = false;
  bool _isTranscriptPageOpen = false;

  // Static: a permission is asked once per app start, not once per screen.
  static final Set<String> _askedPermissions = {};
  bool _askingPermission = false;

  bool get _isActive => identical(_active, this);

  @override
  void initState() {
    super.initState();
    _active ??= this;
    if (!_isActive) return;

    WidgetsBinding.instance.addObserver(this);
    _checkAlarmLaunch();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureAlarmScreenPermissions(),
    );
    _eventSubscription = _platformClient.events.listen(_onNativeEvent);
  }

  void _onNativeEvent(Map<String, dynamic> event) {
    final type = event['event'] as String?;
    final eventAlarmId = event['alarmId'] as String?;
    if (type == 'alarmRinging') {
      // Android shows its own native alarm screen; the Flutter ringing page is iOS-only.
      if (Platform.isAndroid || SynchronizedTranscriptPage.isOpen) return;
      _navigateToRingingPage(alarmId: eventAlarmId);
    } else if (type == 'openTranscript' ||
        (type == 'customAudioStarted' && (eventAlarmId?.isNotEmpty ?? false))) {
      // Only alarm-originated starts open the page (they carry an alarmId);
      // replaying inside the message page must not push it again.
      _navigateToTranscript();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onResumed?.call();
      _checkAlarmLaunch();
      _ensureAlarmScreenPermissions();
    }
  }

  Future<void> _checkAlarmLaunch() async {
    try {
      final launchData = await _platformClient.consumeAlarmLaunch();
      final launched = launchData['launchedFromAlarm'] as bool? ?? false;
      if (launched) {
        if (!SynchronizedTranscriptPage.isOpen) _navigateToTranscript();
        return;
      }
    } catch (_) {}
    _checkInitialState();
  }

  /// iOS only: if the app was opened while the alarm is still ringing, show the
  /// ringing page. The message page is opened only through [_checkAlarmLaunch] or an
  /// alarm event, never just because audio is playing (that re-opened it after Back).
  Future<void> _checkInitialState() async {
    if (Platform.isAndroid) return;
    try {
      final state = await _platformClient.getPlaybackState();
      if (state['state'] == 'ringing') {
        _navigateToRingingPage(alarmId: state['alarmId'] as String?);
      }
    } catch (_) {}
  }

  String _permissionExplanation(String key) {
    final strings = appLanguage(context);
    return switch (key) {
      'notifications' => strings.alarm_permission_notifications,
      'fullScreenIntent' => strings.alarm_permission_full_screen,
      'overlay' => strings.alarm_permission_overlay,
      'exactAlarm' => strings.alarm_permission_exact_alarm,
      _ => key,
    };
  }

  /// Android only: walks the user through the permissions the alarm screen needs,
  /// one settings page at a time (each ask happens once per app start).
  Future<void> _ensureAlarmScreenPermissions() async {
    if (!Platform.isAndroid || _askingPermission) return;
    final status = await _platformClient.getAlarmScreenPermissions();
    final missing = status.entries
        .where((e) => !e.value && !_askedPermissions.contains(e.key))
        .map((e) => e.key)
        .toList();
    if (missing.isEmpty || !mounted) return;

    final key = missing.first;
    _askedPermissions.add(key);
    _askingPermission = true;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLanguage(ctx).alarm_permission_title),
        content: Text(_permissionExplanation(key)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appLanguage(ctx).common_not_now),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appLanguage(ctx).common_allow),
          ),
        ],
      ),
    );
    _askingPermission = false;
    if (agreed == true) {
      await _platformClient.requestAlarmScreenPermissions();
    }
  }

  Future<void> _navigateToTranscript() async {
    if (!mounted ||
        SynchronizedTranscriptPage.isOpen ||
        _isTranscriptPageOpen) {
      return;
    }
    final navigator = Navigator.of(context);
    if (_isRingingPageOpen) {
      navigator.popUntil((route) => route.isFirst);
      _isRingingPageOpen = false;
    }
    _isTranscriptPageOpen = true;
    await navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/transcript'),
        builder: (_) => SynchronizedTranscriptPage(
          platformClient: _platformClient,
          initialTrack: AudioTrackRepository.predefinedTracks.first,
        ),
      ),
    );
    _isTranscriptPageOpen = false;
  }

  Future<void> _navigateToRingingPage({String? alarmId}) async {
    if (!mounted ||
        _isRingingPageOpen ||
        _isTranscriptPageOpen ||
        SynchronizedTranscriptPage.isOpen) {
      return;
    }
    _isRingingPageOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/alarm_ringing'),
        builder: (_) => AlarmRingingPage(
          platformClient: _platformClient,
          alarmId: alarmId,
          audioTrack: AudioTrackRepository.predefinedTracks.first,
        ),
      ),
    );
    _isRingingPageOpen = false;
  }

  @override
  void dispose() {
    if (_isActive) {
      WidgetsBinding.instance.removeObserver(this);
      _eventSubscription?.cancel();
      _active = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
