import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../di/injection.dart';
import '../speech/dictation_controller.dart';
import '../theme/app_color.dart';
import '../utils/text_utils.dart';
import 'app_sheet.dart';
import 'dictation_text_field.dart';
import 'pill_button.dart';
import 'suggestion_list.dart';

/// A bottom sheet to write (type or speak) one line: the app's [DictationTextField],
/// and while it is empty the suggestions [loadSuggestions] brings (shimmer while they
/// load, "Try again" on failure).
///
/// The button reads "No Changes" (off) until the text differs from [initialText] and
/// is long enough ([minLength] characters, [minWords] words), then "Use This"; with
/// [allowEmpty] an emptied field reads "Remove". It returns the trimmed text ("" =
/// remove), or null when it was dismissed. [shortNote] shows under the field while the
/// text is too short.
Future<String?> showTextSheet(
  BuildContext context, {
  required String title,
  required String initialText,
  required String hintText,
  required int maxLength,
  required int minLength,
  int minWords = 1,
  bool allowEmpty = false,
  String? shortNote,
  Future<List<SuggestionItem>> Function()? loadSuggestions,
}) => showAppSheet<String>(
  context,
  builder: (_) => _TextSheet(
    title: title,
    initialText: initialText,
    hintText: hintText,
    maxLength: maxLength,
    minLength: minLength,
    minWords: minWords,
    allowEmpty: allowEmpty,
    shortNote: shortNote,
    loadSuggestions: loadSuggestions,
  ),
);

class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.title,
    required this.initialText,
    required this.hintText,
    required this.maxLength,
    required this.minLength,
    required this.minWords,
    required this.allowEmpty,
    required this.shortNote,
    required this.loadSuggestions,
  });

  final String title;
  final String initialText;
  final String hintText;
  final int maxLength;
  final int minLength;
  final int minWords;
  final bool allowEmpty;
  final String? shortNote;
  final Future<List<SuggestionItem>> Function()? loadSuggestions;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  )..addListener(_changed);
  final DictationController _dictation = instance<DictationController>();
  late Future<List<SuggestionItem>>? _suggestions = widget.loadSuggestions
      ?.call();

  @override
  void initState() {
    super.initState();
    _dictation.addListener(_changed);
  }

  @override
  void dispose() {
    if (_dictation.listening) _dictation.cancel();
    _dictation
      ..removeListener(_changed)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  String get _clean => _text.text.trim();

  bool get _ready {
    final text = _clean;
    if (widget.allowEmpty && text.isEmpty) return true;
    return text.length >= widget.minLength &&
        wordCount(text) >= widget.minWords;
  }

  void _fill(String value) {
    final text = clipToWord(value.trim(), widget.maxLength);
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final clean = _clean;
    final changed = clean != widget.initialText.trim();
    final listening = _dictation.listening;
    final label = !changed
        ? strings.sheet_no_changes
        : widget.allowEmpty && clean.isEmpty
        ? strings.sheet_remove
        : strings.sheet_use_this;
    final suggestions = _suggestions;
    return AppSheet(
      title: widget.title,
      footer: PillButton(
        enabled: changed && _ready && !listening,
        disabledColor: AppColor.slotFree,
        label: label,
        onPressed: () => AppSheetScope.of(context).close(clean),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          DictationTextField(
            controller: _text,
            dictation: _dictation,
            hintText: widget.hintText,
            maxLength: widget.maxLength,
            note: clean.isNotEmpty && !_ready ? widget.shortNote : null,
            onDictationUnavailable: () => ScaffoldMessenger.of(context)
                .showSnackBar(
                  SnackBar(content: Text(strings.dictation_unavailable)),
                ),
          ),
          if (suggestions != null && clean.isEmpty && !listening)
            Padding(
              padding: REdgeInsets.only(top: 22),
              child: FutureBuilder<List<SuggestionItem>>(
                future: suggestions,
                builder: (context, snap) {
                  final label = strings.create_reason_suggestions_label;
                  if (snap.hasError) {
                    return SuggestionError(
                      onRetry: () => setState(
                        () => _suggestions = widget.loadSuggestions?.call(),
                      ),
                    );
                  }
                  final items = snap.data;
                  if (items == null) {
                    return SuggestionListSkeleton(label: label);
                  }
                  if (items.isEmpty) return const SizedBox.shrink();
                  return SuggestionList(
                    label: label,
                    items: items,
                    pillColor: AppColor.surfaceSecondary,
                    onPick: (item) => _fill(item.text),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
