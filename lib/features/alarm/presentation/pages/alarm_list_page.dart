import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/platform/alarm_platform_client.dart';
import '../../data/audio_track_repository.dart';
import '../../domain/entities/alarm.dart';
import 'alarm_ringing_page.dart';
import 'synchronized_transcript_page.dart';

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({super.key});

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage>
    with WidgetsBindingObserver {
  final AlarmPlatformClient _platformClient = AlarmPlatformClient();
  late List<Alarm> _alarms;
  StreamSubscription? _eventSubscription;
  bool _hasNotificationPermission = true;
  bool _isRinging = false;
  bool _isRingingPageOpen = false;
  bool _isTranscriptPageOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _alarms = [
      Alarm(
        id: 'alarm_1',
        enabled: true,
        time: DateTime.now().add(const Duration(minutes: 30)),
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Morning Awakening',
      ),
      Alarm(
        id: 'alarm_2',
        enabled: false,
        time: DateTime.now().add(const Duration(hours: 2)),
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
        label: 'Afternoon Focus',
      ),
    ];

    _checkNotificationPermission();
    _checkAlarmLaunch();

    // Listen to background alarm events
    _eventSubscription = _platformClient.events.listen((event) {
      final type = event['event'] as String?;
      if (type == 'alarmRinging') {
        if (_isTranscriptPageOpen) return;
        setState(() {
          _isRinging = true;
        });
        _navigateToRingingPage(alarmId: event['alarmId'] as String?);
      } else if (type == 'openTranscript' || type == 'customAudioStarted') {
        setState(() {
          _isRinging = false;
        });
        _navigateToTranscript();
      } else if (type == 'alarmDismissed' || type == 'customAudioStopped') {
        setState(() {
          _isRinging = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAlarmLaunch();
    }
  }

  Future<void> _checkAlarmLaunch() async {
    try {
      final launchData = await _platformClient.consumeAlarmLaunch();
      final launched = launchData['launchedFromAlarm'] as bool? ?? false;
      if (launched) {
        if (!_isTranscriptPageOpen) {
          _navigateToTranscript();
        }
        return;
      }
    } catch (_) {}
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final state = await _platformClient.getPlaybackState();
      final status = state['state'] as String?;
      if (status == 'customAudioPlaying') {
        _navigateToTranscript();
      } else if (status == 'ringing') {
        _navigateToRingingPage(alarmId: state['alarmId'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _checkNotificationPermission() async {
    final granted = await _platformClient.hasNotificationPermission();
    if (mounted) {
      setState(() {
        _hasNotificationPermission = granted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    await _platformClient.requestNotificationPermission();
    await Future.delayed(const Duration(seconds: 1));
    await _checkNotificationPermission();
  }

  void _navigateToTranscript() async {
    if (_isTranscriptPageOpen) return;
    if (_isRingingPageOpen) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      _isRingingPageOpen = false;
    }
    _isTranscriptPageOpen = true;
    await Navigator.of(context).push(
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

  void _navigateToRingingPage({String? alarmId}) async {
    if (_isRingingPageOpen || _isTranscriptPageOpen) return;
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

  void _dismissCurrentAlarm() {
    _platformClient.dismissAlarm();
    setState(() {
      _isRinging = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Alarm dismissed')));
  }

  void _stopRingtoneAndPlayAudio() {
    _platformClient.stopAlarm(audioTrackId: 'morning_message');
    setState(() {
      _isRinging = false;
    });
    _navigateToTranscript();
  }

  void _toggleAlarm(Alarm alarm) {
    if (!_hasNotificationPermission) {
      _requestNotificationPermission();
    }

    final updated = Alarm(
      id: alarm.id,
      enabled: !alarm.enabled,
      time: alarm.time,
      audioTrackId: alarm.audioTrackId,
      ringtoneId: alarm.ringtoneId,
      label: alarm.label,
    );

    setState(() {
      final index = _alarms.indexWhere((a) => a.id == alarm.id);
      if (index != -1) {
        _alarms[index] = updated;
      }
    });

    if (updated.enabled) {
      _platformClient.scheduleAlarm({
        'alarmId': updated.id,
        'timeMs': updated.time.millisecondsSinceEpoch,
        'audioTrackId': updated.audioTrackId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm set for ${_formatTime(updated.time)}'),
          backgroundColor: const Color(0xFF7C4DFF),
        ),
      );
    } else {
      _platformClient.cancelAlarm(updated.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alarm cancelled')));
    }
  }

  Future<void> _createNewAlarm() async {
    if (!_hasNotificationPermission) {
      await _requestNotificationPermission();
      if (!mounted) return;
    }

    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(context: context, initialTime: now);

    if (pickedTime == null) return;

    final nowDt = DateTime.now();
    var scheduledDt = DateTime(
      nowDt.year,
      nowDt.month,
      nowDt.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (scheduledDt.isBefore(nowDt)) {
      scheduledDt = scheduledDt.add(const Duration(days: 1));
    }

    final newAlarm = Alarm(
      id: 'alarm_${DateTime.now().millisecondsSinceEpoch}',
      enabled: true,
      time: scheduledDt,
      audioTrackId: 'morning_message',
      ringtoneId: 'default',
      label: 'New Alarm',
    );

    setState(() {
      _alarms.add(newAlarm);
    });

    _platformClient.scheduleAlarm({
      'alarmId': newAlarm.id,
      'timeMs': newAlarm.time.millisecondsSinceEpoch,
      'audioTrackId': newAlarm.audioTrackId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm scheduled for ${_formatTime(newAlarm.time)}'),
          backgroundColor: const Color(0xFF7C4DFF),
        ),
      );
    }
  }

  void _scheduleQuickTestAlarm() async {
    if (!_hasNotificationPermission) {
      await _requestNotificationPermission();
      if (!mounted) return;
    }

    final triggerTime = DateTime.now().add(const Duration(seconds: 5));
    final testAlarm = Alarm(
      id: 'quick_test_${DateTime.now().millisecondsSinceEpoch}',
      enabled: true,
      time: triggerTime,
      audioTrackId: 'morning_message',
      ringtoneId: 'default',
      label: '5-Second Test Alarm',
    );

    _platformClient.scheduleAlarm({
      'alarmId': testAlarm.id,
      'timeMs': triggerTime.millisecondsSinceEpoch,
      'audioTrackId': testAlarm.audioTrackId,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quick test alarm triggers in 5s! Notification will appear with Dismiss and Play buttons.',
          ),
          backgroundColor: Color(0xFF7C4DFF),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    _platformClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        title: const Text(
          'Native Alarms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note, color: Color(0xFF7C4DFF)),
            tooltip: 'Synchronized Transcript',
            onPressed: _navigateToTranscript,
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewAlarm),
        ],
      ),
      body: Column(
        children: [
          // Alarm Ringing Alert Banner (when active)
          if (_isRinging)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.alarm_on, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Alarm Ringing!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The alarm is actively ringing. You can dismiss it completely or start your custom audio message.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _dismissCurrentAlarm,
                        child: const Text('DISMISS'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _stopRingtoneAndPlayAudio,
                        child: const Text(
                          'PLAY AUDIO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Permission Warning Banner
          if (!_hasNotificationPermission)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_off,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notifications are disabled. Enable them to show alarm controls in notification center.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestNotificationPermission,
                    child: const Text(
                      'ENABLE',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Quick test card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1958), Color(0xFF1F1B3E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on, color: Color(0xFFBB86FC)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Native Alarm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Triggers in 5s with notification & controls',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _scheduleQuickTestAlarm,
                  child: const Text('Test (5s)'),
                ),
              ],
            ),
          ),

          // Alarm List
          Expanded(
            child: ListView.builder(
              itemCount: _alarms.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return Dismissible(
                  key: Key(alarm.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    _platformClient.cancelAlarm(alarm.id);
                    setState(() {
                      _alarms.removeAt(index);
                    });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    color: const Color(0xFF1E1E2C),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: alarm.enabled
                            ? const Color(0xFF7C4DFF).withValues(alpha: 0.5)
                            : Colors.white10,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      title: Text(
                        _formatTime(alarm.time),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: alarm.enabled ? Colors.white : Colors.white38,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              alarm.label ?? 'Alarm',
                              style: TextStyle(
                                color: alarm.enabled
                                    ? Colors.white70
                                    : Colors.white24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(color: Colors.white24),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.music_note,
                              size: 14,
                              color: Color(0xFFBB86FC),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Morning Motivation',
                              style: TextStyle(
                                color: Color(0xFFBB86FC),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Switch(
                        value: alarm.enabled,
                        thumbColor: const WidgetStatePropertyAll(
                          Color(0xFF7C4DFF),
                        ),
                        onChanged: (_) => _toggleAlarm(alarm),
                      ),
                      onTap: _navigateToTranscript,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.record_voice_over),
        label: const Text('Live Transcript'),
        onPressed: _navigateToTranscript,
      ),
    );
  }
}
