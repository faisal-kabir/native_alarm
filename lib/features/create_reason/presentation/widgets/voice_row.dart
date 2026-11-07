import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/play_button.dart';
import '../../../../core/widgets/playing_ring.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/sliding_border.dart';
import '../../../../main.dart';
import '../../../voice/domain/entities/voice.dart';

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
  });

  final Voice voice;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;

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
            color: AppColor.cardColor,
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

/// The voice's round portrait (`voice.avatarUrl`, cached on the device) over a disc
/// in its tint; the first letter of its name when it has no picture or it fails.
/// While its sample plays it wears the breathing [PlayingRing].
class VoiceAvatar extends StatelessWidget {
  const VoiceAvatar({
    super.key,
    required this.voice,
    this.playing = false,
    this.size = 42,
  });

  final Voice voice;
  final bool playing;

  /// Diameter before scaling (`.r` is applied here).
  final double size;

  @override
  Widget build(BuildContext context) {
    final size = this.size.r;
    final tint = AppColor.tintOf(voice.color);
    final letter = Center(
      child: Text(
        initialOf(voice.name),
        style: appTheme(context).textTheme.titleMedium!
            .copyWith(fontSize: size * 0.43, color: tint),
      ),
    );
    final url = voice.avatarUrl;
    final decode = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ExcludeSemantics(
      child: PlayingRing(
        active: playing,
        child: ClipOval(
          child: SizedBox.square(
            dimension: size,
            child: ColoredBox(
              color: tint.withValues(alpha: 0.15),
              child: url == null
                  ? letter
                  : CachedNetworkImage(
                      imageUrl: url,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      // Decoded at the size it is shown, not the file's full size.
                      memCacheWidth: decode,
                      memCacheHeight: decode,
                      fadeInDuration: const Duration(milliseconds: 250),
                      errorWidget: (_, _, _) => letter,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
