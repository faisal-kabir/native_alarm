import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../core/widgets/list_group.dart';

/// A [ListGroupRow] ending in an iOS-style switch (51 x 31, green when on).
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final SvgGenImage icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListGroupRow(
      icon: icon,
      label: label,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColor.toggleOn,
        inactiveTrackColor: AppColor.toggleOff,
        thumbColor: AppColor.white,
      ),
    );
  }
}
