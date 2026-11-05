import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import '../theme/dimension.dart';
import 'app_svg_icon.dart';
import 'cached_svg_icon.dart';
import 'rise_in.dart';

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

/// The motion of the choice list, as designed (framer-motion springs).
abstract final class _SelectMotion {
  static const borderSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 36,
  );
  static const checkSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 24,
  );
  static const double radius = 12;
}

/// A single-choice list of cards (area of life, tone, ...) with the app's selection
/// animation, so every choice list moves the same way:
///
/// * The orange 1 dp border is ONE shared element, not one per row. When the selection
///   changes it springs from the old row to the new row; tapping again mid-flight sets
///   off from wherever it is. The first selection just appears.
/// * The chosen row's icon pops (scale 1 → 0.84 → 1.12 → 1 over 450 ms).
/// * Its subtitle turns orange and medium weight; the right circle fills orange and the
///   check springs in with a small overshoot.
/// * Rows rise in when they first appear (staggered), so rows that arrive later from
///   the server animate in too while the existing ones stay still.
///
/// It lays rows out in a Column: put it inside the page's scroll view.
class AnimatedSelectList extends StatefulWidget {
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
  State<AnimatedSelectList> createState() => AnimatedSelectListState();
}

class AnimatedSelectListState extends State<AnimatedSelectList>
    with SingleTickerProviderStateMixin {
  final _stackKey = GlobalKey();
  final _rowKeys = <Object, GlobalKey>{};

  // 0 -> 1 between [_from] and [_to]; unbounded so the spring may overshoot.
  late final AnimationController _move = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  Rect? _from;
  Rect? _to;

  /// Where the border is drawn right now (null = nothing selected).
  @visibleForTesting
  Rect? get indicatorRect {
    if (_to == null) return null;
    if (_from == null) return _to;
    return Rect.lerp(_from, _to, _move.value);
  }

  GlobalKey _keyFor(Object id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  Rect? _rectOf(Object? id) {
    if (id == null) return null;
    final row = _rowKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (row == null || stack == null || !row.hasSize) return null;
    return row.localToGlobal(Offset.zero, ancestor: stack) & row.size;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
  }

  @override
  void didUpdateWidget(AnimatedSelectList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      // Rows are laid out after this build; slide once their rects are known.
      WidgetsBinding.instance.addPostFrameCallback((_) => _slideToSelected());
    }
  }

  void _jumpToSelected() {
    if (!mounted) return;
    setState(() {
      _from = null;
      _to = _rectOf(widget.selectedId);
      _move.value = 1;
    });
  }

  void _slideToSelected() {
    if (!mounted) return;
    final target = _rectOf(widget.selectedId);
    final current = indicatorRect;
    if (target == null || current == null) {
      // Nothing was selected before (or nothing is now): appear / disappear in place.
      _jumpToSelected();
      return;
    }
    _from = current;
    _to = target;
    _move
      ..value = 0
      ..animateWith(SpringSimulation(_SelectMotion.borderSpring, 0, 1, 0));
  }

  /// Keeps the border on its row if the layout changes while it is at rest
  /// (rotation, text scale, rows arriving from the server).
  void _followLayout() {
    if (!mounted || _move.isAnimating) return;
    final target = _rectOf(widget.selectedId);
    if (target != _to || _from != null) {
      setState(() {
        _from = null;
        _to = target;
        _move.value = 1;
      });
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _followLayout());
    final items = widget.items;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Stack(
        key: _stackKey,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(height: 8.h),
                // The key sits outside the rise-in transform, so the border is
                // measured against where the row rests, not where it is rising from.
                KeyedSubtree(
                  key: _keyFor(items[i].id),
                  child: RiseIn(
                    enabled: widget.animateIn,
                    delay: Duration(milliseconds: 80 + i * 30),
                    child: SelectRow(
                      key: ValueKey(items[i].id),
                      item: items[i],
                      selected: items[i].id == widget.selectedId,
                      onTap: () => widget.onSelected(items[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // The one shared border, drawn above the rows and never taking taps.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectionBorderPainter(this, _SelectMotion.radius.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the orange 1 dp inside border at the list's current indicator rect.
class _SelectionBorderPainter extends CustomPainter {
  _SelectionBorderPainter(this.state, this.radius)
    : super(repaint: state._move);

  final AnimatedSelectListState state;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = state.indicatorRect;
    if (r == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        r.deflate(
          0.5,
        ), // a 1 dp stroke centred 0.5 dp in = fully inside the card
        Radius.circular(radius - 0.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColor.primary
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SelectionBorderPainter old) => true;
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

class _SelectRowState extends State<SelectRow> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: 1,
  );
  late final AnimationController _check = AnimationController.unbounded(
    vsync: this,
    value: widget.selected ? 1 : 0,
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
    if (widget.selected && !oldWidget.selected) {
      _pop.forward(from: 0);
      _check
        ..value = 0
        ..animateWith(SpringSimulation(_SelectMotion.checkSpring, 0, 1, 0));
    } else if (!widget.selected && oldWidget.selected) {
      _check.value = 0; // the check goes at once, with no exit animation
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _check.dispose();
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
            borderRadius: BorderRadius.circular(_SelectMotion.radius.r),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on
                      ? AppColor.primary
                      : AppColor.primary.withValues(alpha: 0),
                  border: Border.all(
                    color: on
                        ? AppColor.selectRing.withValues(alpha: 0)
                        : AppColor.selectRing,
                    width: 1.5.r,
                  ),
                ),
                child: on
                    ? AnimatedBuilder(
                        animation: _check,
                        builder: (_, child) => Transform.scale(
                          scale: _check.value.clamp(0.0, 2.0),
                          child: child,
                        ),
                        child: AppSvgIcon(
                          Assets.icons.check,
                          size: 15.r,
                          color: AppColor.onPrimary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
