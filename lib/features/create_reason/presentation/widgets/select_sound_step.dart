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

/// Step 5 of Create Goal (the last): "How should it sound?".
///
/// The tones as a swipeable card (a PageView: one page per tone, holding its own example
/// line, `sound_type.sample`, the same for every goal, and its description) with page
/// dots under it, the sound dials (`sound_type`, the first chosen at first; one orange
/// circle glides between them; swiping the card and tapping a dial are the same
/// choice), and the length (30 or 45 seconds, one border gliding between the two boxes).
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
                child: _TonePager(
                  sounds: state.soundTypes,
                  selectedId: selected.id,
                  onSelect: (sound) {
                    HapticFeedback.selectionClick();
                    bloc.add(SoundSelectedEvent(sound.id));
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

/// The tone's example line, as it is set in the card (also what the card is measured with).
TextStyle _lineStyle(BuildContext context) =>
    appTheme(context).textTheme.titleMedium!.copyWith(
      fontSize: 19.spMin,
      height: 26.22 / 19,
      fontWeight: Dimension.textSemiBold,
      letterSpacing: -0.38,
      color: AppColor.textColor,
    );

/// The tone's description under its line.
TextStyle _descriptionStyle(BuildContext context) => appTheme(context)
    .textTheme
    .bodyLarge!
    .copyWith(
      fontSize: 14.spMin,
      height: 20 / 14,
      letterSpacing: 0,
      color: AppColor.textTertiary,
    );

/// The letter: a card with a big “ and "Example" on top and, below, one page per tone
/// (its example line arriving word by word, its description at the foot). Swipe to move
/// between tones, or tap a dial: both move the same choice. Under it, page dots (the
/// current one a long orange pill). The card is as tall as its tallest page, so nothing
/// below it moves when the tone changes; its glow and rim take the tone's own colour.
class _TonePager extends StatefulWidget {
  const _TonePager({
    required this.sounds,
    required this.selectedId,
    required this.onSelect,
  });

  final List<SoundType> sounds;
  final int selectedId;
  final ValueChanged<SoundType> onSelect;

  @override
  State<_TonePager> createState() => _TonePagerState();
}

class _TonePagerState extends State<_TonePager> {
  late final PageController _pages = PageController(
    initialPage: _indexOf(widget.selectedId),
  );

  /// A glide started by a dial: its in-between pages are not swipes.
  bool _gliding = false;

  int _indexOf(int id) {
    final at = widget.sounds.indexWhere((s) => s.id == id);
    return at < 0 ? 0 : at;
  }

  @override
  void didUpdateWidget(_TonePager old) {
    super.didUpdateWidget(old);
    if (!_pages.hasClients) return;
    final at = _indexOf(widget.selectedId);
    if ((_pages.page?.round() ?? at) == at) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(at);
      return;
    }
    _gliding = true;
    _pages
        .animateToPage(
          at,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _gliding = false);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// The last measured page height and what it was measured for (the tones, the width
  /// and the text scale): picking a tone rebuilds the card, but measures nothing again.
  double _height = 0;
  Object? _measuredFor;

  /// How tall the tallest page is: its line (laid out word by word, as the page's Wrap
  /// does it) plus the description, at [width].
  double _pageHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final key = (widget.sounds, width, scaler);
    if (key == _measuredFor) return _height;
    final line = _lineStyle(context);
    final spacing = 0.26 * 19.spMin;
    final description = _descriptionStyle(context);

    /// The [width] and [height] of [text] laid out in [style]; the painter is freed.
    Size measure(String text, TextStyle style, [double? maxWidth]) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth ?? double.infinity);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    var tallest = 0.0;
    for (final sound in widget.sounds) {
      var height = 14.h;
      final words = (sound.sample ?? '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty);
      if (words.isNotEmpty) {
        var lines = 1;
        var x = 0.0;
        double rowHeight = 0;
        for (final word in words) {
          final p = measure(word, line);
          rowHeight = p.height;
          if (x > 0 && x + spacing + p.width > width) {
            lines++;
            x = p.width;
          } else {
            x += (x > 0 ? spacing : 0) + p.width;
          }
        }
        height += lines * rowHeight;
      }
      final text = sound.description ?? '';
      if (text.isNotEmpty) {
        height += 14.h + measure(text, description, width).height;
      }
      if (height > tallest) tallest = height;
    }
    _measuredFor = key;
    return _height = tallest + 1;
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final sounds = widget.sounds;
    final at = _indexOf(widget.selectedId);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final tint = AppColor.tintOf(sounds[at].color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: tint),
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 800),
            builder: (context, color, child) {
              final light = color ?? tint;
              return Container(
                decoration: BoxDecoration(
                  color: AppColor.cardColor,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: light.withValues(alpha: 0.35)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // The tone's own light, rising from below the card.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, 1.6),
                              radius: 1,
                              colors: [
                                light.withValues(alpha: 0.5),
                                light.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.72],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: REdgeInsets.fromLTRB(20, 18, 20, 20),
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
                                        style: textTheme.headlineLarge!
                                            .copyWith(
                                              fontSize: 44.spMin,
                                              height: 0.6,
                                              letterSpacing: -0.88,
                                              color: light.withValues(
                                                alpha: 0.9,
                                              ),
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
                          child!,
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: _pageHeight(context, constraints.maxWidth),
                child: PageView.builder(
                  controller: _pages,
                  itemCount: sounds.length,
                  onPageChanged: (index) {
                    if (_gliding) return;
                    final sound = sounds[index];
                    if (sound.id != widget.selectedId) widget.onSelect(sound);
                  },
                  itemBuilder: (context, index) =>
                      _TonePage(sound: sounds[index]),
                ),
              ),
            ),
          ),
        ),
        if (sounds.length > 1)
          Padding(
            padding: REdgeInsets.only(top: 14),
            child: ExcludeSemantics(
              child: _PageDots(count: sounds.length, at: at),
            ),
          ),
      ],
    );
  }
}

/// One tone's page: its example line (word by word) and its description at the foot.
class _TonePage extends StatelessWidget {
  const _TonePage({required this.sound});

  final SoundType sound;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final sample = sound.sample;
    final description = sound.description ?? '';
    return Padding(
      padding: REdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sample != null)
            Semantics(
              liveRegion: true,
              label: '${strings.create_reason_example}: $sample',
              excludeSemantics: true,
              // A new key per line, so every new example rises in again.
              child: _ExampleLine(key: ValueKey(sample), text: sample),
            ),
          const Spacer(),
          if (description.isNotEmpty)
            Padding(
              padding: REdgeInsets.only(top: 14),
              child: Text(description, style: _descriptionStyle(context)),
            ),
        ],
      ),
    );
  }
}

/// Where the card is among the tones: the current dot a long orange pill.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.at});

  final int count;
  final int at;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: REdgeInsets.symmetric(horizontal: 3),
            width: (i == at ? 18 : 6).w,
            height: 6.h,
            decoration: BoxDecoration(
              color: i == at ? AppColor.primary : AppColor.dotIdle,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
      ],
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
    final style = _lineStyle(context);
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
