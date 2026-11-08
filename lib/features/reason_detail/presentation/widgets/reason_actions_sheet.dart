import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// The "…" menu of a reason: a sheet titled with its [name], one card of two rows -
/// "Use with an alarm" (not built yet: it does nothing) and "Delete Reason" (red,
/// always last). Returns true when Delete was chosen (the sheet is gone by then; the
/// caller asks to confirm).
Future<bool> showReasonActions(
  BuildContext context, {
  required String name,
}) async {
  final delete = await showAppSheet<bool>(
    context,
    builder: (context) {
      final strings = appLanguage(context);
      return AppSheet(
        title: name,
        body: Padding(
          padding: REdgeInsets.only(bottom: 8),
          child: ListGroup(
            color: AppColor.surfaceSecondary,
            radius: 14,
            children: [
              ListGroupRow(
                icon: Assets.icons.alarm,
                label: strings.reason_actions_use_with_alarm,
                chevron: true,
              ),
              ListGroupRow(
                icon: Assets.icons.settings.trash,
                label: strings.reason_actions_delete,
                danger: true,
                onTap: () => AppSheetScope.of(context).close(true),
              ),
            ],
          ),
        ),
      );
    },
  );
  return delete ?? false;
}
