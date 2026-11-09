import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/presentation/widgets/reason_emblem.dart';

/// The alarm editor's Reason row (the first row of "What you'll hear"): the Reason's
/// area mark, its name, "Area · Tone" and an orange "Change ›".
///
/// With no [reason] it keeps the same footprint so choosing one fills it in place: a
/// dashed tile that breathes (its orange outline 32 % ↔ 72 %, 2.8 s; still with
/// reduce motion), [title] / [hint] and an orange "[action] ›" - the one decision on
/// the page with no default.
class AlarmReasonRow extends StatelessWidget {
  const AlarmReasonRow({
    super.key,
    required this.reason,
    required this.title,
    required this.hint,
    required this.action,
    required this.onTap,
  });

  final Reason? reason;

  /// Used while there is no [reason] ("Choose a reason" / "Add a reason").
  final String title;
  final String hint;

  /// "Change" with a Reason, "Choose" / "Add" without.
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reason = this.reason;
    final name = reason?.name ?? title;
    final meta = reason == null
        ? hint
        : [
            reason.areaTitle,
            reason.toneTitle,
          ].where((s) => s.isNotEmpty).join(' · ');
    final textTheme = appTheme(context).textTheme;
    return Semantics(
      button: true,
      label: '$name. $meta. $action',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: REdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              reason == null
                  ? const _EmptyTile()
                  : ReasonEmblem(
                      areaName: reason.areaTitle,
                      areaColor: reason.area?.color,
                      areaIcon: reason.area?.icon,
                    ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium!.copyWith(
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                action,
                style: textTheme.bodyLarge!.copyWith(
                  fontSize: 15.5.spMin,
                  fontWeight: Dimension.textMedium,
                  color: AppColor.primary,
                ),
              ),
              SizedBox(width: 3.w),
              AppSvgIcon(
                Assets.icons.page.chevron,
                size: 16.r,
                color: AppColor.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A place for something: a 46 tile (as the area mark) with a plus and a dashed
/// orange outline that breathes. The controller lives only while this tile does.
class _EmptyTile extends StatefulWidget {
  const _EmptyTile();

  @override
  State<_EmptyTile> createState() => _EmptyTileState();
}

class _EmptyTileState extends State<_EmptyTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _alpha = _breath.drive(
    Tween<double>(
      begin: 0.32,
      end: 0.72,
    ).chain(CurveTween(curve: Curves.easeInOut)),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // 32 % -> 72 % -> 32 % every 2.8 s; still (50 %) with reduce motion.
    MediaQuery.disableAnimationsOf(context)
        ? _breath.value = 0.45
        : _breath.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _DashedTile(_alpha),
        child: Container(
          width: 46.r,
          height: 46.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: AppSvgIcon(
            Assets.icons.page.plus,
            size: 20.r,
            color: AppColor.primary,
          ),
        ),
      ),
    );
  }
}

/// A 1.5 dashed rounded square whose opacity follows [alpha] (repaints only itself).
class _DashedTile extends CustomPainter {
  _DashedTile(this.alpha) : super(repaint: alpha);

  final Animation<double> alpha;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 1.5;
    final radius = 15 * size.width / 46 - w / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = AppColor.primary.withValues(alpha: alpha.value);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7.5) {
        canvas.drawPath(m.extractPath(d, (d + 4.5).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedTile old) => old.alpha != alpha;
}
