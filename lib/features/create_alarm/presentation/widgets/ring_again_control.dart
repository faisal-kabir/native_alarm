import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../main.dart';

/// iOS's segmented control: a grey track (34 tall, radius 9, padding 2) and the
/// choice on a lighter pill that glides to the next one (320 ms).
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.label,
  });

  final int value;
  final List<String> options;
  final ValueChanged<int> onChanged;

  /// What a screen reader calls the whole control.
  final String label;

  @override
  Widget build(BuildContext context) {
    final n = options.length;
    final still = MediaQuery.disableAnimationsOf(context);
    final textTheme = appTheme(context).textTheme;
    void choose(int i) {
      if (i == value) return;
      HapticFeedback.selectionClick();
      onChanged(i);
    }

    return Semantics(
      container: true,
      label: label,
      child: Container(
        height: 34.h,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColor.controlFill,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              curve: const Cubic(0.25, 1.15, 0.4, 1),
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * value / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF636366), // iOS's raised segment
                    borderRadius: BorderRadius.circular(7.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      inMutuallyExclusiveGroup: true,
                      checked: i == value,
                      button: true,
                      label: options[i],
                      excludeSemantics: true,
                      onTap: () => choose(i),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => choose(i),
                        child: Center(
                          child: Text(
                            options[i],
                            maxLines: 1,
                            style: textTheme.labelLarge!.copyWith(
                              fontWeight: i == value
                                  ? Dimension.textSemiBold
                                  : Dimension.textMedium,
                              color: AppColor.titleColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The sentence under "Ring again", in counts rather than clock times (an alarm can
/// ring at a different time each day): [count] white, the rest grey, always one line
/// so nothing below moves. It cross-fades (180 ms) when the choice changes.
class RingAgainCaption extends StatelessWidget {
  const RingAgainCaption({
    super.key,
    required this.value,
    required this.sentence,
    required this.count,
  });

  /// The choice (it keys the cross-fade).
  final int value;

  /// The sentence with a `\u0000` where [count] goes.
  final String sentence;
  final String count;

  @override
  Widget build(BuildContext context) {
    final style = appTheme(context).textTheme.bodyLarge!
        .copyWith(color: AppColor.textSecondary);
    final parts = sentence.split('\u0000');
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      child: Text.rich(
        key: ValueKey(value),
        TextSpan(
          style: style,
          children: [
            TextSpan(text: parts.first),
            if (parts.length > 1) ...[
              TextSpan(
                text: count,
                style: const TextStyle(
                  color: AppColor.white,
                  fontWeight: Dimension.textMedium,
                ),
              ),
              TextSpan(text: parts.sublist(1).join()),
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
