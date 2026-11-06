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

/// Step 2 of Create Reason: "What are you working toward?".
///
/// The selected area's title sits on top in its tint. The user types into the big
/// field, or speaks into it with the mic (speech to text), or picks one of the
/// suggestions (the selected area's rows of `purpose_suggestion`, 3 at a time, "More
/// ideas" for 3 more). Suggestions show only while the field is empty.
///
/// The text and whether it is an unchanged suggestion
/// (`CreateReasonState.purposeFromSuggestion`) live in [CreateReasonBloc].
class PurposeStep extends StatelessWidget {
  const PurposeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    return ComposerTextStep(
      eyebrow: const _AreaEyebrow(),
      title: strings.create_reason_purpose_title,
      initialText: bloc.state.purpose,
      onChanged: (text) => bloc.add(PurposeChangedEvent(text)),
      hintText: strings.create_reason_purpose_hint,
      maxLength: AppConstant.purposeMaxLength,
      suggestions: (fill) => _Suggestions(onFill: fill),
    );
  }
}

/// The selected area's title, small and upper case, in its tint mixed into white.
class _AreaEyebrow extends StatelessWidget {
  const _AreaEyebrow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CreateReasonBloc, CreateReasonState, (String, int?)?>(
      selector: (state) {
        final area = state.selectedArea;
        return area == null ? null : (area.title, area.color);
      },
      builder: (context, area) {
        if (area == null) return const SizedBox.shrink();
        final tint = Color(area.$2 ?? AppColor.primary.toARGB32());
        return RiseIn(
          dy: 14,
          child: SuggestionLabel(
            area.$1,
            color: Color.lerp(AppColor.white, tint, 0.7),
          ),
        );
      },
    );
  }
}

/// The suggestions under the field: only while it is empty and the mic is off.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onFill});

  /// Puts the picked text into the field.
  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.suggestions != b.suggestions ||
          a.suggestionsStatus != b.suggestionsStatus ||
          a.dictating != b.dictating ||
          a.purpose.trim().isEmpty != b.purpose.trim().isEmpty,
      builder: (context, state) {
        if (state.dictating || state.purpose.trim().isNotEmpty) {
          return const SizedBox.shrink();
        }
        final label = strings.create_reason_suggestions_label;
        final Widget content = switch (state.suggestionsStatus) {
          LoadStatus.loading => SuggestionListSkeleton(label: label),
          LoadStatus.failed => SuggestionError(
            onRetry: () {
              final areaId = state.selectedAreaId;
              if (areaId != null) bloc.add(LoadSuggestionsEvent(areaId));
            },
          ),
          LoadStatus.loaded =>
            state.suggestions.isEmpty
                ? const SizedBox.shrink()
                : SuggestionList(
                    label: label,
                    items: [
                      for (final quote in state.suggestions)
                        SuggestionItem(id: quote.id, text: quote.text),
                    ],
                    onPick: (item) {
                      bloc.add(SuggestionPickedEvent(item.id as int));
                      onFill(item.text);
                    },
                  ),
        };
        return RiseIn(
          delay: const Duration(milliseconds: 300),
          dy: 14,
          child: Padding(padding: REdgeInsets.only(top: 26), child: content),
        );
      },
    );
  }
}
