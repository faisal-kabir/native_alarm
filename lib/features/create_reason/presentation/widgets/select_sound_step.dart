import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/cached_svg_icon.dart';
import '../../../../core/widgets/check_circle.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../core/widgets/sliding_border.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../main.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import 'step_message.dart';
import 'reason_choice_items.dart';

/// Step 5 of Create Reason (the last): "How should it sound?".
///
/// An example card (the selected area's line in the chosen sound, from
/// `quotes_of_sound`, loaded fresh on every sound change with a shimmer while it
/// loads), the sound dials (`sound_type`, the first chosen at first; one orange circle
/// glides between them), the chosen sound's description, and the length (30 or 45
/// seconds, one border gliding between the two boxes).
class SelectSoundStep extends StatelessWidget {
  const SelectSoundStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.soundTypes != b.soundTypes ||
          a.soundTypesStatus != b.soundTypesStatus ||
          a.selectedSound != b.selectedSound ||
          a.soundQuoteShown != b.soundQuoteShown ||
          a.soundQuoteStatus != b.soundQuoteStatus ||
          a.lengthSeconds != b.lengthSeconds,
      builder: (context, state) {
        final selected = state.selectedSound;
        final List<Widget> body;
        if (selected == null) {
          body = [
            switch (state.soundTypesStatus) {
              LoadStatus.loading => const _StepSkeleton(),
              LoadStatus.failed => StepMessage(
                text: strings.common_list_error,
                actionLabel: strings.common_try_again,
                onAction: () => bloc.add(const LoadSoundTypesEvent()),
              ),
              LoadStatus.loaded => StepMessage(text: strings.common_list_empty),
            },
          ];
        } else {
          body = [
            RiseIn(
              delay: const Duration(milliseconds: 120),
              dy: 20,
              child: Padding(
                padding: REdgeInsets.only(top: 18),
                child: _ExampleCard(
                  status: state.soundQuoteStatus,
                  text: state.soundQuoteShown?.text,
                  onRetry: () {
                    final key = state.soundQuoteKey;
                    if (key != null) {
                      bloc.add(LoadSoundQuoteEvent(key.$1, key.$2));
                    }
                  },
                ),
              ),
            ),
            RiseIn(
              delay: const Duration(milliseconds: 250),
              dy: 14,
              child: Padding(
                padding: REdgeInsets.only(top: 26),
                child: _SoundDials(
                  sounds: state.soundTypes,
                  selectedId: selected.id,
                  onSelect: (sound) {
                    HapticFeedback.selectionClick();
                    bloc.add(SoundSelectedEvent(sound.id));
                  },
                ),
              ),
            ),
            Padding(
              padding: REdgeInsets.only(top: 16),
              child: _Blurb(selected.description ?? ''),
            ),
            RiseIn(
              delay: const Duration(milliseconds: 350),
              dy: 14,
              child: Padding(
                padding: REdgeInsets.only(top: 26),
                child: _LengthChoice(
                  seconds: state.lengthSeconds,
                  onSelect: (seconds) {
                    HapticFeedback.selectionClick();
                    bloc.add(LengthSelectedEvent(seconds));
                  },
                ),
              ),
            ),
          ];
        }
        return SingleChildScrollView(
          padding: REdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HighlightedTitle(strings.create_reason_sound_title, fontSize: 32),
              ...body,
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ example card

/// The letter: a big orange “ and "Example", then the example line (word by word),
/// a shimmer while it loads, or "Try again" when it failed.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.status,
    required this.text,
    required this.onRetry,
  });

  final LoadStatus status;
  final String? text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final text = this.text;
    final Widget content = switch (status) {
      LoadStatus.loading => const _ExampleSkeleton(),
      LoadStatus.failed => SuggestionError(
        text: strings.create_reason_example_failed,
        onRetry: onRetry,
      ),
      LoadStatus.loaded =>
        text == null
            ? const SizedBox.shrink()
            : Semantics(
                liveRegion: true,
                label: '${strings.create_reason_example}: $text',
                excludeSemantics: true,
                // A new key per line, so every new example rises in again.
                child: _ExampleLine(key: ValueKey(text), text: text),
              ),
    };
    return RepaintBoundary(
      child: Container(
        constraints: BoxConstraints(minHeight: 172.h),
        padding: REdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: AppColor.cardColor,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 18.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // The mark is a small box; the big glyph hangs out of it.
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 18.w,
                      height: 16.h,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxWidth: 60.w,
                        maxHeight: 26.4.h,
                        child: Text(
                          '“',
                          style: textTheme.headlineLarge!.copyWith(
                            fontSize: 44.spMin,
                            height: 0.6,
                            letterSpacing: -0.88,
                            color: AppColor.primary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      strings.create_reason_example,
                      style: textTheme.labelSmall!.copyWith(
                        fontSize: 12.spMin,
                        height: 18 / 12,
                        fontWeight: Dimension.textMedium,
                        letterSpacing: 0.48,
                        color: AppColor.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            content,
          ],
        ),
      ),
    );
  }
}

