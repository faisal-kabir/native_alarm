import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../../alarm/presentation/widgets/alarm_event_listener.dart';
import '../../../my_alarms/presentation/pages/my_alarms_page.dart';
import '../../../reasons/presentation/pages/reasons_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

/// The mother screen: a [PageView] holding My Alarms, Reasons and Settings, with the
/// floating tab bar below. Tapping a tab slides to its page; swiping the pages moves
/// the tab.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // The first tab is on screen from the start, so it is logged right away.
      create: (BuildContext context) => instance<DashboardBloc>()
        ..add(const DashboardTabChangedEvent(0))
        ..add(const EnsureSessionEvent())
        ..add(const RescheduleAlarmsEvent()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  // One page per tab, in tab order.
  static const List<Widget> _pages = [
    MyAlarmsPage(),
    ReasonsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Back in front = opened again: the session, the user's row, the alarm sounds and
  // the repeating alarms are brought up to date (each skips work that is not needed).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DashboardBloc>()
        ..add(const EnsureSessionEvent())
        ..add(const RescheduleAlarmsEvent());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    // Wraps the home screen so alarm unlocks open the message page from any tab.
    return AlarmEventListener(
      // GlassScaffold gives the tab bar's liquid glass a layer to refract the pages on.
      child: GlassScaffold(
        backgroundColor: AppColor.backgroundColor,
        bottomBar: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) => AppTabBar(
            selectedIndex: state.selectedIndex,
            onSelected: _onTabTapped,
            items: [
              AppTabItem(
                label: strings.tab_alarms,
                icon: Assets.icons.alarm,
                activeIcon: Assets.icons.tab.alarmOn,
              ),
              AppTabItem(
                label: strings.tab_reasons,
                icon: Assets.icons.tab.reasons,
                activeIcon: Assets.icons.tab.reasonsOn,
              ),
              AppTabItem(
                label: strings.tab_settings,
                icon: Assets.icons.tab.settings,
                activeIcon: Assets.icons.tab.settingsOn,
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => context.read<DashboardBloc>().add(
            DashboardTabChangedEvent(index),
          ),
          children: _pages,
        ),
      ),
    );
  }
}
