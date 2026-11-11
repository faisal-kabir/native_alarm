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

/// Step 3 of Create Goal (optional): "Why does it matter to you?".
///
/// Same shape as the purpose step: "OPTIONAL" on top, the heading, the goal the user
/// wrote as a quote, then the type-or-speak field (no counter; a note while it is 1-7
/// characters) and, while it is empty, 3 "why it matters" suggestions that depend on the
/// topic only (never on the goal's wording): the chip's own, or the general ones for a
/// topic the person wrote. Empty means "Skip for now".
class MatterStep extends StatelessWidget {
  const MatterStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    // Rebuilds only when the "too short" note comes or goes.
    return BlocSelector<CreateReasonBloc, CreateReasonState, bool>(
      selector: (state) => state.matterTooShort,
      builder: (context, tooShort) => ComposerTextStep(
        eyebrow: RiseIn(
          dy: 14,
          child: SuggestionLabel(strings.common_optional),
        ),
        title: strings.create_reason_matter_title,
        afterTitle: const _PurposeQuote(),
        initialText: bloc.state.matter,
        onChanged: (text) => bloc.add(MatterChangedEvent(text)),
        hintText: strings.create_reason_matter_hint,
        maxLength: AppConstant.purposeMaxLength,
        showCounter: false,
        note: tooShort ? strings.create_reason_matter_too_short : null,
        suggestions: (fill) => _Suggestions(onFill: fill),
      ),
    );
  }
}

/// A 2-wide orange bar, then "FOR" over the purpose in curly quotes.
class _PurposeQuote extends StatelessWidget {
  const _PurposeQuote();

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final purpose = context.select<CreateReasonBloc, String>(
      (bloc) => bloc.state.purpose.trim(),
    );
    if (purpose.isEmpty) return const SizedBox.shrink();
    return RiseIn(
      delay: const Duration(milliseconds: 100),
      dy: 14,
      child: Padding(
        padding: REdgeInsets.only(top: 14),
        child: Semantics(
          label: '${strings.create_reason_matter_for}: $purpose',
          excludeSemantics: true,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 2.w,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SuggestionLabel(strings.create_reason_matter_for),
                      SizedBox(height: 2.h),
                      Text(
                        strings.quoted_text(purpose),
                        style: appTheme(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15.spMin,
                          height: 1.4,
                          letterSpacing: 0,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The whys under the field: the chosen chip's own three, or the three general ones for
/// a topic the person wrote themselves. Only while the field is empty and the mic is
/// off; they came with the topic, so there is nothing to load.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onFill});

  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.whySuggestions != b.whySuggestions ||
          a.dictating != b.dictating ||
          a.matter.trim().isEmpty != b.matter.trim().isEmpty,
      builder: (context, state) {
        final whys = state.whySuggestions;
        if (state.dictating || state.matter.trim().isNotEmpty || whys.isEmpty) {
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
                for (var i = 0; i < whys.length && i < 3; i++)
                  SuggestionItem(id: '${state.chip?.id}-$i', text: whys[i]),
              ],
              onPick: (item) => onFill(item.text),
            ),
          ),
        );
      },
    );
  }
}
