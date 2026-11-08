import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_color.dart';
import 'animated_select_list.dart';
import 'app_sheet.dart';
import 'pill_button.dart';

/// A bottom sheet to choose one of [items] (an area, a tone, a length, ...). It opens
/// with [selectedId] chosen; its button reads [keepLabel] and stays off until another
/// row is chosen, then reads [useLabel] of that row ("Use Career") and returns its id.
/// Null when it was dismissed. The rows are the app's [AnimatedSelectList].
Future<Object?> showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<SelectItem> items,
  required Object? selectedId,
  required String keepLabel,
  required String Function(SelectItem chosen) useLabel,
}) => showAppSheet<Object>(
  context,
  builder: (_) => _ChoiceSheet(
    title: title,
    items: items,
    selectedId: selectedId,
    keepLabel: keepLabel,
    useLabel: useLabel,
  ),
);

class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.keepLabel,
    required this.useLabel,
  });

  final String title;
  final List<SelectItem> items;
  final Object? selectedId;
  final String keepLabel;
  final String Function(SelectItem) useLabel;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late Object? _value = widget.selectedId;

  @override
  Widget build(BuildContext context) {
    SelectItem? chosen;
    for (final item in widget.items) {
      if (item.id == _value) chosen = item;
    }
    final changed = _value != widget.selectedId && chosen != null;
    return AppSheet(
      title: widget.title,
      footer: PillButton(
        enabled: changed,
        disabledColor: AppColor.slotFree,
        label: changed ? widget.useLabel(chosen) : widget.keepLabel,
        onPressed: () => AppSheetScope.of(context).close(_value),
      ),
      // Inset 3 so the chosen border never touches the sheet's edge.
      body: Padding(
        padding: REdgeInsets.all(3),
        child: AnimatedSelectList(
          items: widget.items,
          selectedId: _value,
          animateIn: false,
          rowColor: AppColor.surfaceSecondary,
          onSelected: (item) => setState(() => _value = item.id),
        ),
      ),
    );
  }
}
