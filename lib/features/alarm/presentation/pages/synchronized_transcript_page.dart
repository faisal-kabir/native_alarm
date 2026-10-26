import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/platform/alarm_platform_client.dart';
import '../../data/audio_track_repository.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/transcript.dart';
import '../../domain/entities/transcript_word.dart';
import 'alarm_list_page.dart';

class SynchronizedTranscriptPage extends StatefulWidget {
  final AudioTrack? initialTrack;
  final AlarmPlatformClient platformClient;

  const SynchronizedTranscriptPage({
    super.key,
    this.initialTrack,
    required this.platformClient,
  });

  @override
  State<SynchronizedTranscriptPage> createState() =>
      _SynchronizedTranscriptPageState();
}

class _SynchronizedTranscriptPageState extends State<SynchronizedTranscriptPage>
    with WidgetsBindingObserver {
  late AudioTrack _track;
  Transcript? _transcript;
  bool _isLoading = true;
  String _errorMessage = '';

  int _currentPositionMs = 0;
  int _durationMs = 3556;
  String _playbackState =
      'idle'; // 'idle', 'ringing', 'customAudioPlaying', 'customAudioPaused'
  StreamSubscription? _eventSubscription;
  Timer? _pollTimer;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _wordKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _track = widget.initialTrack ?? AudioTrackRepository.predefinedTracks.first;
    _loadTranscript();
    _pollPlaybackState();
    _startListeningEvents();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollPlaybackState();
      _startListeningEvents();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _stopListeningEvents();
      _stopPolling();
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted) {
        _pollPlaybackState();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadTranscript() async {
    try {
      final transcript = await AudioTrackRepository.loadTranscript(
        _track.transcriptPath,
      );
      setState(() {
        _transcript = transcript;
        _isLoading = false;
        if (transcript.words.isNotEmpty) {
          _durationMs = transcript.words.last.endMs;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load transcript: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pollPlaybackState() async {
    try {
      final state = await widget.platformClient.getPlaybackState();
      if (mounted) {
        setState(() {
          _playbackState = state['state'] as String? ?? 'idle';
          _currentPositionMs = (state['positionMs'] as num?)?.toInt() ?? 0;
          final dur = (state['durationMs'] as num?)?.toInt() ?? 0;
          if (dur > 0) _durationMs = dur;
        });
      }
    } catch (_) {}
  }

  void _startListeningEvents() {
    if (_eventSubscription != null) return;
    _eventSubscription = widget.platformClient.events.listen((event) {
      if (!mounted) return;
      final type = event['event'] as String?;
      if (type == 'positionUpdate') {
        final pos =
            (event['positionMs'] as num?)?.toInt() ?? _currentPositionMs;
        final dur = (event['durationMs'] as num?)?.toInt() ?? _durationMs;
        setState(() {
          _currentPositionMs = pos;
          if (dur > 0) _durationMs = dur;
          _playbackState = 'customAudioPlaying';
        });
        _scrollToActiveWord();
      } else if (type == 'customAudioStarted') {
        final dur = (event['durationMs'] as num?)?.toInt() ?? _durationMs;
        setState(() {
          _playbackState = 'customAudioPlaying';
          _currentPositionMs = 0;
          if (dur > 0) _durationMs = dur;
        });
      } else if (type == 'customAudioPaused') {
        setState(() {
          _playbackState = 'customAudioPaused';
        });
      } else if (type == 'customAudioResumed') {
        setState(() {
          _playbackState = 'customAudioPlaying';
        });
      } else if (type == 'alarmDismissed' ||
          type == 'customAudioStopped' ||
          type == 'customAudioCompleted') {
        setState(() {
          _playbackState = 'idle';
          _currentPositionMs = 0;
        });
      } else if (type == 'alarmRinging') {
        setState(() {
          _playbackState = 'ringing';
        });
      }
    });
  }

  void _stopListeningEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  int _findActiveWordIndex(List<TranscriptWord> words, int posMs) {
    if (words.isEmpty) return -1;
    // Binary search for word containing posMs
    int low = 0;
    int high = words.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final w = words[mid];
      if (posMs >= w.startMs && posMs <= w.endMs) {
        return mid;
      } else if (posMs < w.startMs) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    // If between words or near end, find closest prior word
    if (high >= 0 && high < words.length && posMs >= words[high].startMs) {
      return high;
    }
    return -1;
  }

  void _scrollToActiveWord() {
    final words = _transcript?.words;
    if (words == null || words.isEmpty) return;
    final activeIndex = _findActiveWordIndex(words, _currentPositionMs);
    if (activeIndex != -1 && _wordKeys.containsKey(activeIndex)) {
      final keyContext = _wordKeys[activeIndex]?.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 150),
          alignment: 0.5,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _stopListeningEvents();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRinging = _playbackState == 'ringing';
    final isPlaying = _playbackState == 'customAudioPlaying';
    final words = _transcript?.words ?? [];
    final activeIndex = _findActiveWordIndex(words, _currentPositionMs);

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        title: Text(_track.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AlarmListPage()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Column(
              children: [
                // Alarm Ringing Banner
                if (isRinging)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose to play the motivational message or dismiss the alarm.',
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
                              onPressed: () =>
                                  widget.platformClient.dismissAlarm(),
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
                              onPressed: () => widget.platformClient.stopAlarm(
                                audioTrackId: _track.id,
                              ),
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

                // Status Pill
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Colors.green.withValues(alpha: 0.2)
                        : isRinging
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPlaying
                          ? Colors.greenAccent
                          : isRinging
                          ? Colors.redAccent
                          : Colors.purpleAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPlaying
                            ? Icons.graphic_eq
                            : isRinging
                            ? Icons.notifications_active
                            : Icons.music_note,
                        size: 16,
                        color: isPlaying
                            ? Colors.greenAccent
                            : Colors.purpleAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPlaying
                            ? 'Playing in background'
                            : isRinging
                            ? 'Alarm Ringing'
                            : _playbackState == 'customAudioPaused'
                            ? 'Paused'
                            : 'Ready',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPlaying
                              ? Colors.greenAccent
                              : Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Clear error / retry state if native playback is not running (Step 3.4)
                if (!isPlaying && !isRinging)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: InkWell(
                      onTap: () {
                        widget.platformClient.startCustomAudio(_track.id);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF7C4DFF)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tap to play message',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Transcript Card with Word-by-Word highlighting
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(words.length, (index) {
                          final word = words[index];
                          final isActive = index == activeIndex;
                          final isPast =
                              activeIndex != -1 && index < activeIndex;
                          final key = _wordKeys.putIfAbsent(
                            index,
                            () => GlobalKey(),
                          );

                          return GestureDetector(
                            key: key,
                            onTap: () {
                              // Seek directly to word start time
                              widget.platformClient.seekCustomAudio(
                                word.startMs,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF7C4DFF)
                                    : isPast
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF7C4DFF)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 12,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                word.text,
                                style: TextStyle(
                                  fontSize: isActive ? 22 : 20,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : isPast
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: isActive
                                      ? Colors.white
                                      : isPast
                                      ? Colors.white70
                                      : Colors.white38,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Audio Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF7C4DFF),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _currentPositionMs
                              .clamp(0, _durationMs)
                              .toDouble(),
                          min: 0,
                          max: _durationMs > 0 ? _durationMs.toDouble() : 1.0,
                          onChanged: (val) {
                            widget.platformClient.seekCustomAudio(val.toInt());
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatMs(_currentPositionMs),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatMs(_durationMs),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Controls Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Replay button
                      IconButton(
                        icon: const Icon(
                          Icons.replay,
                          color: Colors.white70,
                          size: 28,
                        ),
                        onPressed: () {
                          widget.platformClient.seekCustomAudio(0);
                          widget.platformClient.startCustomAudio(_track.id);
                        },
                      ),

                      // Play / Pause main button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C4DFF)
                                  .withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 42,
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (isPlaying) {
                              widget.platformClient.pauseCustomAudio();
                            } else if (_playbackState == 'customAudioPaused') {
                              widget.platformClient.resumeCustomAudio();
                            } else {
                              widget.platformClient.startCustomAudio(_track.id);
                            }
                          },
                        ),
                      ),

                      // Stop button
                      IconButton(
                        icon: const Icon(
                          Icons.stop,
                          color: Colors.white70,
                          size: 28,
                        ),
                        onPressed: () => widget.platformClient.dismissAlarm(),
                      ),
                    ],
                  ),
                ),

                // Demo Alarm Trigger Bar
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.alarm_add, size: 20),
                    label: const Text('Test Alarm Trigger in 5 Seconds'),
                    onPressed: () {
                      final triggerTime = DateTime.now().add(
                        const Duration(seconds: 5),
                      );
                      widget.platformClient.scheduleAlarm({
                        'alarmId':
                            'demo_alarm_${DateTime.now().millisecondsSinceEpoch}',
                        'timeMs': triggerTime.millisecondsSinceEpoch,
                        'audioTrackId': _track.id,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Alarm scheduled for 5 seconds from now. Lock phone to test background playback!',
                          ),
                          backgroundColor: Color(0xFF7C4DFF),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final tenths = (ms % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Word-by-Word Synchronized Audio',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This feature plays custom audio in a native foreground service (Android) / background audio session (iOS) so it continues playing even when the screen is locked.\n\nWhen you open the app, this page matches the exact playback timestamp from the native player to the transcript words using binary search.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
