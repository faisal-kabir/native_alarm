import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/account_notices.dart';
import '../widgets/horizon.dart';
import '../widgets/profile_card.dart';
import '../widgets/sign_in_sheet.dart';
import '../../../../core/widgets/list_group.dart';

/// The "Settings" tab of the Dashboard.
///
/// The account is told in two places, by who is signed in ([AccountBloc]):
///
/// * the card at the top: the name (or "Set your name"), and under it "Signed in with
///   Apple" / "Signed in with Google" / "Signed in on this device" / "Not signed in";
///   it opens Profile;
/// * the Account group: signed in, "Sign Out" (after a question); not signed in, "Sign In"
///   (the sheet with the Apple and Google buttons) and, under the group, what is at stake.
///
/// "Delete account" is there either way. The Premium badge and credits come with the
/// subscription feature.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (BuildContext context) =>
              instance<SettingsBloc>()..add(const LoadSettingsEvent()),
        ),
        // One shared account for every screen that shows it; never closed here.
        BlocProvider.value(
          value: instance<AccountBloc>()..add(const AccountStartedEvent()),
        ),
      ],
      child: const AccountNoticeListener(child: _SettingsView()),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView>
    with AutomaticKeepAliveClientMixin {
  // Keeps the page (and its BLoC) alive while another Dashboard tab is shown.
  @override
  bool get wantKeepAlive => true;

  Widget _sectionTitle(String title) => Padding(
    padding: REdgeInsets.fromLTRB(2, 24, 2, 10),
    child: SectionHeader(title: title),
  );

  /// "Sign In": the sheet; whichever button is tapped signs in with that provider.
  Future<void> _signIn(BuildContext context) async {
    final bloc = context.read<AccountBloc>();
    if (bloc.state.busy) return;
    HapticFeedback.selectionClick();
    final provider = await showSignInSheet(context);
    if (provider == null) return;
    HapticFeedback.mediumImpact();
    bloc.add(AccountSignInRequestedEvent(provider));
  }

  /// "Sign Out": asks first, saying that nothing is lost.
  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AccountBloc>();
    if (bloc.state.busy) return;
    final strings = appLanguage(context);
    final out = await showAppAlert<bool>(
      context,
      title: strings.account_sign_out_title,
      message: strings.account_sign_out_message,
      actions: [
        AppAlertAction(label: strings.common_cancel, value: false),
        AppAlertAction(
          label: strings.settings_sign_out,
          value: true,
          destructive: true,
        ),
      ],
    );
    if (out ?? false) bloc.add(const AccountSignOutRequestedEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final icons = Assets.icons.settings;
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final loaded = state is SettingsLoaded ? state : null;
        final settings = loaded?.settings;
        final appInfo = loaded?.appInfo;
        void toggle(SettingsNotification kind, bool value) => context
            .read<SettingsBloc>()
            .add(NotificationToggledEvent(kind, value));
        return Stack(
          children: [
            const Horizon(),
            SafeArea(
              bottom: false,
              child: ListView(
                // Bottom padding lets the last row scroll clear of the tab bar.
                padding: REdgeInsets.fromLTRB(24, 18, 24, 100),
                children: [
                  SizedBox(
                    height: 40.8.h,
                    child: Text(
                      strings.settings_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineLarge,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  BlocBuilder<AccountBloc, AccountState>(
                    buildWhen: (a, b) =>
                        a.name != b.name || a.status != b.status,
                    builder: (context, account) => ProfileCard(
                      name: account.name,
                      subtitle: switch (account.status) {
                        AccountStatus.apple => strings.settings_signed_in_apple,
                        AccountStatus.google =>
                          strings.settings_signed_in_google,
                        AccountStatus.thisDevice =>
                          strings.settings_signed_in_device,
                        AccountStatus.signedOut =>
                          strings.settings_not_signed_in,
                      },
                      onTap: () => context.push(RouteNames.profilePath),
                    ),
                  ),
                  if (settings != null) ...[
                    _sectionTitle(strings.settings_notifications),
                    ListGroup(
                      children: [
                        ListGroupSwitchRow(
                          icon: icons.bell,
                          label: strings.settings_notify_billing,
                          value: settings.notifyBilling,
                          onChanged: (v) =>
                              toggle(SettingsNotification.billing, v),
                        ),
                        ListGroupSwitchRow(
                          icon: Assets.icons.alarm,
                          label: strings.settings_notify_alarms,
                          value: settings.notifyAlarms,
                          onChanged: (v) =>
                              toggle(SettingsNotification.alarms, v),
                        ),
                        ListGroupSwitchRow(
                          icon: icons.quote,
                          label: strings.settings_notify_quotes,
                          value: settings.notifyQuotes,
                          onChanged: (v) =>
                              toggle(SettingsNotification.quotes, v),
                        ),
                      ],
                    ),
                    ListGroupNote(strings.settings_notifications_note),
                  ],
                  _sectionTitle(strings.settings_subscription),
                  ListGroup(
                    children: [
                      ListGroupRow(
                        icon: icons.crown,
                        label: strings.settings_subscription,
                        value: strings.settings_plan_free,
                        chevron: true,
                      ),
                    ],
                  ),
                  _sectionTitle(strings.settings_support),
                  ListGroup(
                    children: [
                      ListGroupRow(
                        icon: icons.help,
                        label: strings.settings_help,
                        chevron: true,
                      ),
                      ListGroupRow(
                        icon: icons.doc,
                        label: strings.settings_faq,
                        chevron: true,
                      ),
                      ListGroupRow(
                        icon: Assets.icons.bulb,
                        label: strings.settings_request_feature,
                        chevron: true,
                      ),
                      ListGroupRow(
                        icon: icons.star,
                        label: strings.settings_leave_review,
                        chevron: true,
                      ),
                    ],
                  ),
                  _sectionTitle(strings.settings_legal),
                  ListGroup(
                    children: [
                      ListGroupRow(
                        icon: icons.shield,
                        label: strings.settings_privacy,
                        chevron: true,
                      ),
                      ListGroupRow(
                        icon: icons.doc,
                        label: strings.settings_terms,
                        chevron: true,
                      ),
                    ],
                  ),
                  _sectionTitle(strings.settings_account),
                  BlocBuilder<AccountBloc, AccountState>(
                    buildWhen: (a, b) => a.signedIn != b.signedIn,
                    builder: (context, account) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListGroup(
                          children: [
                            if (account.signedIn)
                              ListGroupRow(
                                icon: icons.logout,
                                label: strings.settings_sign_out,
                                onTap: () => _confirmSignOut(context),
                              )
                            else
                              ListGroupRow(
                                icon: icons.user,
                                label: strings.settings_sign_in,
                                chevron: true,
                                onTap: () => _signIn(context),
                              ),
                            ListGroupRow(
                              icon: icons.trash,
                              label: strings.settings_delete_account,
                              danger: true,
                            ),
                          ],
                        ),
                        // What is at stake, for someone who has not signed in.
                        if (!account.signedIn)
                          ListGroupNote(strings.settings_sign_in_note),
                      ],
                    ),
                  ),
                  if (appInfo != null) ...[
                    SizedBox(height: 24.h),
                    Center(
                      child: Text(
                        strings.settings_version(
                          appInfo.name,
                          appInfo.version,
                          appInfo.build,
                        ),
                        style: textTheme.bodyLarge!.copyWith(
                          height: 1.45,
                          letterSpacing: 0,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
