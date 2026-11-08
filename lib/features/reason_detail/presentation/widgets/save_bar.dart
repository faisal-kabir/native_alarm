import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../main.dart';

/// "Save Changes" + "Discard" and the caption under them, shown while [visible] (the
/// reason has held changes). It slides up from the bottom edge on a spring (stiffness
/// 420, damping 36, mass 0.8) while it fades in, and back down when it goes; it stays
/// mounted until it is gone. Transitions only: nothing rebuilds per frame.
class SaveBar extends StatefulWidget {
  const SaveBar({
    super.key,
    required this.visible,
    required this.saving,
    required this.onSave,
    required this.onDiscard,
  });

  final bool visible;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  State<SaveBar> createState() => _SaveBarState();
}

class _SaveBarState extends State<SaveBar> with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 0.8,
    stiffness: 420,
    damping: 36,
  );

  late final AnimationController _shown = AnimationController.unbounded(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );
  late final Animation<Offset> _slide = _shown.drive(
    Tween(begin: const Offset(0, 1), end: Offset.zero),
  );
  late bool _mounted = widget.visible;

  @override
  void didUpdateWidget(SaveBar old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    final still = MediaQuery.disableAnimationsOf(context);
    final target = widget.visible ? 1.0 : 0.0;
    if (widget.visible) _mounted = true;
    if (still) {
      _shown.value = target;
      _mounted = widget.visible;
      return;
    }
    _shown
        .animateWith(SpringSimulation(_spring, _shown.value, target, 0))
        .whenComplete(() {
          if (mounted && !widget.visible) setState(() => _mounted = false);
        });
  }

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mounted) return const SizedBox.shrink();
    final strings = appLanguage(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _shown,
          child: ColoredBox(
            color: AppColor.backgroundColor,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, bottom + 6.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: widget.saving
                              ? strings.common_saving
                              : strings.reason_detail_save,
                          enabled: !widget.saving,
                          onPressed: widget.onSave,
                        ),
                      ),
                      SizedBox(width: 9.w),
                      SizedBox(
                        width: 108.w,
                        child: PillButton(
                          label: strings.reason_detail_discard,
                          enabled: !widget.saving,
                          quiet: true,
                          disabledColor: AppColor.surfaceSecondary,
                          onPressed: widget.onDiscard,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    strings.reason_detail_caption,
                    textAlign: TextAlign.center,
                    style: appTheme(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 15.spMin,
                      height: 21.75 / 15,
                      letterSpacing: 0,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
