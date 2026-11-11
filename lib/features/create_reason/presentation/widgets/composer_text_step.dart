import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/speech/dictation_controller.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/dictation_text_field.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../main.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';

/// The shared body of the Create Reason text steps ("What are you working toward?",
/// "Why does it matter to you?"): [eyebrow], the big [title], an optional
/// [afterTitle], the type-or-speak field, then the step's [suggestions].
///
/// It owns the text field and the microphone: the field starts with [initialText]
/// (from the BLoC, so coming back shows what was written), every change goes to
/// [onChanged], and while the mic listens the BLoC hears `DictationChangedEvent`.
/// [suggestions] gets a `fill` callback that puts a picked suggestion into the field.
class ComposerTextStep extends StatefulWidget {
  const ComposerTextStep({
    super.key,
    required this.eyebrow,
    required this.title,
    this.afterTitle,
    required this.initialText,
    required this.onChanged,
    required this.hintText,
    required this.maxLength,
    this.showCounter = true,
    this.note,
    this.fieldMinHeight = 72,
    required this.suggestions,
  });

  final Widget eyebrow;
  final String title;
  final Widget? afterTitle;
  final String initialText;
  final ValueChanged<String> onChanged;
  final String hintText;
  final int maxLength;
  final bool showCounter;
  final String? note;

  /// The field is at least this tall (dp) before anything is written.
  final double fieldMinHeight;
  final Widget Function(ValueChanged<String> fill) suggestions;

  @override
  State<ComposerTextStep> createState() => _ComposerTextStepState();
}

class _ComposerTextStepState extends State<ComposerTextStep> {
  late final CreateReasonBloc _bloc = context.read<CreateReasonBloc>();

  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  )..addListener(_onText);
  String _sent = '';

  late final DictationController _dictation = instance<DictationController>()
    ..addListener(_onDictation);
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _sent = widget.initialText;
  }

  void _onText() {
    if (_text.text == _sent) return;
    _sent = _text.text;
    widget.onChanged(_sent);
  }

  void _onDictation() {
    if (_dictation.listening == _listening) return;
    _listening = _dictation.listening;
    _bloc.add(DictationChangedEvent(_listening));
  }

  /// Puts a picked suggestion into the field (within the length limit).
  void _fill(String text) {
    final value = clipToWord(text.trim(), widget.maxLength);
    _text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
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
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: REdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.eyebrow,
          SizedBox(height: 8.h),
          HighlightedTitle(widget.title, fontSize: 32),
          ?widget.afterTitle,
          SizedBox(height: 26.h),
          RiseIn(
            delay: const Duration(milliseconds: 150),
            dy: 14,
            child: DictationTextField(
              controller: _text,
              dictation: _dictation,
              hintText: widget.hintText,
              maxLength: widget.maxLength,
              showCounter: widget.showCounter,
              note: widget.note,
              minHeight: widget.fieldMinHeight,
              onDictationUnavailable: () => ScaffoldMessenger.of(context)
                  .showSnackBar(
                    SnackBar(content: Text(strings.dictation_unavailable)),
                  ),
            ),
          ),
          widget.suggestions(_fill),
        ],
      ),
    );
  }
}
