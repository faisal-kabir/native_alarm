import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../constants/app_constant.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';
import 'rise_in.dart';
import 'shimmer.dart';

/// One suggestion of [SuggestionList].
class SuggestionItem {
  const SuggestionItem({required this.id, required this.text});

  final Object id;
  final String text;
}

/// Suggested wording under a text field: a small upper-case [label], then
/// [AppConstant.suggestionsPerPage] suggestions at a time; "More ideas" adds as many
/// again (only when [expandable]). Each suggestion arrives on its own (10 up, out of a light blur, 420 ms).
class SuggestionList extends StatefulWidget {
  const SuggestionList({
    super.key,
    required this.label,
    required this.items,
    required this.onPick,
    this.expandable = true,
  });

  final String label;
  final List<SuggestionItem> items;
  final ValueChanged<SuggestionItem> onPick;
  final bool expandable;

  @override
  State<SuggestionList> createState() => _SuggestionListState();
}

class _SuggestionListState extends State<SuggestionList> {
  static const _per = AppConstant.suggestionsPerPage;
  int _count = _per;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final shown = widget.items.take(_count).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionLabel(widget.label),
        SizedBox(height: 10.h),
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          // Each one arrives 10 up, out of a soft blur, 420 ms.
          RiseIn(
            key: ValueKey(shown[i].id),
            delay: Duration(milliseconds: 40 + (i % _per) * 60),
            duration: const Duration(milliseconds: 420),
            dy: 10,
            blur: 2,
            child: _SuggestionPill(
              text: shown[i].text,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPick(shown[i]);
              },
            ),
          ),
        ],
        if (widget.expandable && _count < widget.items.length)
          Padding(
            padding: REdgeInsets.only(top: 10),
            child: Semantics(
              button: true,
              label: strings.suggestions_more_ideas_semantics,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _count += _per);
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 44.h),
                  child: Padding(
                    padding: REdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          strings.suggestions_more_ideas,
                          style: textTheme.bodyLarge!.copyWith(
                            fontSize: 15.spMin,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.15,
                            color: AppColor.textTertiary,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // The forward chevron turned to point down.
                        RotatedBox(
                          quarterTurns: 1,
                          child: AppSvgIcon(
                            Assets.icons.page.chevron,
                            size: 15.r,
                            color: AppColor.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The small upper-case heading above suggestions ("OR START FROM ONE OF THESE").
class SuggestionLabel extends StatelessWidget {
  const SuggestionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: appTheme(context).textTheme.labelSmall!.copyWith(
        fontSize: 11.5.spMin,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.61,
        color: color ?? AppColor.textTertiary,
      ),
    );
  }
}

/// Placeholder for [SuggestionList] while its suggestions load: three shimmering pills.
class SuggestionListSkeleton extends StatelessWidget {
  const SuggestionListSkeleton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionLabel(label),
        SizedBox(height: 10.h),
        ExcludeSemantics(
          child: Shimmer(
            baseColor: AppColor.cardColor,
            highlightColor: AppColor.surfaceSecondary,
            child: Column(
              children: [
                for (var i = 0; i < AppConstant.suggestionsPerPage; i++) ...[
                  if (i > 0) SizedBox(height: 8.h),
                  Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// In place of [SuggestionList] (or any small piece of loaded content) when it could
/// not be loaded: a short note ([text], "Couldn't load ideas." by default) and "Try
/// again".
class SuggestionError extends StatelessWidget {
  const SuggestionError({super.key, required this.onRetry, this.text});

  final VoidCallback onRetry;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    return Row(
      children: [
        Flexible(
          child: Text(
            text ?? strings.suggestions_load_failed,
            style: textTheme.bodySmall!.copyWith(color: AppColor.textTertiary),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRetry,
          child: Padding(
            padding: REdgeInsets.all(8),
            child: Text(
              strings.common_try_again,
              style: textTheme.labelLarge!.copyWith(color: AppColor.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.cardColor,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: REdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Text(
              text,
              style: appTheme(context).textTheme.bodyLarge!.copyWith(
                fontSize: 15.spMin,
                height: 1.35,
                letterSpacing: 0,
                color: AppColor.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
