import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../main.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../../../voice/domain/entities/voice.dart';
import 'area_label.dart';
import 'voice_row.dart';

/// A whole reason on one card: the area, the [name] (any widget: a plain text, or a
/// `ReasonNameField` to rename it in place), the purpose, "Why it matters" (left out
/// when [why] is empty), then the voice and the tone side by side.
///
/// Shown when a reason is ready; meant for the reason's own screen and its editor too.
class ReasonSummaryCard extends StatelessWidget {
  const ReasonSummaryCard({
    super.key,
    required this.area,
    required this.name,
    required this.purpose,
    required this.why,
    required this.voice,
    required this.sound,
  });

  final AreaOfLife area;
  final Widget name;
  final String purpose;
  final String why;
  final Voice voice;
  final SoundType sound;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final why = this.why.trim();
    return Container(
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColor.fieldRule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AreaLabel(
                  title: area.title,
                  color: area.color,
                  icon: area.icon,
                ),
                SizedBox(height: 8.h),
                name,
                SizedBox(height: 8.h),
                Text(
                  purpose,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 20.spMin,
                    height: 27 / 20,
                    letterSpacing: -0.2,
                    color: AppColor.textColor,
                  ),
                ),
                if (why.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  SuggestionLabel(strings.reason_ready_why),
                  SizedBox(height: 6.h),
                  Text(
                    why,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge!.copyWith(
                      fontSize: 15.spMin,
                      height: 21 / 15,
                      letterSpacing: 0,
                      color: AppColor.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: AppColor.fieldRule),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: REdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        VoiceAvatar(voice: voice, size: 32),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _Fact(
                            label: strings.reason_ready_voice,
                            value: voice.name,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColor.fieldRule),
                      ),
                    ),
                    padding: REdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: _Fact(
                      label: strings.reason_ready_tone,
                      value: sound.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "VOICE" over "Astra".
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionLabel(label),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appTheme(context).textTheme.bodyLarge!.copyWith(
            fontSize: 15.spMin,
            height: 17.5 / 15,
            fontWeight: Dimension.textMedium,
            letterSpacing: 0,
            color: AppColor.textColor,
          ),
        ),
      ],
    );
  }
}
