import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/select_list_skeleton.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../../goal_topic/domain/entities/goal_topic.dart';
import '../../../goal_topic/domain/goal_topic_search.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import 'step_message.dart';

/// Step 1 of Create Goal: "What do you want to wake up for?"
///
/// The answer is a label of a few words (the goal itself is the next step): typed into
/// one line that never wraps (20 characters, a placeholder that cycles through
/// examples), or a chip. The chips (`goal_topic`, from the saved copy, so they show at
/// once and offline too) arrive in steps: the first 20, then "More" for 15, then "More"
/// for the rest. One answer either way: typing lets go of a chip, a chip clears the
/// typing, and no category stands behind either.
///
/// Typing is also a search: chips that match come to the front and the rest step back,
/// still there to tap, and tapping a match completes what was typed. Typing a chip's
/// exact name is that chip, so it lights up and brings its suggestions along.
class TopicStep extends StatefulWidget {
  const TopicStep({super.key});

  @override
  State<TopicStep> createState() => _TopicStepState();
}

class _TopicStepState extends State<TopicStep> {
  late final CreateReasonBloc _bloc = context.read<CreateReasonBloc>();
  late final TextEditingController _text = TextEditingController(
    text: _bloc.state.topicText,
  )..addListener(_onText);
  final FocusNode _focus = FocusNode();

  /// How many of the chip steps are open (0 = the first 20).
  int _step = 0;
  bool _stepChosen = false;

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onText() {
    if (_text.text != _bloc.state.topicText) {
      _bloc.add(TopicTypedEvent(_text.text));
    }
  }