/// The example sentence arriving word by word: each word rises 6 and fades in over
/// 400 ms, 35 ms after the one before. Only colour alpha and a translate change per
/// frame (no layers, no relayout); with reduced motion it is simply there.
class _ExampleLine extends StatefulWidget {
  const _ExampleLine({super.key, required this.text});

  final String text;

  @override
  State<_ExampleLine> createState() => _ExampleLineState();
}

class _ExampleLineState extends State<_ExampleLine>
    with SingleTickerProviderStateMixin {
  static const _stagger = 35;
  static const _wordMs = 400;

  late final List<String> _words = widget.text
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (_words.length - 1).clamp(0, 1000) * _stagger + _wordMs,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else if (_enter.value == 0 && !_enter.isAnimating) {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = appTheme(context).textTheme.titleMedium!.copyWith(
      fontSize: 19.spMin,
      height: 26.22 / 19,
      fontWeight: Dimension.textSemiBold,
      letterSpacing: -0.38,
      color: AppColor.textColor,
    );
    final rise = 6.h;
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, _) {
        final totalMs = _enter.duration!.inMilliseconds;
        final nowMs = _enter.value * totalMs;
        return SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 0.26 * 19.spMin,
            children: [
              for (var i = 0; i < _words.length; i++)
                Builder(
                  builder: (_) {
                    final t = RiseIn.curve.transform(
                      ((nowMs - i * _stagger) / _wordMs).clamp(0.0, 1.0),
                    );
                    return Transform.translate(
                      offset: Offset(0, rise * (1 - t)),
                      child: Text(
                        _words[i],
                        style: style.copyWith(
                          color: AppColor.textColor.withValues(alpha: t),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmering lines in the example card while the line loads.
class _ExampleSkeleton extends StatelessWidget {
  const _ExampleSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 16.h,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
    return ExcludeSemantics(
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(1),
            SizedBox(height: 10.h),
            bar(0.92),
            SizedBox(height: 10.h),
            bar(0.6),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------ dials

/// One dial per sound in equal columns; ONE orange circle springs from dial to dial.
class _SoundDials extends StatefulWidget {
  const _SoundDials({
    required this.sounds,
    required this.selectedId,
    required this.onSelect,
  });

  final List<SoundType> sounds;
  final int selectedId;
  final ValueChanged<SoundType> onSelect;

  @override
  State<_SoundDials> createState() => _SoundDialsState();
}

class _SoundDialsState extends State<_SoundDials>
    with SingleTickerProviderStateMixin {
  // The chosen circle's column, fractional while it travels.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );

  int get _index {
    final i = widget.sounds.indexWhere((s) => s.id == widget.selectedId);
    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(_SoundDials oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _index.toDouble();
    if (target == _pos.value && !_pos.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pos.value = target;
    } else {
      _pos.animateWith(
        SpringSimulation(SelectionMotion.pickerSpring, _pos.value, target, 0),
      );
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.sounds.length;
    final dial = 54.r;
    final gap = 6.w;
    final height = 84.h;
    return Semantics(
      container: true,
      label: appLanguage(context).create_reason_sound_semantics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = (constraints.maxWidth - gap * (n - 1)) / n;
          double left(int i) => i * (w + gap);
          final circleX = (w - dial) / 2;
          final selected = _index;
          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < n; i++)
                  if (i != selected)
                    Positioned(
                      left: left(i) + circleX,
                      top: 4.h,
                      child: Container(
                        width: dial,
                        height: dial,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.cardColor,
                          border: Border.all(color: AppColor.fieldRule),
                        ),
                      ),
                    ),
                AnimatedBuilder(
                  animation: _pos,
                  builder: (context, child) => Positioned(
                    left: _pos.value * (w + gap) + circleX,
                    top: 4.h,
                    child: child!,
                  ),
                  child: IgnorePointer(
                    child: SizedBox.square(
                      dimension: dial,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: left(i),
                    top: 0,
                    width: w,
                    height: height,
                    child: _Dial(
                      sound: widget.sounds[i],
                      on: i == selected,
                      dial: dial,
                      onTap: () => widget.onSelect(widget.sounds[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({
    required this.sound,
    required this.on,
    required this.dial,
    required this.onTap,
  });

  final SoundType sound;
  final bool on;
  final double dial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = sound.icon;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      button: true,
      label: sound.title,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(height: 4.h),
            SizedBox.square(
              dimension: dial,
              child: Center(
                child: icon == null
                    ? null
                    : TweenAnimationBuilder<Color?>(
                        tween: ColorTween(
                          end: on ? AppColor.onPrimary : AppColor.textSecondary,
                        ),
                        duration: const Duration(milliseconds: 300),
                        builder: (_, color, _) => CachedSvgIcon(
                          path: icon,
                          size: 22.r,
                          color: color!,
                          fallback: const SizedBox.shrink(),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8.h),
            // A label wider than its column shrinks to fit instead of running into
            // the next one.
            SizedBox(
              width: double.infinity,
              height: 14.h,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: appTheme(context).textTheme.labelSmall!.copyWith(
                    fontSize: 12.spMin,
                    height: 14 / 12,
                    fontWeight: on ? Dimension.textBold : Dimension.textMedium,
                    letterSpacing: -0.12,
                    color: on ? AppColor.textColor : AppColor.textTertiary,
                  ),
                  child: Text(sound.title, maxLines: 1, softWrap: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- blurb / length

/// A centred line that cross-fades when its words change.
class _Blurb extends StatelessWidget {
  const _Blurb(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
      switchOutCurve: const Interval(0.5, 1, curve: Curves.easeOut),
      child: SizedBox(
        key: ValueKey(text),
        width: double.infinity,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: appTheme(context).textTheme.bodyLarge!.copyWith(
            fontSize: 15.spMin,
            height: 17.5 / 15,
            letterSpacing: 0,
            color: AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// "LENGTH", the two boxes (one border glides between them), and the chosen one's line.
class _LengthChoice extends StatelessWidget {
  const _LengthChoice({required this.seconds, required this.onSelect});

  final int seconds;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    const lengths = AppConstant.reasonLengthsSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuggestionLabel(strings.create_reason_length),
        SizedBox(height: 10.h),
        Semantics(
          container: true,
          label: strings.create_reason_length,
          child: SlidingBorderScope(
            selectedId: seconds,
            child: Row(
              children: [
                for (var i = 0; i < lengths.length; i++) ...[
                  if (i > 0) SizedBox(width: 8.w),
                  Expanded(
                    child: SlidingBorderTarget(
                      id: lengths[i],
                      child: _LengthBox(
                        name: reasonLengthName(strings, lengths[i]),
                        seconds: lengths[i],
                        on: lengths[i] == seconds,
                        onTap: () => onSelect(lengths[i]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 14.h),
        _Blurb(reasonLengthNote(strings, seconds)),
      ],
    );
  }
}

class _LengthBox extends StatelessWidget {
  const _LengthBox({
    required this.name,
    required this.seconds,
    required this.on,
    required this.onTap,
  });

  final String name;
  final int seconds;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final duration = strings.seconds_short(seconds);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      button: true,
      label: '$name, $duration',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: REdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColor.cardColor,
            borderRadius: BorderRadius.circular(SelectionMotion.radius.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium!.copyWith(
                        fontSize: 15.spMin,
                        height: 17.5 / 15,
                        color: AppColor.textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: textTheme.bodySmall!.copyWith(
                        fontSize: 13.spMin,
                        height: 15 / 13,
                        color: on ? AppColor.primary : AppColor.textSecondary,
                      ),
                      child: Text(duration),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              CheckCircle(on: on, size: 24, iconSize: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- loading

/// The step at its real sizes while the sound types load, shimmering.
class _StepSkeleton extends StatelessWidget {
  const _StepSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double h, double r) => Container(
      height: h,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return ExcludeSemantics(
      child: Shimmer(
        baseColor: AppColor.cardColor,
        highlightColor: AppColor.surfaceSecondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 18.h),
            block(172.h, 22.r),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: 54.r,
                    height: 54.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.white,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 56.h),
            Row(
              children: [
                Expanded(child: block(58.h, 12.r)),
                SizedBox(width: 8.w),
                Expanded(child: block(58.h, 12.r)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
