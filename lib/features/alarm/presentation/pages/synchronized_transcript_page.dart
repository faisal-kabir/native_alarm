import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/platform/alarm_platform_client.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/back_chevron.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../data/audio_track_repository.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/entities/transcript_word.dart';

/// The message after an alarm: the words light up one by one as the native player
/// speaks them (tap a word, or drag the bar, to jump there). The player runs natively,
/// so it keeps playing with the screen locked; this page only shows where it is.
///
/// The native side sends the position every 100 ms while playing, so the page reads
/// the player's state once on open and on resume, and otherwise only listens. Each
/// tick moves the bar; the transcript redraws only when the spoken word changes.
class SynchronizedTranscriptPage extends StatefulWidget {
  final AudioTrack? initialTrack;
  final AlarmPlatformClient platformClient;

  const SynchronizedTranscriptPage({
    super.key,
    this.initialTrack,
    required this.platformClient,
  });

  /// Number of message pages currently on the navigator stack. Every navigation source
  /// (native events, alarm launch, resume) checks this so the page is never pushed twice.
  static int openCount = 0;
  static bool get isOpen => openCount > 0;

  @override
  State<SynchronizedTranscriptPage> createState() =>
      _SynchronizedTranscriptPageState();
}

/// What the native player is doing.
enum _Playback { idle, ringing, playing, paused }

_Playback _playbackOf(String? state) => switch (state) {
  'ringing' => _Playback.ringing,
  'customAudioPlaying' => _Playback.playing,
  'customAudioPaused' => _Playback.paused,
  _ => _Playback.idle,
};

