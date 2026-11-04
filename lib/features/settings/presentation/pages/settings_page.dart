import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';
import '../../../../main.dart';

/// The "Settings" tab of the Dashboard. Placeholder until its design arrives.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(text: appLanguage(context).settings_placeholder);
  }
}
