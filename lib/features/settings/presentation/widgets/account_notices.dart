import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../main.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_state.dart';

/// Says what the account just could not do (a sign-in, a sign-out or a name that failed)
/// in a snackbar, once. Only the screen on top speaks, so two open screens never say it
/// twice.
class AccountNoticeListener extends StatelessWidget {
  const AccountNoticeListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listenWhen: (a, b) =>
          a.noticeCount != b.noticeCount && b.notice != AccountNotice.none,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent == false) return;
        final strings = appLanguage(context);
        final text = switch (state.notice) {
          AccountNotice.signInFailed => strings.account_sign_in_failed,
          AccountNotice.signOutFailed => strings.account_sign_out_failed,
          AccountNotice.nameFailed => strings.account_name_failed,
          AccountNotice.none => null,
        };
        if (text == null) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      },
      child: child,
    );
  }
}
