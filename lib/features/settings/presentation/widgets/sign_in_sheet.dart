import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../../auth/domain/entities/auth_provider.dart';

/// The sign-in sheet: "Keep your goals safe", one line, and the two providers' buttons.
/// Returns the provider the person tapped, null when they closed it (the ✕, a swipe down
/// or the scrim are the way out: nothing here insists).
Future<AuthProvider?> showSignInSheet(BuildContext context) =>
    showAppSheet<AuthProvider>(context, builder: (_) => const _SignInSheet());

class _SignInSheet extends StatelessWidget {
  const _SignInSheet();

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return AppSheet(
      title: strings.account_sign_in_title,
      subtitle: strings.account_sign_in_subtitle,
      body: Padding(
        padding: REdgeInsets.fromLTRB(20, 4, 20, 14),
        child: SignInButtons(onChosen: AppSheetScope.of(context).close),
      ),
    );
  }
}

/// The one Apple / Google pair of the app (the sign-in sheet's and Profile's). Apple's
/// button goes where Apple sign-in works: on an iPhone (Android has no Apple sheet;
/// Google is enough there). While [enabled] is false (a sign-in on its way) the pair
/// is dimmed and does not answer.
class SignInButtons extends StatelessWidget {
  const SignInButtons({super.key, required this.onChosen, this.enabled = true});

  final ValueChanged<AuthProvider> onChosen;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: const Duration(milliseconds: 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (defaultTargetPlatform != TargetPlatform.android) ...[
              AuthButton(
                label: strings.account_sign_in_apple,
                background: AppColor.white,
                foreground: AppColor.onPrimary,
                icon: AppSvgIcon(
                  Assets.icons.auth.apple,
                  size: 19.r,
                  color: AppColor.onPrimary,
                ),
                onTap: () => onChosen(AuthProvider.apple),
              ),
              SizedBox(height: 10.h),
            ],
            AuthButton(
              label: strings.account_sign_in_google,
              background: AppColor.surfaceSecondary,
              foreground: AppColor.textColor,
              icon: Assets.icons.auth.google.svg(
                width: 18.r,
                height: 18.r,
                excludeFromSemantics: true,
              ),
              onTap: () => onChosen(AuthProvider.google),
            ),
          ],
        ),
      ),
    );
  }
}

/// A provider's button, drawn the way the provider draws it (Apple's cream-white with a
/// dark mark, Google's with its own four-colour G), never in the app's orange: a button
/// that looks like ours is not trusted as theirs. A 58-tall pill.
class AuthButton extends StatefulWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget icon;
  final VoidCallback onTap;

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            height: 58.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(AppConstant.pillRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.icon,
                SizedBox(width: 8.w),
                Text(
                  widget.label,
                  style: appTheme(context).textTheme.titleMedium!
                      .copyWith(color: widget.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
