import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';
import '../../../../main.dart';

/// The "Reasons" tab of the Dashboard. Placeholder until its design arrives.
class ReasonsPage extends StatelessWidget {
  const ReasonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(text: appLanguage(context).reasons_placeholder);
  }
}
