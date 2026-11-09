import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/audio/sample_player.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/media_url.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/add_card.dart';
import '../../../../core/widgets/animated_select_list.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/play_button.dart';
import '../../../../main.dart';
import '../../../alarm_audio/domain/entities/alarm_audio.dart';
import '../../../reasons/domain/entities/reason.dart';

// The alarm editor's three pickers, one look learned once: the app's choice rows
// (AnimatedSelectList: a tile in the row's colour, the name, a hint line; ONE orange
// border that glides to the chosen row) and one orange button that commits. Tapping a
// row only chooses.

/// What the Reason picker closed with.
sealed class ReasonPick {
  const ReasonPick();
}

/// A Reason was chosen.
class ReasonPicked extends ReasonPick {
  const ReasonPicked(this.id);

  final int id;
}

/// "New Reason" was tapped (the sheet has closed): open the reason maker.
class ReasonMakeRequested extends ReasonPick {
  const ReasonMakeRequested();
}

/// "What should wake you up?": [pickable] (the chosen one first, then the Reasons no
/// other alarm plays) and a last row "New Reason". "Select Reason" stays grey until the
/// choice is a change. [anyReasons] false: there are none at all yet.
Future<ReasonPick?> showReasonPicker(
  BuildContext context, {
  required List<Reason> pickable,
  required bool anyReasons,
  required int? selectedId,
}) => showAppSheet<ReasonPick>(
  context,
  builder: (_) => _ReasonPicker(
    pickable: pickable,
    anyReasons: anyReasons,
    selectedId: selectedId,
  ),
);

/// A Reason as a choice row: its area's icon and colour, "Area · Tone".
SelectItem reasonChoice(Reason reason) => SelectItem(
  id: reason.id,
  title: reason.name,
  subtitle: [
    reason.areaTitle,
    reason.toneTitle,
  ].where((s) => s.isNotEmpty).join(' · '),
  tint: AppColor.tintOf(reason.area?.color),
  iconPath: reason.area?.icon,
);

class _ReasonPicker extends StatefulWidget {
  const _ReasonPicker({
    required this.pickable,
    required this.anyReasons,
    required this.selectedId,
  });

  final List<Reason> pickable;
  final bool anyReasons;
  final int? selectedId;

  @override
  State<_ReasonPicker> createState() => _ReasonPickerState();
}

class _ReasonPickerState extends State<_ReasonPicker> {
  late int? _value = widget.selectedId;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final value = _value;
    final changed = value != null && value != widget.selectedId;
    final allTaken = widget.anyReasons && widget.pickable.isEmpty;
    return AppSheet(
      title: strings.reason_picker_title,
      subtitle: allTaken
          ? strings.reason_picker_all_taken
          : strings.reason_picker_subtitle,
      footer: widget.pickable.isEmpty
          ? null
          : PillButton(
              enabled: changed,
              disabledColor: AppColor.slotFree,
              label: strings.reason_picker_select,
              onPressed: () =>
                  AppSheetScope.of(context).close(ReasonPicked(value!)),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.anyReasons)
            Padding(
              padding: REdgeInsets.symmetric(vertical: 18),
              child: Text(
                strings.reason_picker_none,
                textAlign: TextAlign.center,
                style: appTheme(context).textTheme.bodyLarge!
                    .copyWith(color: AppColor.textSecondary),
              ),
            ),
          // Inset 3 so the chosen border never touches the sheet's edge.
          Padding(
            padding: REdgeInsets.all(3),
            child: AnimatedSelectList(
              items: [for (final r in widget.pickable) reasonChoice(r)],
              selectedId: value,
              animateIn: false,
              rowColor: AppColor.surfaceSecondary,
              onSelected: (item) {
                HapticFeedback.selectionClick();
                setState(() => _value = item.id as int);
              },
              footer: AddCard.row(
                label: strings.reason_picker_new,
                color: AppColor.surfaceSecondary,
                onTap: () =>
                    AppSheetScope.of(context)
                        .close(const ReasonMakeRequested()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A sound sheet ("Soundtrack" from `sound_track`, "Alarm sound" from `alarm_sound`),
/// read from the device. Each row with audio has a play button that plays its file
/// (the downloaded copy, so it works offline); a row with no audio ("None") is grey
/// and silent. With [playAlsoChooses] (soundtracks) playing a row also chooses it:
/// hearing one is how you decide; for the ring, play only plays. The button always
/// commits (keeping the choice is a fine answer). Returns the chosen id, or null when
/// dismissed. It owns its player, so nothing keeps sounding once it has closed.
Future<int?> showSoundSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String selectLabel,
  required List<AlarmAudio> options,
  required int? selectedId,
  required bool playAlsoChooses,
}) => showAppSheet<int>(
  context,
  builder: (_) => _SoundSheet(
    title: title,
    subtitle: subtitle,
    selectLabel: selectLabel,
    options: options,
    selectedId: selectedId,
    playAlsoChooses: playAlsoChooses,
  ),
);

class _SoundSheet extends StatefulWidget {
  const _SoundSheet({
    required this.title,
    required this.subtitle,
    required this.selectLabel,
    required this.options,
    required this.selectedId,
    required this.playAlsoChooses,
  });

  final String title;
  final String subtitle;
  final String selectLabel;
  final List<AlarmAudio> options;
  final int? selectedId;
  final bool playAlsoChooses;

  @override
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  final SamplePlayer _player = instance<SamplePlayer>();
  late final StreamSubscription<void> _done;
  late int? _value = widget.selectedId;
  int? _playingId;

  // Bumped on every play / stop, so a slow start that finishes late is ignored.
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

  Future<void> _togglePlay(AlarmAudio option) async {
    HapticFeedback.selectionClick();
    final request = ++_request;
    if (_playingId == option.id) {
      _setPlaying(null);
      await _player.stop();
      return;
    }
    if (widget.playAlsoChooses) setState(() => _value = option.id);
    _setPlaying(option.id);
    try {
      final file = option.audioFile;
      file != null
          ? await _player.playFile(file)
          // Not downloaded yet (first open, before the refresh finished).
          : await _player.play(mediaUrl(option.audio!));
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
    final strings = appLanguage(context);
    final byId = {for (final o in widget.options) o.id: o};
    return AppSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      footer: PillButton(
        enabled: true,
        label: widget.selectLabel,
        onPressed: () => AppSheetScope.of(context).close(_value),
      ),
      body: Padding(
        padding: REdgeInsets.all(3),
        child: AnimatedSelectList(
          items: [
            for (final o in widget.options)
              SelectItem(
                id: o.id,
                title: o.title,
                subtitle: o.description,
                // A silent row ("None") is grey.
                tint: o.audio == null
                    ? AppColor.textMuted
                    : AppColor.tintOf(o.color),
                iconPath: o.icon,
                iconFile: o.iconFile,
              ),
          ],
          selectedId: _value,
          animateIn: false,
          rowColor: AppColor.surfaceSecondary,
          onSelected: (item) {
            HapticFeedback.selectionClick();
            setState(() => _value = item.id as int);
          },
          markBuilder: (item, selected) {
            final option = byId[item.id]!;
            if (option.audio == null) return const SizedBox.shrink();
            final playing = _playingId == option.id;
            return PlayButton(
              label: playing
                  ? strings.voice_stop(option.title)
                  : strings.voice_play(option.title),
              filled: selected || playing,
              playing: playing,
              onTap: () => _togglePlay(option),
            );
          },
        ),
      ),
    );
  }
}
