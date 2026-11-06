import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/speech/dictation_controller.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/dictation_text_field.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../main.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';

/// Step 2 of Create Reason: "What are you working toward?".
///
/// The selected area's title sits on top in its tint. The user types into the big
/// field, or speaks into it with the mic (speech to text), or picks one of the
/// suggestions (the selected area's rows of `purpose_suggestion`, 3 at a time, "More
/// ideas" for 3 more). Suggestions show only while the field is empty.
///
/// The text and whether it is an unchanged suggestion
/// (`CreateReasonState.purposeFromSuggestion`) live in [CreateReasonBloc].
class PurposeStep extends StatefulWidget {
  const PurposeStep({super.key});

  @override
  State<PurposeStep> createState() => _PurposeStepState();
}

class _PurposeStepState extends State<PurposeStep> {
  late final CreateReasonBloc _bloc = context.read<CreateReasonBloc>();

  // Restored from the BLoC, so coming back to this step shows what was written.
  late final TextEditingController _text = TextEditingController(
    text: _bloc.state.purpose,
  )..addListener(_onText);

  late final DictationController _dictation = instance<DictationController>()
    ..addListener(_onDictation);
  bool _listening = false;

  void _onText() {
    if (_text.text != _bloc.state.purpose) {
      _bloc.add(PurposeChangedEvent(_text.text));
    }
  }

  void _onDictation() {
    if (_dictation.listening == _listening) return;
    _listening = _dictation.listening;
    _bloc.add(DictationChangedEvent(_listening));
  }

  @override
  void dispose() {
    if (_dictation.listening) _dictation.cancel();
    if (_listening && !_bloc.isClosed) {
      _bloc.add(const DictationChangedEvent(false));
    }
    _dictation
      ..removeListener(_onDictation)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocListener<CreateReasonBloc, CreateReasonState>(
      // A picked suggestion is put into the field from here.
      listenWhen: (a, b) => a.purpose != b.purpose,
      listener: (context, state) {
        if (_text.text == state.purpose) return;
        _text.value = TextEditingValue(
          text: state.purpose,
          selection: TextSelection.collapsed(offset: state.purpose.length),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: REdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AreaEyebrow(),
              SizedBox(height: 8.h),
              HighlightedTitle(
                strings.create_reason_purpose_title,
                fontSize: 32,
              ),
              SizedBox(height: 26.h),
              RiseIn(
                delay: const Duration(milliseconds: 150),
                dy: 14,
                child: DictationTextField(
                  controller: _text,
                  dictation: _dictation,
                  hintText: strings.create_reason_purpose_hint,
                  maxLength: AppConstant.purposeMaxLength,
                  onDictationUnavailable: () => ScaffoldMessenger.of(context)
                      .showSnackBar(
                        SnackBar(content: Text(strings.dictation_unavailable)),
                      ),
                ),
              ),
              const _Suggestions(),
            ],
          ),
        ),
      ),
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
  const _Suggestions();

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
          LoadStatus.failed => _IdeasError(
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
                    onPick: (item) =>
                        bloc.add(SuggestionPickedEvent(item.id as int)),
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

class _IdeasError extends StatelessWidget {
  const _IdeasError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    return Row(
      children: [
        Flexible(
          child: Text(
            strings.create_reason_ideas_error,
            style: textTheme.bodySmall!.copyWith(color: AppColor.textTertiary),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRetry,
          child: Padding(
            padding: REdgeInsets.all(8),
            child: Text(
              strings.common_try_again,
              style: textTheme.labelLarge!.copyWith(color: AppColor.primary),
            ),
          ),
        ),
      ],
    );
  }
}
