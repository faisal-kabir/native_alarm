import 'package:flutter/material.dart';

import '../../main.dart';

/// A list heading: bold title on the left, an optional control on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: appTheme(context).textTheme.headlineSmall),
        ?trailing,
      ],
    );
  }
}
