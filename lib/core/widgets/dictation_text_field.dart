import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../speech/dictation_controller.dart';
import '../theme/app_color.dart';
import '../utils/text_utils.dart';
import 'app_svg_icon.dart';
import 'dictation_bar.dart';
import 'rise_in.dart';

/// A big free-text field the user can type into **or speak into**.
///
/// Typing: large text, a mic button in the bottom-right corner, a thin rule under it
/// whose orange fill grows with the text (full at 40 characters), and a "123/180"
/// counter past 75 % of [maxLength] (unless [showCounter] is false). A [note] (e.g. "a
/// few more words") fades in under the rule.
///
/// Speaking: the mic starts [dictation]; the field cross-fades into the
/// [DictationBar] (transcript + live meter). When the take ends, what was said is
/// added to the end of what was typed (clipped to [maxLength] at a whole word). If
/// speech input is not available, [onDictationUnavailable] is called.
class DictationTextField extends StatefulWidget {
  const DictationTextField({
    super.key,
    required this.controller,
    required this.dictation,
    required this.hintText,
    required this.maxLength,
    this.showCounter = true,
    this.note,
    this.minHeight = 72,
    this.onDictationUnavailable,
  });

  final TextEditingController controller;
  final DictationController dictation;
  final String hintText;
  final int maxLength;
  final bool showCounter;
  final String? note;

  /// The field is at least this tall (dp) before anything is written.
  final double minHeight;
  final VoidCallback? onDictationUnavailable;

  @override
  State<DictationTextField> createState() => _DictationTextFieldState();
}

class _DictationTextFieldState extends State<DictationTextField> {
  @override
  void initState() {
    super.initState();
    widget.dictation.onFinished = _onSaid;
  }

  @override
  void didUpdateWidget(DictationTextField old) {
    super.didUpdateWidget(old);
    if (old.dictation != widget.dictation) {
      old.dictation.onFinished = null;
      widget.dictation.onFinished = _onSaid;
    }
  }

  @override
  void dispose() {
    widget.dictation.onFinished = null;
    super.dispose();
  }

  /// Speech joins what is already there; it never replaces it.
  void _onSaid(String said) {
    final had = widget.controller.text.trim();
    final next = clipToWord(
      had.isEmpty ? said : '$had $said',
      widget.maxLength,
    );
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _startDictation() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final ok = await widget.dictation.start();
    if (!ok && mounted) widget.onDictationUnavailable?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds only when listening starts or stops (words are handled inside the bar).
    return ListenableBuilder(
      listenable: widget.dictation,
      builder: (context, _) {
        final listening = widget.dictation.listening;
        return AnimatedSwitcher(
          // The old child fades out (250 ms), then the new one fades in (250 ms).
          duration: const Duration(milliseconds: 500),
          switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
          switchOutCurve: const Interval(0.5, 1, curve: Curves.easeOut),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: listening
              ? DictationBar(
                  key: const ValueKey('saying'),
                  controller: widget.dictation,
                )
              : _TypingField(
                  key: const ValueKey('typing'),
                  controller: widget.controller,
                  hintText: widget.hintText,
                  maxLength: widget.maxLength,
                  showCounter: widget.showCounter,
                  note: widget.note,
                  minHeight: widget.minHeight,
                  onMic: _startDictation,
                ),
        );
      },
    );
  }
}

/// The written line: big text, the mic in its corner, the warming rule under it.
class _TypingField extends StatelessWidget {
  const _TypingField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLength,
    required this.showCounter,
    required this.note,
    required this.minHeight,
    required this.onMic,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final bool showCounter;
  final String? note;
  final double minHeight;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final fieldStyle = textTheme.titleLarge!.copyWith(
      fontSize: 27.spMin,
      height: 1.25,
      letterSpacing: -0.54,
      color: AppColor.textColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight.h),
              child: TextField(
                controller: controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
                cursorColor: AppColor.primary,
                // A tap anywhere else closes the keyboard (a page-wide tap catcher
                // would win the tap from the field itself and stop it focusing).
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                style: fieldStyle,
                decoration: InputDecoration.collapsed(
                  hintText: hintText,
                  hintStyle: fieldStyle.copyWith(color: AppColor.fieldHint),
                ).copyWith(contentPadding: REdgeInsets.only(right: 52)),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Semantics(
                button: true,
                label: strings.dictation_start,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onMic,
                  child: Container(
                    width: 44.r,
                    height: 44.r,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.cardColor,
                    ),
                    child: AppSvgIcon(
                      Assets.icons.voice.mic,
                      size: 19.r,
                      color: AppColor.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // Only the rule and the counter follow the text; the field itself is not
        // rebuilt on every keystroke by this widget.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final len = value.text.length;
            final fill = (value.text.trim().length / 40).clamp(0.0, 1.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: Container(
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: AppColor.fieldRule,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: fill),
                      duration: const Duration(milliseconds: 500),
                      curve: RiseIn.curve,
                      builder: (_, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showCounter && len > maxLength * 0.75)
                  Padding(
                    padding: REdgeInsets.only(top: 6),
                    child: Text(
                      strings.text_counter(len, maxLength),
                      textAlign: TextAlign.right,
                      style: textTheme.bodySmall!.copyWith(
                        fontSize: 13.5.spMin,
                        color: AppColor.textTertiary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: note == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  key: ValueKey(note),
                  padding: REdgeInsets.only(top: 8),
                  child: Text(
                    note!,
                    style: appTheme(context).textTheme.bodySmall!.copyWith(
                      fontSize: 13.5.spMin,
                      color: AppColor.textTertiary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
