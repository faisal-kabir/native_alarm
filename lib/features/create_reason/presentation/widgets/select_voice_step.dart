import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/audio/sample_player.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/select_list_skeleton.dart';
import '../../../../core/widgets/sliding_border.dart';
import '../../../../main.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/domain/entities/voice_group.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import 'step_message.dart';
import 'voice_row.dart';

/// Step 3 of Create Reason: "Who should say it?".
///
/// The voices (loaded and cached when the page opened) under their group headings
/// (`voice.group`, joined from `voice_group` on the server). One selection border glides
/// between rows, across the headings too. The play button plays the voice's sample
/// (and chooses that voice: hearing one is how you decide); only one plays at a time
/// and it stops when the step is left.
class SelectVoiceStep extends StatefulWidget {
  const SelectVoiceStep({super.key});

  @override
  State<SelectVoiceStep> createState() => _SelectVoiceStepState();
}

class _SelectVoiceStepState extends State<SelectVoiceStep> {
  late final CreateReasonBloc _bloc = context.read<CreateReasonBloc>();
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

  void _setPlaying(int? id) {
    if (mounted && _playingId != id) setState(() => _playingId = id);
  }

  Future<void> _togglePlay(Voice voice) async {
    _bloc.add(VoiceSelectedEvent(voice.id));
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
  void dispose() {
    _done.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.voices != b.voices ||
          a.voicesStatus != b.voicesStatus ||
          a.selectedVoiceId != b.selectedVoiceId,
      builder: (context, state) {
        final Widget content;
        if (state.voices.isNotEmpty) {
          content = SlidingBorderScope(
            selectedId: state.selectedVoiceId,
            child: _VoiceGroups(
              voices: state.voices,
              selectedId: state.selectedVoiceId,
              playingId: _playingId,
              onSelect: (v) => _bloc.add(VoiceSelectedEvent(v.id)),
              onPlay: _togglePlay,
            ),
          );
        } else {
          content = switch (state.voicesStatus) {
            LoadStatus.loading => const SelectListSkeleton(count: 4),
            LoadStatus.failed => StepMessage(
              text: strings.create_reason_areas_error,
              actionLabel: strings.common_try_again,
              onAction: () => _bloc.add(const RefreshVoicesEvent()),
            ),
            LoadStatus.loaded => StepMessage(
              text: strings.create_reason_areas_empty,
            ),
          };
        }
        return SingleChildScrollView(
          padding: REdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HighlightedTitle(strings.create_reason_voice_title, fontSize: 32),
              SizedBox(height: 12.h),
              content,
            ],
          ),
        );
      },
    );
  }
}

/// The voices under their group headings, groups in id order (voices without a group
/// last, with no heading).
class _VoiceGroups extends StatelessWidget {
  const _VoiceGroups({
    required this.voices,
    required this.selectedId,
    required this.playingId,
    required this.onSelect,
    required this.onPlay,
  });

  final List<Voice> voices;
  final int? selectedId;
  final int? playingId;
  final ValueChanged<Voice> onSelect;
  final ValueChanged<Voice> onPlay;

  @override
  Widget build(BuildContext context) {
    final groups = <int?, List<Voice>>{};
    for (final voice in voices) {
      groups.putIfAbsent(voice.group?.id, () => []).add(voice);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) => (a ?? 1 << 62).compareTo(b ?? 1 << 62));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var gi = 0; gi < keys.length; gi++) ...[
          if (gi > 0) SizedBox(height: 20.h),
          _GroupBlock(
            group: groups[keys[gi]]!.first.group,
            voices: groups[keys[gi]]!,
            delay: Duration(milliseconds: 80 + gi * 80),
            selectedId: selectedId,
            playingId: playingId,
            onSelect: onSelect,
            onPlay: onPlay,
          ),
        ],
      ],
    );
  }
}

class _GroupBlock extends StatelessWidget {
  const _GroupBlock({
    required this.group,
    required this.voices,
    required this.delay,
    required this.selectedId,
    required this.playingId,
    required this.onSelect,
    required this.onPlay,
  });

  final VoiceGroup? group;
  final List<Voice> voices;
  final Duration delay;
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
                      delay: delay + Duration(milliseconds: 40 + i * 30),
                      dy: 10,
                      child: VoiceRow(
                        voice: voices[i],
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
