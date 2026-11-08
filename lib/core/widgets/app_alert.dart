import 'package:flutter/cupertino.dart';

import '../theme/app_color.dart';

/// One button of [showAppAlert].
class AppAlertAction<T> {
  const AppAlertAction({
    required this.label,
    required this.value,
    this.destructive = false,
  });

  final String label;

  /// What [showAppAlert] returns when this button is pressed.
  final T value;

  /// Red instead of the brand colour ("Discard").
  final bool destructive;
}

/// The app's alert (iOS style: blurred box, buttons under a hairline): use it for
/// every "Discard changes?"-style question. Returns the pressed action's value, null
/// when it was dismissed.
Future<T?> showAppAlert<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<AppAlertAction<T>> actions,
}) => showCupertinoDialog<T>(
  context: context,
  barrierDismissible: true,
  builder: (context) => CupertinoTheme(
    data: const CupertinoThemeData(brightness: Brightness.dark),
    child: CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        for (final action in actions)
          CupertinoDialogAction(
            isDestructiveAction: action.destructive,
            textStyle: action.destructive
                ? null
                : const TextStyle(color: AppColor.primary),
            onPressed: () => Navigator.of(context).pop(action.value),
            child: Text(action.label),
          ),
      ],
    ),
  ),
);
