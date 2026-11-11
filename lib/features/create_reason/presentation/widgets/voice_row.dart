import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/play_button.dart';
import '../../../../core/widgets/sliding_border.dart';
import '../../../../main.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../voice/presentation/widgets/voice_avatar.dart';

/// One voice as a card: round portrait, name, "Female · American · Warm" and the play
/// button. Draws no selection border itself: put it in a `SlidingBorderTarget` inside
/// a `SlidingBorderScope` so one border glides between rows.
class VoiceRow extends StatelessWidget {
  const VoiceRow({
    super.key,
    required this.voice,
    required this.selected,
    required this.playing,
    required this.onSelect,
    required this.onPlay,
    this.color = AppColor.cardColor,
  });

  final Voice voice;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;

  /// The card's fill (`AppColor.surfaceSecondary` inside a sheet).
  final Color color;

  /// The play / stop button was tapped.
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    // The first of the voice's traits ("Warm · Encouraging" -> "Warm").
    final trait = voice.traits?.split(RegExp(r'[·,]')).first.trim();
    final line = [voice.gender, voice.accent, trait]
        .whereType<String>()
        .where((t) => t.isNotEmpty)
        .join(strings.list_separator);
    final playLabel = playing
        ? strings.voice_stop(voice.name)
        : strings.voice_play(voice.name);
    // One node for screen readers: tap = choose, plus a "Hear / Stop" action.
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: voice.name,
      hint: line,
      excludeSemantics: true,
      onTap: onSelect,
      customSemanticsActions: {CustomSemanticsAction(label: playLabel): onPlay},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: Container(
          constraints: BoxConstraints(minHeight: 62.h),
          padding: REdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(SelectionMotion.radius.r),
          ),
          child: Row(
            children: [
              VoiceAvatar(voice: voice, playing: playing),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    if (line.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: textTheme.bodyLarge!.copyWith(
                          fontSize: 13.5.spMin,
                          height: 18 / 13.5,
                          letterSpacing: 0,
                          fontWeight: selected
                              ? Dimension.textMedium
                              : Dimension.textRegular,
                          color: selected
                              ? AppColor.primary
                              : AppColor.textSecondary,
                        ),
                        child: Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 13.w),
              PlayButton(
                label: playLabel,
                filled: selected,
                playing: playing,
                onTap: onPlay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
