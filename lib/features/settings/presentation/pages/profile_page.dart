import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../core/widgets/app_nav_bar.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';
import '../../../auth/domain/entities/auth_provider.dart';
import '../widgets/account_notices.dart';
import '../widgets/sign_in_sheet.dart';

/// "Profile": who you are. Your first name (the one word every wake-up says out loud;
/// letters only, 24 at most) with "Save" on the bar, and the Account:
///
/// * signed in: "Signed in with" and the provider on the right (Apple, Google, or
///   "This device" for any other account);
/// * not signed in: "Not signed in", then the Apple and Google buttons and what signing
///   in keeps. Signing in links this device's user to the account, or, for an account
///   Eala already has, moves its goals and alarms there: nothing made here is lost.
///
/// Signing out stays on Settings.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: instance<AccountBloc>()..add(const AccountStartedEvent()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final AccountBloc _bloc = context.read<AccountBloc>();
  late final TextEditingController _name = TextEditingController(
    text: _bloc.state.name,
  )..addListener(() => setState(() {}));

  /// "Save" was tapped and its answer has not come yet.
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _typed => _name.text.trim();

  /// Something new, and a name that can be saved.
  bool get _dirty => isValidName(_typed) && _typed != _bloc.state.name;

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    _saving = true;
    _bloc.add(AccountNameSavedEvent(_typed));
  }

  void _signIn(AuthProvider provider) {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    _bloc.add(AccountSignInRequestedEvent(provider));
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    return MultiBlocListener(
      listeners: [
        // A saved name that arrives later (read from the device, or given by Apple /
        // Google with a sign-in) fills the field, unless something is typed in it.
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (a, b) => a.name != b.name,
          listener: (context, state) {
            if (_name.text.trim().isEmpty) _name.text = state.name;
          },
        ),
        // The save went through: the Profile screen has done that job. (A sign-in
        // ending here leaves the screen open, showing the account.)
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (a, b) => _saving && a.busy && !b.busy,
          listener: (context, state) {
            _saving = false;
            if (state.name == _typed) context.pop();
          },
        ),
      ],
      child: AccountNoticeListener(
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppNavBar(
                  title: strings.account_profile_title,
                  backLabel: strings.account_profile_back,
                  onBack: () => context.pop(),
                  trailing: Semantics(
                    button: true,
                    enabled: _dirty,
                    label: strings.account_save,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _dirty ? _save : null,
                      child: SizedBox(
                        height: 44.h,
                        child: Padding(
                          padding: REdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            child: Text(
                              strings.account_save,
                              style: textTheme.titleMedium!.copyWith(
                                fontSize: 17.spMin,
                                letterSpacing: 0,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: REdgeInsets.fromLTRB(24, 0, 24, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _title(strings.account_your_name, top: 14),
                        _NameField(
                          controller: _name,
                          hint: strings.account_name_hint,
                          label: strings.account_name_semantics,
                          onSubmitted: () {
                            if (_dirty) _save();
                          },
                        ),
                        _title(strings.account_section, top: 24),
                        BlocBuilder<AccountBloc, AccountState>(
                          buildWhen: (a, b) =>
                              a.status != b.status || a.busy != b.busy,
                          builder: (context, state) => _Account(
                            status: state.status,
                            busy: state.busy,
                            onSignIn: _signIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text, {required double top}) => Padding(
    padding: REdgeInsets.fromLTRB(2, top, 2, 10),
    child: SectionHeader(title: text),
  );
}

/// The first-name field: a 52-tall cell (radius 14), 17, letters only.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final style = appTheme(context).textTheme.titleMedium!.copyWith(
      fontSize: 17.spMin,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: AppColor.textColor,
    );
    return Container(
      height: 52.h,
      padding: REdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Semantics(
        label: label,
        child: TextField(
          controller: controller,
          style: style,
          cursorColor: AppColor.primary,
          maxLines: 1,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          inputFormatters: [_NameFormatter()],
          decoration: InputDecoration.collapsed(
            hintText: hint,
            hintStyle: style.copyWith(color: AppColor.textMuted),
          ),
          onSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }
}

/// Keeps only what a name may hold (see `sanitizeName`) as it is typed or pasted.
class _NameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = sanitizeName(newValue.text);
    if (clean == newValue.text) return newValue;
    return TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }
}

/// The Account group; signed out, the way in under it.
class _Account extends StatelessWidget {
  const _Account({
    required this.status,
    required this.busy,
    required this.onSignIn,
  });

  final AccountStatus status;
  final bool busy;
  final ValueChanged<AuthProvider> onSignIn;

  @override
  Widget build(BuildContext context) {
    final group = ListGroup(children: [_AccountRow(status: status)]);
    if (status != AccountStatus.signedOut) return group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        group,
        SizedBox(height: 16.h),
        SignInButtons(onChosen: onSignIn, enabled: !busy),
        ListGroupNote(appLanguage(context).settings_sign_in_note),
      ],
    );
  }
}

/// "Signed in with   Apple" / "Not signed in".
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    if (status == AccountStatus.signedOut) {
      return ListGroupRow(
        icon: Assets.icons.settings.user,
        label: strings.settings_not_signed_in,
      );
    }
    return ListGroupRow(
      icon: Assets.icons.settings.user,
      label: strings.account_signed_in_with,
      value: switch (status) {
        AccountStatus.apple => strings.account_provider_apple,
        AccountStatus.google => strings.account_provider_google,
        _ => strings.account_provider_device,
      },
    );
  }
}
