import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// What was chosen in a reason's "…" menu.
enum ReasonAction { useWithAlarm, delete }

/// The "…" menu of a reason: a sheet titled with its [name], one card of rows -
/// "Use with an alarm" (only while no alarm plays it, [canUseWithAlarm]: one alarm,
/// one Reason) and "Delete Reason" (red, always last). Answers the chosen action once
/// the sheet is gone (the caller acts on it), or null when dismissed.
Future<ReasonAction?> showReasonActions(
  BuildContext context, {
  required String name,
  required bool canUseWithAlarm,
}) => showAppSheet<ReasonAction>(
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
            if (canUseWithAlarm)
              ListGroupRow(
                icon: Assets.icons.alarm,
                label: strings.reason_actions_use_with_alarm,
                chevron: true,
                onTap: () =>
                    AppSheetScope.of(context).close(ReasonAction.useWithAlarm),
              ),
            ListGroupRow(
              icon: Assets.icons.settings.trash,
              label: strings.reason_actions_delete,
              danger: true,
              onTap: () => AppSheetScope.of(context).close(ReasonAction.delete),
            ),
          ],
        ),
      ),
    );
  },
);
