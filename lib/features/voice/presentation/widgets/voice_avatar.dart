import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/playing_ring.dart';
import '../../../../main.dart';
import '../../domain/entities/voice.dart';

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
