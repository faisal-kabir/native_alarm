import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../main.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import 'composer_text_step.dart';

/// Step 2 of Create Goal: "What are you working toward?".
///
/// The topic from the first step sits on top. The user types into the big field, or
/// speaks into it with the mic (speech to text), or picks one of the suggestions: the
/// three goals of the chosen chip. A topic the person wrote themselves has no
/// suggestions, so nothing shows under the field. Suggestions show only while the field
/// is empty and the mic is off, and need no loading: they came with the chip.
class PurposeStep extends StatelessWidget {
  const PurposeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    return ComposerTextStep(
      eyebrow: const _TopicEyebrow(),
      title: strings.create_reason_purpose_title,
      initialText: bloc.state.purpose,
      onChanged: (text) => bloc.add(PurposeChangedEvent(text)),
      hintText: strings.create_reason_purpose_hint,
      maxLength: AppConstant.purposeMaxLength,
      fieldMinHeight: 44,
      suggestions: (fill) => _Suggestions(onFill: fill),
    );
  }
}

/// The topic, small and upper case, above the heading.
class _TopicEyebrow extends StatelessWidget {
  const _TopicEyebrow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CreateReasonBloc, CreateReasonState, String>(
      selector: (state) => state.topic,
      builder: (context, topic) {
        if (topic.isEmpty) return const SizedBox.shrink();
        return RiseIn(
          dy: 14,
          child: SuggestionLabel(topic, color: AppColor.textSecondary),
        );
      },
    );
  }
}

/// The chip's goals under the field: only while it is empty and the mic is off.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onFill});

  /// Puts the picked text into the field.
  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.goalSuggestions != b.goalSuggestions ||
          a.dictating != b.dictating ||
          a.purpose.trim().isEmpty != b.purpose.trim().isEmpty,
      builder: (context, state) {
        final goals = state.goalSuggestions;
        if (state.dictating ||
            state.purpose.trim().isNotEmpty ||
            goals.isEmpty) {
          return const SizedBox.shrink();
        }
        return RiseIn(
          delay: const Duration(milliseconds: 300),
          dy: 14,
          child: Padding(
            padding: REdgeInsets.only(top: 26),
            child: SuggestionList(
              label: strings.create_reason_suggestions_label,
              expandable: false,
              items: [
                for (var i = 0; i < goals.length && i < 3; i++)
                  SuggestionItem(id: '${state.chip?.id}-$i', text: goals[i]),
              ],
              onPick: (item) => onFill(item.text),
            ),
          ),
        );
      },
    );
  }
}