  /// The bloc changed the text (a chip was tapped, which clears it): follow it.
  void _follow(String text) {
    if (_text.text == text) return;
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _tap(GoalTopic topic, bool on, bool typing) {
    HapticFeedback.selectionClick();
    if (typing) {
      // Tapping a match completes what was typed (typing a chip's name is that chip).
      _bloc.add(TopicTypedEvent(on ? '' : topic.label));
    } else {
      _bloc.add(TopicPickedEvent(on ? null : topic.id));
    }
  }

  /// A saved choice reopens the step it sits in.
  void _openStepOf(List<GoalTopic> topics, GoalTopic? chip) {
    if (_stepChosen || chip == null) return;
    final at = topics.indexWhere((t) => t.id == chip.id);
    if (at < 0) return;
    final steps = chipSteps(topics.length);
    _stepChosen = true;
    _step = steps.indexWhere((end) => at < end).clamp(0, steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final examples = [
      strings.create_reason_topic_example_1,
      strings.create_reason_topic_example_2,
      strings.create_reason_topic_example_3,
      strings.create_reason_topic_example_4,
      strings.create_reason_topic_example_5,
      strings.create_reason_topic_example_6,
    ];
    return BlocConsumer<CreateReasonBloc, CreateReasonState>(
      listenWhen: (a, b) => a.topicText != b.topicText,
      listener: (context, state) => _follow(state.topicText),
      buildWhen: (a, b) =>
          a.topics != b.topics ||
          a.topicsStatus != b.topicsStatus ||
          a.selectedTopicId != b.selectedTopicId ||
          a.topicText != b.topicText,
      builder: (context, state) {
        _openStepOf(state.topics, state.chip);
        final typed = state.topicText.trim();
        const max = AppConstant.reasonNameMaxLength;
        final left = max - state.topicText.length;
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: REdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HighlightedTitle(strings.create_reason_area_title),
              SizedBox(height: 22.h),
              RiseIn(
                delay: const Duration(milliseconds: 120),
                dy: 14,
                child: _Field(
                  controller: _text,
                  focus: _focus,
                  examples: examples,
                  semantics: strings.create_reason_topic_semantics,
                  clearLabel: strings.create_reason_topic_clear,
                  onSubmitted: () {
                    if (state.canContinue) _bloc.add(const NextStepEvent());
                  },
                ),
              ),
              _Rule(filled: typed.isNotEmpty),
              SizedBox(
                height: 18.h,
                child: Padding(
                  padding: REdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      state.topicText.length >= max - 6
                          ? strings.create_reason_topic_left(left)
                          : '',
                      style: appTheme(context).textTheme.bodySmall!.copyWith(
                        fontSize: 13.spMin,
                        color: left <= 3
                            ? AppColor.primary
                            : AppColor.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SuggestionLabel(strings.create_reason_topic_chips),
              SizedBox(height: 12.h),
              if (state.topics.isNotEmpty)
                _Chips(
                  topics: state.topics,
                  chip: state.chip,
                  typed: typed,
                  step: _step,
                  moreLabel: strings.create_reason_topic_more,
                  moreSemantics: strings.create_reason_topic_more_semantics,
                  onMore: () => setState(() => _step++),
                  onTap: (topic, on) => _tap(topic, on, typed.isNotEmpty),
                )
              else
                switch (state.topicsStatus) {
                  LoadStatus.loading => const SelectListSkeleton(count: 4),
                  LoadStatus.failed => StepMessage(
                    text: strings.common_list_error,
                    actionLabel: strings.common_try_again,
                    onAction: () => _bloc.add(const RefreshTopicsEvent()),
                  ),
                  LoadStatus.loaded => StepMessage(
                    text: strings.common_list_empty,
                  ),
                },
            ],
          ),
        );
      },
    );
  }
}

/// The one-line field: big text, a placeholder that turns through examples (every
/// 2.4 s) while it is empty, and a small round clear button at the end once there is
/// something. The text field itself is built once; only the placeholder and the clear
/// button follow the typing, and only the placeholder follows the turning examples.
class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.focus,
    required this.examples,
    required this.semantics,
    required this.clearLabel,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final List<String> examples;
  final String semantics;
  final String clearLabel;
  final VoidCallback onSubmitted;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  /// Which example the placeholder shows.
  final ValueNotifier<int> _example = ValueNotifier(0);
  late final Timer _turn;

  static final List<TextInputFormatter> _formatters = [
    LengthLimitingTextInputFormatter(AppConstant.reasonNameMaxLength),
    FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
  ];

  @override
  void initState() {
    super.initState();
    _turn = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (widget.controller.text.isEmpty) _example.value++;
    });
  }

  @override
  void dispose() {
    _turn.cancel();
    _example.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final style = appTheme(context).textTheme.titleLarge!.copyWith(
      fontSize: 27.spMin,
      height: 1.25,
      letterSpacing: -0.54,
      color: AppColor.textColor,
    );
    final still = MediaQuery.disableAnimationsOf(context);
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Semantics(
          label: widget.semantics,
          textField: true,
          child: TextField(
            controller: controller,
            focusNode: widget.focus,
            maxLines: 1,
            inputFormatters: _formatters,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            cursorColor: AppColor.primary,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onSubmitted: (_) => widget.onSubmitted(),
            style: style,
            decoration: InputDecoration.collapsed(hintText: '')
                .copyWith(contentPadding: REdgeInsets.only(right: 36)),
          ),
        ),
        Positioned.fill(
          right: 36.w,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ListenableBuilder(
                listenable: Listenable.merge([controller, _example]),
                builder: (context, _) {
                  if (controller.text.isNotEmpty) {
                    return const SizedBox.shrink();
                  }
                  final at = _example.value % widget.examples.length;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: still
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      // The old and the new example both start at the left edge (the
                      // default centres the shorter one while they cross).
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: Text(
                        widget.examples[at],
                        key: ValueKey(at),
                        maxLines: 1,
                        style: style.copyWith(color: AppColor.fieldHint),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              final empty = controller.text.isEmpty;
              return AnimatedScale(
                scale: empty ? 0.6 : 1,
                duration: const Duration(milliseconds: 180),
                child: AnimatedOpacity(
                  opacity: empty ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(ignoring: empty, child: child),
                ),
              );
            },
            child: Semantics(
              button: true,
              label: widget.clearLabel,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.clear();
                },
                child: Container(
                  width: 28.r,
                  height: 28.r,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColor.clearButton,
                  ),
                  child: AppSvgIcon(
                    Assets.icons.voice.close,
                    size: 13.r,
                    color: AppColor.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The 2 dp rule under the field; its orange fill grows from the left once there is text.
class _Rule extends StatelessWidget {
  const _Rule({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: REdgeInsets.only(top: 10),
      child: SizedBox(
        height: 2.h,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColor.fieldRule)),
            Positioned.fill(
              child: AnimatedFractionallySizedBox(
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: RiseIn.curve,
                alignment: Alignment.centerLeft,
                widthFactor: filled ? 1 : 0,
                child: const ColoredBox(color: AppColor.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chips, in steps. While something is typed the chips that match come first (the
/// rest dim but stay tappable); otherwise they are in chip order, as many as the open
/// steps hold, and "More" opens the next step.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.topics,
    required this.chip,
    required this.typed,
    required this.step,
    required this.moreLabel,
    required this.moreSemantics,
    required this.onMore,
    required this.onTap,
  });

  final List<GoalTopic> topics;
  final GoalTopic? chip;
  final String typed;
  final int step;
  final String moreLabel;
  final String moreSemantics;
  final VoidCallback onMore;
  final void Function(GoalTopic topic, bool on) onTap;

  @override
  Widget build(BuildContext context) {
    final steps = chipSteps(topics.length);
    final open = steps[step.clamp(0, steps.length - 1)];
    final prev = step > 0 ? steps[step - 1] : 0;
    final opened = topics.take(open).toList();
    final searching = typed.isNotEmpty;
    final matched = searching
        ? [
            for (final t in topics)
              if (topicMatches(t, typed)) t,
          ]
        : const <GoalTopic>[];
    final hit = {for (final t in matched) t.id};
    final shown = searching
        ? [...matched, ...opened.where((t) => !hit.contains(t.id))]
        : opened;
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (var i = 0; i < shown.length; i++)
          _Chip(
            key: ValueKey(shown[i].id),
            topic: shown[i],
            on: chip?.id == shown[i].id,
            near: !searching || hit.contains(shown[i].id),
            glow: searching && hit.contains(shown[i].id),
            // A step that has just opened rises in a little after the one before.
            enter: !searching && step > 0 && i >= prev
                ? Duration(milliseconds: (i - prev) * 30)
                : Duration(milliseconds: 240 + (i.clamp(0, 12)) * 12),
            onTap: () => onTap(shown[i], chip?.id == shown[i].id),
          ),
        if (!searching && step < steps.length - 1)
          _MoreChip(label: moreLabel, semantics: moreSemantics, onTap: onMore),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.topic,
    required this.on,
    required this.near,
    required this.glow,
    required this.enter,
    required this.onTap,
  });

  final GoalTopic topic;
  final bool on;

  /// False while searching for something else: the chip dims.
  final bool near;

  /// A match of what is typed: a thin orange ring.
  final bool glow;
  final Duration enter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    return RiseIn(
      delay: enter,
      duration: const Duration(milliseconds: 300),
      dy: 6,
      child: AnimatedOpacity(
        opacity: near ? 1 : 0.32,
        duration: const Duration(milliseconds: 300),
        child: Semantics(
          button: true,
          inMutuallyExclusiveGroup: true,
          checked: on,
          label: topic.label,
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: REdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: on ? AppColor.primary : AppColor.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppConstant.pillRadius),
                border: Border.all(
                  color: glow && !on
                      ? AppColor.primary.withValues(alpha: 0.55)
                      : AppColor.transparent,
                ),
              ),
              child: Text(
                topic.label,
                maxLines: 1,
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 15.spMin,
                  height: 20 / 15,
                  letterSpacing: -0.15,
                  color: on
                      ? AppColor.onPrimary
                      : glow
                      ? AppColor.textColor
                      : AppColor.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "More ⌄": opens the next step of chips; quiet, with a thin outline.
class _MoreChip extends StatelessWidget {
  const _MoreChip({
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: REdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstant.pillRadius),
            border: Border.all(color: AppColor.chipOutline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 15.spMin,
                  height: 20 / 15,
                  letterSpacing: -0.15,
                  color: AppColor.textSecondary,
                ),
              ),
              SizedBox(width: 4.w),
              // The forward chevron turned to point down.
              RotatedBox(
                quarterTurns: 1,
                child: AppSvgIcon(
                  Assets.icons.page.chevron,
                  size: 14.r,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
