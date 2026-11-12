import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import '../theme/dimension.dart';
import 'app_svg_icon.dart';

/// A rounded card holding [ListGroupRow]s split by hairlines (Settings, a reason's
/// screen). Inside a sheet it is `AppColor.surfaceSecondary` with radius 14.
class ListGroup extends StatelessWidget {
  const ListGroup({
    super.key,
    required this.children,
    this.color = AppColor.cardColor,
    this.radius = 22,
  });

  final List<Widget> children;
  final Color color;

  /// Corner radius before scaling (`.r` is applied here).
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius.r),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColor.divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A line under a [ListGroup] saying what its rows mean ("These settings don't affect
/// your alarms.", what signing in keeps).
class ListGroupNote extends StatelessWidget {
  const ListGroupNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Text(
        text,
        style: appTheme(context).textTheme.bodyLarge!
            .copyWith(height: 1.45, letterSpacing: 0),
      ),
    );
  }
}

/// One row of a [ListGroup]: icon, label, then an optional value, trailing widget (a
/// switch) and chevron. At least 52 tall; grows with the text.
///
/// [leading] replaces the [icon] (e.g. a server icon). [highlight] turns the value
/// orange (a changed value, or an empty one asking to be added), with a short fade.
/// [tint] colours the icon, label and chevron (an action row: "Connect an alarm");
/// [iconColor] the icon alone (a goal's alarm: an orange clock, a white time).
class ListGroupRow extends StatelessWidget {
  const ListGroupRow({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    this.value,
    this.highlight = false,
    this.trailing,
    this.chevron = false,
    this.danger = false,
    this.tint,
    this.iconColor,
    this.sentence = false,
    this.semanticsLabel,
    this.onTap,
  }) : assert(icon != null || leading != null);

  final SvgGenImage? icon;
  final Widget? leading;
  final String label;
  final String? value;
  final bool highlight;
  final Widget? trailing;
  final bool chevron;
  final bool danger;
  final Color? tint;
  final Color? iconColor;

  /// A row whose value is a whole sentence (a goal, a why): the label keeps one short
  /// width so two sentences of different lengths start their words in the same place,
  /// and the value reads from the left.
  final bool sentence;

  /// What a screen reader says for the whole row (label and value by default).
  final String? semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    // Row text is the 17 role without its bold weight.
    final rowText = textTheme.titleMedium!.copyWith(
      fontWeight: Dimension.textRegular,
    );
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: danger
          ? rowText.copyWith(
              fontWeight: Dimension.textSemiBold,
              color: AppColor.danger,
            )
          : rowText.copyWith(color: tint ?? AppColor.titleColor),
    );
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: 52.h),
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            leading ??
                AppSvgIcon(
                  icon!,
                  size: 22.r,
                  color: danger
                      ? AppColor.danger
                      : iconColor ?? tint ?? AppColor.textSecondary,
                ),
            SizedBox(width: 12.w),
            if (value == null)
              Expanded(child: labelText)
            else ...[
              // The label keeps its words (up to half the row); a long value gives
              // way and ends in "…".
              if (sentence)
                SizedBox(width: 42.w, child: labelText)
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: (1.sw - 48.w) * 0.5),
                  child: labelText,
                ),
              SizedBox(width: 12.w),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: rowText.copyWith(
                    color: highlight
                        ? AppColor.primary
                        : AppColor.textSecondary,
                  ),
                  child: Text(
                    value!,
                    textAlign: sentence ? TextAlign.left : TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            if (trailing != null) ...[SizedBox(width: 12.w), trailing!],
            if (chevron) ...[
              SizedBox(width: 12.w),
              AppSvgIcon(
                Assets.icons.page.chevron,
                size: 19.r,
                color: tint?.withValues(alpha: 0.7) ?? AppColor.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
    // A row with a switch is not a button: the switch is the control.
    if (onTap == null && trailing != null) {
      return MergeSemantics(child: content);
    }
    final row = InkWell(onTap: onTap, child: content);
    if (semanticsLabel == null) return row;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: row,
    );
  }
}

/// A [ListGroupRow] ending in an iOS-style switch (51 x 31, green when on): Settings'
/// notifications, an alarm's "Enabled".
class ListGroupSwitchRow extends StatelessWidget {
  const ListGroupSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final SvgGenImage icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListGroupRow(
      icon: icon,
      label: label,
      trailing: AppSwitch(value: value, onChanged: onChanged),
    );
  }
}

/// The app's on / off switch (iOS style, 51 x 31, green when on). [label] names it
/// for a screen reader when no row text does.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColor.toggleOn,
        inactiveTrackColor: AppColor.toggleOff,
        thumbColor: AppColor.white,
      ),
    );
  }
}
