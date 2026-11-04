import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';

/// A centred text standing in for a screen that is not built yet. Replace the page's
/// body with the real screen when its design arrives.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Padding(
          padding: REdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: appTheme(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
