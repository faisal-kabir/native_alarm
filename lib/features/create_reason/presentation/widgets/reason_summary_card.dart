import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../main.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../voice/presentation/widgets/voice_avatar.dart';

/// What was just made, played back as it was answered (the prototype's GoalCard). Three
/// lines in the order of the three questions, each under its own label and at one size
/// (the labels do the ranking): "Wake up for" (the name, any widget: a plain text, or a
/// `ReasonNameField` to rename it in place), "Goal", and "Why" (left out when there is
/// none, quieter). Under a hairline, the three choices made on the way in three equal
/// columns: voice (with its face), tone, length.
///
/// [timeline] (with [total], its length in seconds, and [delay], when the card starts)
/// makes it arrive the way a receipt prints: the card rises in over 0.7 s, then its
/// lines one after another, 0.12 s apart, then the choices. Without it everything is
/// simply there.
class ReasonSummaryCard extends StatelessWidget {
  const ReasonSummaryCard({
    super.key,
    required this.reason,
    required this.name,
    this.timeline,
    this.total = 1,
    this.delay = 0,
  });

  final Reason reason;
  final Widget name;
  final Animation<double>? timeline;
  final double total;
  final double delay;

  /// A window of [timeline] ([start] and [dur] in seconds) that rises and fades in.
  Animation<double>? _window(double start, double dur) => timeline?.drive(
    CurveTween(
      curve: Interval(
        start / total,
        ((start + dur) / total).clamp(0.0, 1.0),
        curve: RiseIn.curve,
      ),
    ),
  );

  Widget _rise(Animation<double>? window, double dy, Widget child) =>
      window == null
      ? child
      : RiseTransition(animation: window, dy: dy, child: child);

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final why = reason.why.trim();
    final voice = reason.voice;
    // The lines come a breath apart, from 0.15 s after the card starts.
    var line = 0;
    Animation<double>? next() => _window(delay + 0.15 + line++ * 0.12, 0.5);

    final rows = <Widget>[
      _rise(
        next(),
        6,
        _Line(
          label: strings.reason_ready_topic,
          child: Padding(padding: REdgeInsets.only(top: 5), child: name),
        ),
      ),
      _rise(
        next(),
        6,
        _Line(
          label: strings.reason_ready_goal,
          child: _LineText(reason.purpose, maxLines: 3),
        ),
      ),
      if (why.isNotEmpty)
        _rise(
          next(),
          6,
          _Line(
            label: strings.reason_ready_why,
            child: _LineText(why, maxLines: 2, quiet: true),
          ),
        ),
    ];
    final choices = timeline?.drive(
      CurveTween(
        curve: Interval(
          (delay + 0.15 + line * 0.12) / total,
          ((delay + 0.15 + line * 0.12 + 0.5) / total).clamp(0.0, 1.0),
        ),
      ),
    );

    final choicesRow = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Cell(
              child: Row(
                children: [
                  if (voice != null) ...[
                    VoiceAvatar(voice: voice, size: 30),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: _Choice(
                      label: strings.reason_ready_voice,
                      value: voice?.name ?? '',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _Cell(
              divided: true,
              child: _Choice(
                label: strings.reason_ready_tone,
                value: reason.toneTitle,
              ),
            ),
          ),
          Expanded(
            child: _Cell(
              divided: true,
              child: _Choice(
                label: strings.reason_ready_length,
                value: strings.seconds_short(reason.lengthSeconds),
              ),
            ),
          ),
        ],
      ),
    );

    return _rise(
      _window(delay, 0.7),
      16,
      Container(
        decoration: BoxDecoration(
          color: AppColor.cardColor,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColor.fieldRule),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: REdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) SizedBox(height: 16.h),
                    rows[i],
                  ],
                ],
              ),
            ),
            const SizedBox(
              height: 1,
              child: ColoredBox(color: AppColor.fieldRule),
            ),
            choices == null
                ? choicesRow
                : FadeTransition(opacity: choices, child: choicesRow),
          ],
        ),
      ),
    );
  }
}

/// A label over its content, left aligned.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SuggestionLabel(label), child],
    );
  }
}

/// A line of the card: 17, semibold (the quiet one regular and softer), at most
/// [maxLines] long.
class _LineText extends StatelessWidget {
  const _LineText(this.text, {required this.maxLines, this.quiet = false});

  final String text;
  final int maxLines;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.only(top: 5),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: appTheme(context).textTheme.bodyLarge!.copyWith(
          fontSize: 17.spMin,
          height: 1.32,
          letterSpacing: -0.2,
          fontWeight: quiet ? Dimension.textRegular : Dimension.textSemiBold,
          color: quiet ? AppColor.textSecondary : AppColor.textColor,
        ),
      ),
    );
  }
}

/// One of the three equal columns under the hairline.
class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.divided = false});

  final Widget child;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: REdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        border: divided
            ? const Border(left: BorderSide(color: AppColor.fieldRule))
            : null,
      ),
      child: child,
    );
  }
}

/// "VOICE" over "Astra".
class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionLabel(label),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appTheme(context).textTheme.bodyLarge!.copyWith(
            fontSize: 15.spMin,
            height: 17.5 / 15,
            fontWeight: Dimension.textMedium,
            letterSpacing: 0,
            color: AppColor.textColor,
          ),
        ),
      ],
    );
  }
}
