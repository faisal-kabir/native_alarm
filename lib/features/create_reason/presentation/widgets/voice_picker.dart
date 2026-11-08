import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/audio/sample_player.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/sliding_border.dart';
import '../../../../main.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/domain/entities/voice_group.dart';
import 'voice_row.dart';

/// The voices to choose from: under their group headings (groups in id order, voices
/// without a group last), one selection border gliding between rows (across the
/// headings too), and each row's sample button.
///
/// It plays the samples itself (one at a time, with its own `SamplePlayer`, stopped
/// and released when it goes away). Playing a voice also chooses it: hearing one is how
/// you decide. Used by the Create Reason voice step and the voice sheet of a reason.
class VoicePicker extends StatefulWidget {
  const VoicePicker({
    super.key,
    required this.voices,
    required this.selectedId,
    required this.onSelect,
    this.rowColor = AppColor.cardColor,
    this.animateIn = true,
  });

  final List<Voice> voices;
  final int? selectedId;
  final ValueChanged<Voice> onSelect;

  /// The cards' fill (`AppColor.surfaceSecondary` inside a sheet).
  final Color rowColor;

  /// Rows and headings rise in when they first appear (off in a sheet).
  final bool animateIn;

  @override
  State<VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends State<VoicePicker> {
  final SamplePlayer _player = instance<SamplePlayer>();
  late final StreamSubscription<void> _done;

  int? _playingId;

  // Bumped on every play / stop, so a slow load that finishes late is ignored.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _done = _player.onComplete.listen((_) => _setPlaying(null));
  }

  @override
  void dispose() {
    _done.cancel();
    _player.dispose();
    super.dispose();
  }

  void _setPlaying(int? id) {
    if (mounted && _playingId != id) setState(() => _playingId = id);
  }

  Future<void> _togglePlay(Voice voice) async {
    widget.onSelect(voice);
    final request = ++_request;
    if (_playingId == voice.id) {
      _setPlaying(null);
      await _player.stop();
      return;
    }
    final url = voice.audioUrl;
    if (url == null) return;
    _setPlaying(voice.id);
    try {
      await _player.play(url);
    } catch (_) {
      if (!mounted || request != _request) return;
      _setPlaying(null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLanguage(context).voice_play_failed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <int?, List<Voice>>{};
    for (final voice in widget.voices) {
      groups.putIfAbsent(voice.group?.id, () => []).add(voice);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => (a ?? 1 << 62).compareTo(b ?? 1 << 62));
    return SlidingBorderScope(
      selectedId: widget.selectedId,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var gi = 0; gi < keys.length; gi++) ...[
            if (gi > 0) SizedBox(height: 20.h),
            _GroupBlock(
              group: groups[keys[gi]]!.first.group,
              voices: groups[keys[gi]]!,
              delay: Duration(milliseconds: 80 + gi * 80),
              animateIn: widget.animateIn,
              rowColor: widget.rowColor,
              selectedId: widget.selectedId,
              playingId: _playingId,
              onSelect: widget.onSelect,
              onPlay: _togglePlay,
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupBlock extends StatelessWidget {
  const _GroupBlock({
    required this.group,
    required this.voices,
    required this.delay,
    required this.animateIn,
    required this.rowColor,
    required this.selectedId,
    required this.playingId,
    required this.onSelect,
    required this.onPlay,
  });

  final VoiceGroup? group;
  final List<Voice> voices;
  final Duration delay;
  final bool animateIn;
  final Color rowColor;
  final int? selectedId;
  final int? playingId;
  final ValueChanged<Voice> onSelect;
  final ValueChanged<Voice> onPlay;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    final group = this.group;
    return Semantics(
      container: true,
      label: group == null
          ? null
          : appLanguage(context).voice_group_semantics(group.title),
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (group != null)
            RiseIn(
              enabled: animateIn,
              delay: delay,
              dy: 10,
              child: Padding(
                padding: REdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        group.title,
                        style: textTheme.headlineSmall!.copyWith(
                          height: 23.5 / 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    if (group.description != null)
                      Expanded(
                        child: Text(
                          group.description!,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall!.copyWith(
                            fontSize: 13.spMin,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Inset 3 so the chosen border never touches the screen edge.
          Padding(
            padding: REdgeInsets.all(3),
            child: Column(
              children: [
                for (var i = 0; i < voices.length; i++) ...[
                  if (i > 0) SizedBox(height: 8.h),
                  // The target sits outside the rise-in transform, so the border is
                  // measured where the row rests.
                  SlidingBorderTarget(
                    id: voices[i].id,
                    child: RiseIn(
                      enabled: animateIn,
                      delay: delay + Duration(milliseconds: 40 + i * 30),
                      dy: 10,
                      child: VoiceRow(
                        voice: voices[i],
                        color: rowColor,
                        selected: voices[i].id == selectedId,
                        playing: voices[i].id == playingId,
                        onSelect: () => onSelect(voices[i]),
                        onPlay: () => onPlay(voices[i]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
