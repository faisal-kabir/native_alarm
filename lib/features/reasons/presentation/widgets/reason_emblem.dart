import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../voice/presentation/widgets/voice_avatar.dart';
import '../../../voice/domain/entities/voice.dart';

/// Whether an alarm plays a reason: none = no badge, on = orange, off = grey.
enum ReasonAlarmBadge { none, on, off }

/// A goal's mark: the face of the voice that speaks it, the same picture on My Goals, the
/// goal's own screen, its alarm card, the picker and the editor, so a goal is one
/// recognisable thing everywhere (the prototype's `CueEmblem`). It replaced a monogram of
/// the area, which only repeated the title printed beside it.
///
/// [voice] is the joined voice (a round portrait over its tint; the first letter of
/// [name] when it has none or the picture fails). [size] (46 before scaling) is the
/// diameter. [muted] is a switched-off alarm: the face greyed and dimmed to half, the
/// colour coming back with the alarm (0.3 s). [badge] adds the alarm mark (22 + 2.5
/// black ring) hanging off the lower-right corner.
class ReasonEmblem extends StatelessWidget {
  const ReasonEmblem({
    super.key,
    required this.voice,
    required this.name,
    this.badge = ReasonAlarmBadge.none,
    this.size = 46,
    this.muted = false,
  });

  final Voice? voice;

  /// The goal's name: its first letter stands in when there is no voice picture.
  final String name;
  final ReasonAlarmBadge badge;
  final double size;
  final bool muted;

  /// One colour matrix for the whole switched-off look: [s] = 1 is the face as it is,
  /// 0 is grey at half strength. Saturation and opacity in one filter (one layer).
  @visibleForTesting
  static ColorFilter mutedFilter(double s) {
    final alpha = 0.5 + 0.5 * s;
    return ColorFilter.matrix([
      0.2126 + 0.7874 * s, 0.7152 - 0.7152 * s, 0.0722 - 0.0722 * s, 0, 0, //
      0.2126 - 0.2126 * s, 0.7152 + 0.2848 * s, 0.0722 - 0.0722 * s, 0, 0, //
      0.2126 - 0.2126 * s, 0.7152 - 0.7152 * s, 0.0722 + 0.9278 * s, 0, 0, //
      0, 0, 0, alpha, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final face = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: muted ? 0 : 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 300),
      curve: const Cubic(0.25, 0.1, 0.25, 1),
      // In full colour (the usual case) no filter at all.
      builder: (context, s, child) => s >= 1
          ? child!
          : ColorFiltered(colorFilter: mutedFilter(s), child: child),
      child: VoiceAvatar(
        voice: voice ?? Voice(id: 0, name: name, voiceId: ''),
        size: size,
      ),
    );
    return SizedBox(
      width: size.r,
      height: size.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: face),
          if (badge != ReasonAlarmBadge.none)
            Positioned(
              right: -7.8.r,
              bottom: -7.8.r,
              child: _AlarmBadgeMark(on: badge == ReasonAlarmBadge.on),
            ),
        ],
      ),
    );
  }
}

class _AlarmBadgeMark extends StatelessWidget {
  const _AlarmBadgeMark({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27.r, // 22 + 2 x 2.5 ring
      height: 27.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColor.primary : AppColor.badgeOff,
        border: Border.all(color: AppColor.backgroundColor, width: 2.5.r),
      ),
      child: AppSvgIcon(
        on ? Assets.icons.alarm : Assets.icons.alarmOff,
        size: 15.r,
        color: on ? AppColor.onPrimary : AppColor.textSecondary,
      ),
    );
  }
}
