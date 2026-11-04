import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/horizon.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_switch_row.dart';

/// The "Settings" tab of the Dashboard.
///
/// There is no account system yet, so the page always shows the signed-out look: an
/// unnamed profile, the "Sign In" row and the free plan. The Premium badge, credits
/// and "Sign Out" rows from the design are added with the account feature.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<SettingsBloc>()..add(const LoadSettingsEvent()),
      child: const _SettingsView(),
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

  Widget _caption(BuildContext context, String text) => Padding(
    padding: REdgeInsets.fromLTRB(4, 8, 4, 0),
    child: Text(
      text,
      style: appTheme(context).textTheme.bodyLarge!
          .copyWith(height: 1.45, letterSpacing: 0),
    ),
  );

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
                  ProfileCard(
                    name: '',
                    subtitle: strings.settings_not_signed_in,
                  ),
                  if (settings != null) ...[
                    _sectionTitle(strings.settings_notifications),
                    SettingsGroup(
                      children: [
                        SettingsSwitchRow(
                          icon: icons.bell,
                          label: strings.settings_notify_billing,
                          value: settings.notifyBilling,
                          onChanged: (v) =>
                              toggle(SettingsNotification.billing, v),
                        ),
                        SettingsSwitchRow(
                          icon: Assets.icons.alarm,
                          label: strings.settings_notify_alarms,
                          value: settings.notifyAlarms,
                          onChanged: (v) =>
                              toggle(SettingsNotification.alarms, v),
                        ),
                        SettingsSwitchRow(
                          icon: icons.quote,
                          label: strings.settings_notify_quotes,
                          value: settings.notifyQuotes,
                          onChanged: (v) =>
                              toggle(SettingsNotification.quotes, v),
                        ),
                      ],
                    ),
                    _caption(context, strings.settings_notifications_note),
                  ],
                  _sectionTitle(strings.settings_subscription),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: icons.crown,
                        label: strings.settings_subscription,
                        value: strings.settings_plan_free,
                        chevron: true,
                      ),
                    ],
                  ),
                  _sectionTitle(strings.settings_support),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: icons.help,
                        label: strings.settings_help,
                        chevron: true,
                      ),
                      SettingsRow(
                        icon: icons.doc,
                        label: strings.settings_faq,
                        chevron: true,
                      ),
                      SettingsRow(
                        icon: icons.bulb,
                        label: strings.settings_request_feature,
                        chevron: true,
                      ),
                      SettingsRow(
                        icon: icons.star,
                        label: strings.settings_leave_review,
                        chevron: true,
                      ),
                    ],
                  ),
                  _sectionTitle(strings.settings_legal),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: icons.shield,
                        label: strings.settings_privacy,
                        chevron: true,
                      ),
                      SettingsRow(
                        icon: icons.doc,
                        label: strings.settings_terms,
                        chevron: true,
                      ),
                    ],
                  ),
                  _sectionTitle(strings.settings_account),
                  SettingsGroup(
                    children: [
                      SettingsRow(
                        icon: icons.user,
                        label: strings.settings_sign_in,
                        chevron: true,
                      ),
                      SettingsRow(
                        icon: icons.trash,
                        label: strings.settings_delete_account,
                        danger: true,
                      ),
                    ],
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
