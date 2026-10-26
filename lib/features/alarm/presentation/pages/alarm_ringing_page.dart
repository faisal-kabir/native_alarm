import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/platform/alarm_platform_client.dart';
import '../../data/audio_track_repository.dart';
import '../../domain/entities/audio_track.dart';
import 'synchronized_transcript_page.dart';
import 'alarm_list_page.dart';

class AlarmRingingPage extends StatefulWidget {
  final AlarmPlatformClient platformClient;
  final String? alarmId;
  final String? label;
  final AudioTrack? audioTrack;

  const AlarmRingingPage({
    super.key,
    required this.platformClient,
    this.alarmId,
    this.label,
    this.audioTrack,
  });

  @override
  State<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends State<AlarmRingingPage> {
  late DateTime _currentTime;
  Timer? _clockTimer;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Check if custom audio is already playing on mount
    widget.platformClient.getPlaybackState().then((state) {
      if (!mounted) return;
      if (state['state'] == 'customAudioPlaying') {
        _navigateToTranscript();
      }
    });

    _eventSubscription = widget.platformClient.events.listen((event) {
      final type = event['event'] as String?;
      if (type == 'customAudioStarted' || type == 'openTranscript') {
        _navigateToTranscript();
      } else if (type == 'alarmDismissed') {
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AlarmListPage()),
            );
          }
        }
      }
    });
  }

  bool _isNavigating = false;

  void _navigateToTranscript() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/transcript'),
        builder: (_) => SynchronizedTranscriptPage(
          platformClient: widget.platformClient,
          initialTrack: widget.audioTrack ?? AudioTrackRepository.predefinedTracks.first,
        ),
      ),
    );
  }

  void _onStopPressed() {
    // 1. Stop ringtone and immediately play custom audio
    final track = widget.audioTrack ?? AudioTrackRepository.predefinedTracks.first;
    widget.platformClient.stopAlarm(audioTrackId: track.id);
    _navigateToTranscript();
  }

  void _onSnoozePressed() {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    widget.platformClient.scheduleAlarm({
      'alarmId': 'snooze_${DateTime.now().millisecondsSinceEpoch}',
      'timeMs': snoozeTime.millisecondsSinceEpoch,
      'audioTrackId': widget.audioTrack?.id ?? 'morning_message',
    });
    widget.platformClient.dismissAlarm();
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AlarmListPage()),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm snoozed for 5 minutes'),
          backgroundColor: Color(0xFF1FB247),
        ),
      );
    }
  }

  String _formatClock(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, $month ${dt.day}';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2869D9),
              Color(0xFF5D94E6),
              Color(0xFF90B9ED),
              Color(0xFFBDD7F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Digital Clock
              Text(
                _formatClock(_currentTime),
                style: const TextStyle(
                  fontSize: 78,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 12),

              // Date
              Text(
                _formatDate(_currentTime),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 2),

              // Alarm Title
              Text(
                widget.label ?? 'Alarm',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 24),

              // Snooze Button (Green pill matching screenshot)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FB247),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _onSnoozePressed,
                    child: const Text(
                      'Snooze for 5 min',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Stop Button (White pill matching screenshot)
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  width: 170,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E1E1E),
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _onStopPressed,
                    child: const Text(
                      'Stop',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
