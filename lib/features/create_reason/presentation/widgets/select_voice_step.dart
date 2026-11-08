import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/select_list_skeleton.dart';
import '../../../../main.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import 'step_message.dart';
import 'voice_picker.dart';

/// Step 3 of Create Reason: "Who should say it?": the voices (loaded and cached when
/// the page opened) in a [VoicePicker] (group headings, gliding border, samples that
/// stop when the step is left).
class SelectVoiceStep extends StatelessWidget {
  const SelectVoiceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.voices != b.voices ||
          a.voicesStatus != b.voicesStatus ||
          a.selectedVoiceId != b.selectedVoiceId,
      builder: (context, state) {
        final Widget content;
        if (state.voices.isNotEmpty) {
          content = VoicePicker(
            voices: state.voices,
            selectedId: state.selectedVoiceId,
            onSelect: (v) => bloc.add(VoiceSelectedEvent(v.id)),
          );
        } else {
          content = switch (state.voicesStatus) {
            LoadStatus.loading => const SelectListSkeleton(count: 4),
            LoadStatus.failed => StepMessage(
              text: strings.common_list_error,
              actionLabel: strings.common_try_again,
              onAction: () => bloc.add(const RefreshVoicesEvent()),
            ),
            LoadStatus.loaded => StepMessage(text: strings.common_list_empty),
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
