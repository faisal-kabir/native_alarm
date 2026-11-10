import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/platform/alarm_platform_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../main.dart';
import '../../data/audio_track_repository.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/repositories/alarm_scheduler.dart';
import 'synchronized_transcript_page.dart';

/// iOS only: the app's own ringing screen, shown when the app is opened while an alarm
/// rings (Android shows its native alarm screen). The clock and date, the alarm's
/// text, "Snooze" (rings again in [AppConstant.snoozeMinutes], through the one alarm
/// helper) and "Stop" (stops the ring and plays the message). Leaves for the message
/// page when the message starts, and goes home when the alarm is dismissed.
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
  late DateTime _now = DateTime.now();
  late final Timer _clock;
  StreamSubscription<Map<String, dynamic>>? _events;
  bool _isNavigating = false;

  AudioTrack get _track =>
      widget.audioTrack ?? AudioTrackRepository.predefinedTracks.first;

  @override
  void initState() {
    super.initState();
    // The clock shows minutes: a redraw when the minute changes is enough.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (mounted && now.minute != _now.minute) setState(() => _now = now);
    });

    // The message may already be playing.
    widget.platformClient.getPlaybackState().then((state) {
      if (mounted && state['state'] == 'customAudioPlaying') {
        _navigateToTranscript();
      }
    });

    _events = widget.platformClient.events.listen((event) {
      final type = event['event'] as String?;
      if (type == 'customAudioStarted' || type == 'openTranscript') {
        _navigateToTranscript();
      } else if (type == 'alarmDismissed') {
        _leave();
      }
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _events?.cancel();
    super.dispose();
  }

  /// Back to where it was opened from; never a second home page (each one listens to
  /// alarm events and would navigate again).
  void _leave() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go(RouteNames.dashboardPath);
    }
  }

  void _navigateToTranscript() {
    if (!mounted || _isNavigating || SynchronizedTranscriptPage.isOpen) return;
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/transcript'),
        builder: (_) => SynchronizedTranscriptPage(
          platformClient: widget.platformClient,
          initialTrack: _track,
        ),
      ),
    );
  }

  /// Stops the ring and plays the message at once.
  void _onStop() {
    widget.platformClient.stopAlarm(audioTrackId: _track.id);
    _navigateToTranscript();
  }

  void _onSnooze() {
    final strings = appLanguage(context);
    const minutes = AppConstant.snoozeMinutes;
    instance<AlarmScheduler>().snooze(
      widget.alarmId ?? 'ringing',
      at: DateTime.now().add(const Duration(minutes: minutes)),
      title: widget.label ?? '',
    );
    widget.platformClient.dismissAlarm();
    final messenger = ScaffoldMessenger.of(context);
    _leave();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.alarm_ringing_snoozed(minutes)),
        backgroundColor: AppColor.snooze,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final clock = '$hour:${_now.minute.toString().padLeft(2, '0')}';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColor.ringingSkyTop,
                AppColor.ringingSkyUpper,
                AppColor.ringingSkyLower,
                AppColor.ringingSkyBottom,
              ],
            ),
          ),
          child: SizedBox.expand(
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  Text(
                    clock,
                    style: textTheme.headlineLarge!.copyWith(
                      fontSize: 78.spMin,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1.5,
                      color: AppColor.white,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    DateFormat('EEEE, MMMM d', locale).format(_now),
                    style: textTheme.bodyLarge!.copyWith(
                      fontSize: 18.spMin,
                      letterSpacing: 0.2,
                      color: AppColor.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(flex: 2),
                  Text(
                    widget.label ?? strings.alarm_ringing_fallback_title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium!.copyWith(
                      fontSize: 32.spMin,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: AppColor.white,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Padding(
                    padding: REdgeInsets.symmetric(horizontal: 48),
                    child: _Pill(
                      label: strings.alarm_ringing_snooze(
                        AppConstant.snoozeMinutes,
                      ),
                      fill: AppColor.snooze,
                      ink: AppColor.white,
                      height: 54,
                      onTap: _onSnooze,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: REdgeInsets.only(bottom: 48),
                    child: SizedBox(
                      width: 170.w,
                      child: _Pill(
                        label: strings.alarm_ringing_stop,
                        fill: AppColor.white,
                        ink: AppColor.stopInk,
                        height: 56,
                        raised: true,
                        onTap: _onStop,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width pill button of the ringing screen ([height] before scaling).
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fill,
    required this.ink,
    required this.height,
    required this.onTap,
    this.raised = false,
  });

  final String label;
  final Color fill;
  final Color ink;
  final double height;
  final bool raised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: ink,
          elevation: raised ? 3 : 0,
          shadowColor: AppColor.scrim,
          shape: const StadiumBorder(),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: appTheme(context).textTheme.titleMedium!.copyWith(
            fontSize: 18.spMin,
            fontWeight: Dimension.textSemiBold,
            letterSpacing: 0.2,
            color: ink,
          ),
        ),
      ),
    );
  }
}
