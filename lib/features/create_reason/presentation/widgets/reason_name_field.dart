import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';

/// A reason's name, editable in place.
///
/// * At rest: the name (17 / semibold) with a small round pencil chip beside it.
/// * A tap anywhere on it opens it; the caret goes to the END of the name (a tap on
///   the text itself keeps its own caret), never selecting everything.
/// * While open the chip becomes an orange round check (the visible "done"), a thin
///   orange line fades in under the text, the row grows a little. Keyboard "done", the
///   check and a tap anywhere else all save; Escape puts the old name back.
/// * An empty or unchanged name is dropped (the old one comes back); a real change
///   goes to [onCommit] with one light haptic.
/// * The field is as wide as its text (8 to 24 characters' worth), never wider than
///   the row; at rest a long name ends in "…".
class ReasonNameField extends StatefulWidget {
  const ReasonNameField({
    super.key,
    required this.value,
    required this.onCommit,
  });

  final String value;

  /// The trimmed new name, only when it is non-empty and different.
  final ValueChanged<String> onCommit;

  @override
  State<ReasonNameField> createState() => _ReasonNameFieldState();
}

class _ReasonNameFieldState extends State<ReasonNameField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();
  bool _naming = false;
  bool _cancelled = false;

  /// A touch that landed on the text itself keeps its own caret.
  bool _onText = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(ReasonNameField old) {
    super.didUpdateWidget(old);
    // Also when the value came back unchanged (a rename that failed fast).
    if (!_naming && _c.text != widget.value) {
      _c.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_focusChanged)
      ..dispose();
    _c.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (_focus.hasFocus) {
      setState(() => _naming = true);
      if (!_onText) {
        // The platform places its own caret after focus; move it on the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_focus.hasFocus) return;
          _c.selection = TextSelection.collapsed(offset: _c.text.length);
        });
      }
    } else {
      _finish();
    }
  }

  void _finish() {
    setState(() => _naming = false);
    _onText = false;
    if (_cancelled) {
      _cancelled = false;
      _c.text = widget.value;
      return;
    }
    final clean = _c.text.trim();
    if (clean.isNotEmpty && clean != widget.value) {
      HapticFeedback.lightImpact();
      _c.text = clean;
      widget.onCommit(clean);
    } else {
      _c.text = widget.value;
    }
  }

  /// Width of the field: (clamp(characters, 8, 24) * 0.56 + 0.4) em of the text.
  double _width(double room, double fontSize) {
    final n = _c.text.length.clamp(8, 24);
    return ((n * 0.56 + 0.4) * fontSize).clamp(0.0, room);
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final fontSize = 17.spMin;
    final style = appTheme(context).textTheme.titleMedium!.copyWith(
      fontSize: fontSize,
      height: 20 / 17,
      letterSpacing: -0.2,
      color: AppColor.textColor,
    );
    final chip = (_naming ? 30 : 26).r;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_focus.hasFocus) _focus.requestFocus();
      },
      child: LayoutBuilder(
        builder: (context, constraints) => ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final room = (constraints.maxWidth - 6.w - chip).clamp(0.0, 1e9);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _width(room, fontSize),
                  child: Semantics(
                    container: true,
                    label: strings.reason_name_label,
                    child: _input(style),
                  ),
                ),
                SizedBox(width: 6.w),
                _naming
                    ? _SpringIn(
                        key: const ValueKey('save'),
                        spring: const SpringDescription(
                          mass: 1,
                          stiffness: 520,
                          damping: 22,
                        ),
                        child: _SaveButton(
                          label: strings.reason_name_save,
                          onTap: _focus.unfocus,
                        ),
                      )
                    : const _SpringIn(
                        key: ValueKey('edit'),
                        spring: SpringDescription(
                          mass: 1,
                          stiffness: 520,
                          damping: 26,
                        ),
                        child: ExcludeSemantics(child: _PencilChip()),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _input(TextStyle style) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
      height: 23.h,
      padding: REdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColor.primary.withValues(alpha: _naming ? 0.55 : 0),
          ),
        ),
      ),
      child: Focus(
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _cancelled = true;
            _focus.unfocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerDown: (_) => _onText = true,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // At rest the name is drawn here, so a long one can end in "…".
              if (!_naming)
                IgnorePointer(
                  child: Text(
                    _c.text,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              TextField(
                controller: _c,
                focusNode: _focus,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    AppConstant.reasonNameMaxLength,
                  ),
                ],
                style: _naming
                    ? style
                    : style.copyWith(color: AppColor.transparent),
                cursorColor: AppColor.primary,
                cursorWidth: 1.5,
                decoration: InputDecoration.collapsed(
                  hintText: appLanguage(context).reason_name_hint,
                  hintStyle: style.copyWith(
                    color: AppColor.textTertiary,
                    fontWeight: Dimension.textRegular,
                  ),
                ),
                onTapOutside: (_) => _focus.unfocus(),
                onSubmitted: (_) => _focus.unfocus(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scale 0.6 → 1 and fade in on a spring, once, when it appears.
class _SpringIn extends StatefulWidget {
  const _SpringIn({super.key, required this.spring, required this.child});

  final SpringDescription spring;
  final Widget child;

  @override
  State<_SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<_SpringIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.animateWith(SpringSimulation(widget.spring, 0, 1, 0));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _c.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * _c.value, child: child),
      ),
    );
  }
}

/// The small round chip with the pencil: the name can be changed.
class _PencilChip extends StatelessWidget {
  const _PencilChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26.r,
      height: 26.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColor.surfaceSecondary,
        shape: BoxShape.circle,
      ),
      child: AppSvgIcon(
        Assets.icons.pencil,
        size: 12.r,
        color: AppColor.textSecondary,
      ),
    );
  }
}

/// The orange round "done" button with a black check. It is part of the field's tap
/// region, so tapping it does not count as "a tap elsewhere" (that would close the
/// field and remove the button before the tap lands).
class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: Semantics(
        container: true,
        button: true,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? 0.9 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 30.r,
              height: 30.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColor.primary,
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(
                Assets.icons.check,
                size: 15.r,
                color: AppColor.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
