import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../main.dart';
import '../theme/app_color.dart';
import '../theme/dimension.dart';
import 'cached_svg_icon.dart';
import 'check_circle.dart';
import 'rise_in.dart';
import 'sliding_border.dart';

/// One row of [AnimatedSelectList].
class SelectItem {
  const SelectItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.tint,
    this.iconPath,
  });

  final Object id;
  final String title;
  final String? subtitle;

  /// The row's colour: its icon and the tile behind it.
  final Color tint;

  /// Server path of a single-colour SVG painted in [tint] (see `mediaUrl`). Without
  /// one (or when it can not be loaded) the first letter of [title] is shown instead.
  final String? iconPath;
}

/// A single-choice list of cards (area of life, tone, ...) with the app's selection
/// animation, so every choice list moves the same way:
///
/// * The orange 1 dp border is ONE shared element ([SlidingBorderScope]), not one per
///   row: it springs from the old row to the new one.
/// * The chosen row's icon pops (scale 1 → 0.84 → 1.12 → 1 over 450 ms).
/// * Its subtitle turns orange and medium weight; the right circle fills orange and the
///   check springs in with a small overshoot.
/// * Rows rise in when they first appear (staggered), so rows that arrive later from
///   the server animate in too while the existing ones stay still.
///
/// It lays rows out in a Column: put it inside the page's scroll view.
class AnimatedSelectList extends StatelessWidget {
  const AnimatedSelectList({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.animateIn = true,
  });

  final List<SelectItem> items;
  final Object? selectedId;
  final ValueChanged<SelectItem> onSelected;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SlidingBorderScope(
        selectedId: selectedId,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: 8.h),
              // The target sits outside the rise-in transform, so the border is
              // measured against where the row rests, not where it is rising from.
              SlidingBorderTarget(
                id: items[i].id,
                child: RiseIn(
                  enabled: animateIn,
                  delay: Duration(milliseconds: 80 + i * 30),
                  child: SelectRow(
                    key: ValueKey(items[i].id),
                    item: items[i],
                    selected: items[i].id == selectedId,
                    onTap: () => onSelected(items[i]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One card row. It draws no border of its own: [AnimatedSelectList] moves one border
/// between rows.
class SelectRow extends StatefulWidget {
  const SelectRow({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SelectItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<SelectRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );

  // Keyframes [1, 0.84, 1.12, 1], evenly spaced, ease-out on each leg.
  late final Animation<double> _popScale = TweenSequence<double>([
    for (final (begin, end) in const [(1.0, 0.84), (0.84, 1.12), (1.12, 1.0)])
      TweenSequenceItem(
        tween: Tween<double>(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(SelectRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Widget _leading(BuildContext context) {
    final item = widget.item;
    final trimmed = item.title.trim();
    final letter = Text(
      trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase(),
      style: appTheme(context).textTheme.titleMedium!
          .copyWith(fontSize: 18.spMin, color: item.tint),
    );
    final path = item.iconPath;
    if (path == null || path.isEmpty) return letter;
    return CachedSvgIcon(
      path: path,
      size: 20.r,
      color: item.tint,
      fallback: Center(child: letter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final on = widget.selected;
    final textTheme = appTheme(context).textTheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      button: true,
      label: item.title,
      hint: item.subtitle,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 62.h),
          padding: REdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: AppColor.cardColor,
            borderRadius: BorderRadius.circular(SelectionMotion.radius.r),
          ),
          child: Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.tint.withValues(alpha: 0x1F / 255),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ScaleTransition(
                  scale: _popScale,
                  child: _leading(context),
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    if (item.subtitle != null) ...[
                      SizedBox(height: 1.h),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 13.5.spMin,
                          height: 18.225 / 13.5,
                          letterSpacing: 0,
                          fontWeight: on
                              ? Dimension.textMedium
                              : Dimension.textRegular,
                          color: on ? AppColor.primary : AppColor.textSecondary,
                        ),
                        child: Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 13.w),
              CheckCircle(on: on),
            ],
          ),
        ),
      ),
    );
  }
}
