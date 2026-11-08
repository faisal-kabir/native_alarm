import 'package:flutter/material.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../main.dart';
import '../../../create_reason/presentation/widgets/voice_picker.dart';
import '../../../voice/domain/entities/voice.dart';

/// "Choose a voice": the app's [VoicePicker] in a sheet (samples play; they stop when
/// the sheet goes away). Returns the chosen voice's id once it is a change, else null.
Future<int?> showVoiceSheet(
  BuildContext context, {
  required List<Voice> voices,
  required int selectedId,
}) => showAppSheet<int>(
  context,
  builder: (_) => _VoiceSheet(voices: voices, selectedId: selectedId),
);

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet({required this.voices, required this.selectedId});

  final List<Voice> voices;
  final int selectedId;

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  late int _value = widget.selectedId;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    Voice? chosen;
    for (final voice in widget.voices) {
      if (voice.id == _value) chosen = voice;
    }
    final changed = _value != widget.selectedId && chosen != null;
    return AppSheet(
      title: strings.reason_detail_voice_sheet,
      footer: PillButton(
        enabled: changed,
        disabledColor: AppColor.slotFree,
        label: changed
            ? strings.sheet_use_choice(chosen.name)
            : strings.reason_detail_keep_voice,
        onPressed: () => AppSheetScope.of(context).close(_value),
      ),
      body: VoicePicker(
        voices: widget.voices,
        selectedId: _value,
        animateIn: false,
        rowColor: AppColor.surfaceSecondary,
        onSelect: (voice) => setState(() => _value = voice.id),
      ),
    );
  }
}