class _SynchronizedTranscriptPageState extends State<SynchronizedTranscriptPage>
    with WidgetsBindingObserver {
  late final AudioTrack _track =
      widget.initialTrack ?? AudioTrackRepository.predefinedTracks.first;
  Transcript? _transcript;
  bool _loadFailed = false;
  _Playback _playback = _Playback.idle;
  int _durationMs = 0;

  /// Where the player is (ms), and the word being spoken (-1 for none).
  final ValueNotifier<int> _position = ValueNotifier(0);
  final ValueNotifier<int> _activeWord = ValueNotifier(-1);

  StreamSubscription<Map<String, dynamic>>? _events;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _wordKeys = {};

  AlarmPlatformClient get _player => widget.platformClient;

  @override
  void initState() {
    super.initState();
    SynchronizedTranscriptPage.openCount++;
    WidgetsBinding.instance.addObserver(this);
    _loadTranscript();
    _readPlayer();
    _listen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _readPlayer();
      _listen();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _events?.cancel();
      _events = null;
    }
  }

  @override
  void dispose() {
    SynchronizedTranscriptPage.openCount--;
    WidgetsBinding.instance.removeObserver(this);
    _events?.cancel();
    // Leaving the message page ends the message, so nothing keeps playing in the
    // background and re-opens this page.
    if (_playback == _Playback.playing || _playback == _Playback.paused) {
      _player.stopCustomAudio();
    }
    _position.dispose();
    _activeWord.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadTranscript() async {
    try {
      final transcript = await AudioTrackRepository.loadTranscript(
        _track.transcriptPath,
      );
      if (!mounted) return;
      setState(() {
        _transcript = transcript;
        if (_durationMs == 0 && transcript.words.isNotEmpty) {
          _durationMs = transcript.words.last.endMs;
        }
      });
      _moveTo(_position.value);
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  /// The player's state now (on open and on resume; events keep it current after).
  Future<void> _readPlayer() async {
    final Map<String, dynamic> state;
    try {
      state = await _player.getPlaybackState();
    } on Object {
      return;
    }
    if (!mounted) return;
    _update(
      _playbackOf(state['state'] as String?),
      position: (state['positionMs'] as num?)?.toInt() ?? 0,
      duration: (state['durationMs'] as num?)?.toInt(),
    );
  }

  void _listen() {
    _events ??= _player.events.listen((event) {
      if (!mounted) return;
      final position = (event['positionMs'] as num?)?.toInt();
      final duration = (event['durationMs'] as num?)?.toInt();
      switch (event['event'] as String?) {
        case 'positionUpdate':
          _update(_Playback.playing, position: position, duration: duration);
        case 'customAudioStarted':
          _update(_Playback.playing, position: 0, duration: duration);
        case 'customAudioPaused':
          _update(_Playback.paused, position: position);
        case 'customAudioResumed':
          _update(_Playback.playing);
        case 'alarmDismissed' || 'customAudioStopped' || 'customAudioCompleted':
          _update(_Playback.idle, position: 0);
        case 'alarmRinging':
          _update(_Playback.ringing);
      }
    });
  }

  /// Redraws the page only when the playback or the length changed; a new position
  /// moves just the bar (and the transcript when the word changes).
  void _update(_Playback playback, {int? position, int? duration}) {
    final length = duration != null && duration > 0 ? duration : _durationMs;
    if (playback != _playback || length != _durationMs) {
      setState(() {
        _playback = playback;
        _durationMs = length;
      });
    }
    if (position != null) _moveTo(position);
  }

  void _moveTo(int positionMs) {
    _position.value = positionMs;
    final index = _wordAt(_transcript?.words ?? const [], positionMs);
    if (index == _activeWord.value) return;
    _activeWord.value = index;
    final word = _wordKeys[index]?.currentContext;
    if (word != null) {
      Scrollable.ensureVisible(
        word,
        duration: const Duration(milliseconds: 150),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    }
  }

  /// The word spoken at [posMs] (the last one started when between words), or -1.
  int _wordAt(List<TranscriptWord> words, int posMs) {
    var low = 0;
    var high = words.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final w = words[mid];
      if (posMs >= w.startMs && posMs <= w.endMs) return mid;
      if (posMs < w.startMs) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return high >= 0 && posMs >= words[high].startMs ? high : -1;
  }

  void _seek(int ms) {
    _player.seekCustomAudio(ms);
    // While paused no position comes back, so the page moves at once.
    _moveTo(ms);
  }

  void _playOrPause() {
    switch (_playback) {
      case _Playback.playing:
        _player.pauseCustomAudio();
      case _Playback.paused:
        _player.resumeCustomAudio();
      case _Playback.idle || _Playback.ringing:
        _player.startCustomAudio(_track.id);
    }
  }

  void _replay() {
    _seek(0);
    _player.startCustomAudio(_track.id);
  }

  /// Back to where it was opened from; never a second home page (each one listens to
  /// alarm events and would navigate again).
  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go(RouteNames.dashboardPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final transcript = _transcript;
    final Widget body;
    if (_loadFailed) {
      body = Center(
        child: Text(
          strings.message_load_failed,
          style: textTheme.bodyLarge!.copyWith(color: AppColor.danger),
        ),
      );
    } else if (transcript == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Column(
        children: [
          if (_playback == _Playback.ringing)
            _RingingBanner(
              onDismiss: _player.dismissAlarm,
              onPlay: () => _player.stopAlarm(audioTrackId: _track.id),
            ),
          _StatusPill(playback: _playback),
          if (_playback == _Playback.idle || _playback == _Playback.paused)
            _PlayPrompt(onTap: _playOrPause),
          Expanded(
            child: _TranscriptCard(
              words: transcript.words,
              activeWord: _activeWord,
              wordKeys: _wordKeys,
              scroll: _scroll,
              onWordTap: _seek,
            ),
          ),
          _ProgressBar(
            position: _position,
            durationMs: _durationMs,
            onSeek: _seek,
          ),
          _Controls(
            playing: _playback == _Playback.playing,
            onReplay: _replay,
            onPlayPause: _playOrPause,
            onStop: _player.dismissAlarm,
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 50.h,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: strings.common_back,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _back,
                      child: SizedBox.square(
                        dimension: 48.r,
                        child: Center(
                          child: BackChevron(size: 22.r, color: AppColor.white),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium!.copyWith(
                        fontSize: 17.spMin,
                        fontWeight: Dimension.textSemiBold,
                        color: AppColor.titleColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 48.r),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Shown while the alarm still rings: dismiss it, or stop it and play the message.
class _RingingBanner extends StatelessWidget {
  const _RingingBanner({required this.onDismiss, required this.onPlay});

  final VoidCallback onDismiss;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.r),
    );
    return Container(
      width: double.infinity,
      margin: REdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.danger,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSvgIcon(Assets.icons.alarm, size: 26.r, color: AppColor.white),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  strings.message_ringing_title,
                  style: textTheme.titleMedium!.copyWith(
                    fontSize: 16.spMin,
                    fontWeight: FontWeight.bold,
                    color: AppColor.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            strings.message_ringing_body,
            style: textTheme.bodyMedium!.copyWith(
              fontSize: 13.spMin,
              color: AppColor.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.white,
                  side: BorderSide(
                    color: AppColor.white.withValues(alpha: 0.55),
                  ),
                  shape: shape,
                ),
                onPressed: onDismiss,
                child: Text(strings.message_dismiss),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.white,
                  foregroundColor: AppColor.danger,
                  shape: shape,
                ),
                onPressed: onPlay,
                child: Text(
                  strings.message_play,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What the player is doing, as a small pill.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.playback});

  final _Playback playback;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final (label, color) = switch (playback) {
      _Playback.playing => (strings.message_status_playing, AppColor.success),
      _Playback.ringing => (strings.message_ringing_title, AppColor.danger),
      _Playback.paused => (strings.message_status_paused, AppColor.primary),
      _Playback.idle => (strings.message_status_ready, AppColor.primary),
    };
    return Container(
      margin: REdgeInsets.symmetric(vertical: 8),
      padding: REdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: appTheme(context).textTheme.labelMedium!.copyWith(
          fontSize: 12.spMin,
          fontWeight: Dimension.textSemiBold,
          color: color,
        ),
      ),
    );
  }
}

/// "Tap to play message", while nothing plays.
class _PlayPrompt extends StatelessWidget {
  const _PlayPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: REdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.2),
            borderRadius: radius,
            border: Border.all(color: AppColor.primary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(
                Assets.icons.voice.play,
                size: 20.r,
                color: AppColor.white,
              ),
              SizedBox(width: 8.w),
              Text(
                appLanguage(context).message_tap_to_play,
                style: appTheme(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.spMin,
                  fontWeight: FontWeight.bold,
                  color: AppColor.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The message's words; the spoken one filled, the ones before it brighter than the
/// ones still to come. Redraws only when [activeWord] changes.
class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.words,
    required this.activeWord,
    required this.wordKeys,
    required this.scroll,
    required this.onWordTap,
  });

  final List<TranscriptWord> words;
  final ValueNotifier<int> activeWord;
  final Map<int, GlobalKey> wordKeys;
  final ScrollController scroll;
  final ValueChanged<int> onWordTap;

  @override
  Widget build(BuildContext context) {
    final style = appTheme(context).textTheme.bodyLarge!
        .copyWith(fontSize: 20.spMin);
    return Container(
      margin: REdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: REdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: SingleChildScrollView(
        controller: scroll,
        child: ValueListenableBuilder<int>(
          valueListenable: activeWord,
          builder: (context, active, _) => Wrap(
            spacing: 8.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < words.length; i++)
                GestureDetector(
                  key: wordKeys.putIfAbsent(i, GlobalKey.new),
                  onTap: () => onWordTap(words[i].startMs),
                  // Only the colours change, so the words never move.
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: REdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: i == active
                          ? AppColor.primary
                          : AppColor.primary.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      words[i].text,
                      style: style.copyWith(
                        color: i == active
                            ? AppColor.onPrimary
                            : active != -1 && i < active
                            ? AppColor.textColor
                            : AppColor.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The position bar and its times. Dragging moves only the bar; the player seeks
/// once, where the drag ends.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.position,
    required this.durationMs,
    required this.onSeek,
  });

  final ValueNotifier<int> position;
  final int durationMs;
  final ValueChanged<int> onSeek;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragging;

  static String _time(int ms) {
    final seconds = ms ~/ 1000;
    final tenths = (ms % 1000) ~/ 100;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.durationMs > 0 ? widget.durationMs.toDouble() : 1.0;
    final timeStyle = appTheme(context).textTheme.labelMedium!
        .copyWith(fontSize: 12.spMin, color: AppColor.textTertiary);
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 24),
      child: ValueListenableBuilder<int>(
        valueListenable: widget.position,
        builder: (context, position, _) {
          final value = _dragging ?? position.clamp(0, max).toDouble();
          return Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColor.primary,
                  inactiveTrackColor: AppColor.progressTrack,
                  thumbColor: AppColor.white,
                  trackHeight: 4.h,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                ),
                child: Slider(
                  value: value,
                  max: max,
                  onChanged: (v) => setState(() => _dragging = v),
                  onChangeEnd: (v) {
                    setState(() => _dragging = null);
                    widget.onSeek(v.toInt());
                  },
                ),
              ),
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_time(value.toInt()), style: timeStyle),
                    Text(_time(widget.durationMs), style: timeStyle),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Replay, play / pause and stop.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.playing,
    required this.onReplay,
    required this.onPlayPause,
    required this.onStop,
  });

  final bool playing;
  final VoidCallback onReplay;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final side = AppColor.textSecondary;
    return Padding(
      padding: REdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onReplay,
            icon: AppSvgIcon(
              Assets.icons.voice.replay,
              size: 28.r,
              color: side,
            ),
          ),
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 72.r,
              height: 72.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primary,
              ),
              child: AppSvgIcon(
                playing ? Assets.icons.voice.pause : Assets.icons.voice.play,
                size: 36.r,
                color: AppColor.onPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onStop,
            icon: AppSvgIcon(Assets.icons.voice.stop, size: 28.r, color: side),
          ),
        ],
      ),
    );
  }
}
