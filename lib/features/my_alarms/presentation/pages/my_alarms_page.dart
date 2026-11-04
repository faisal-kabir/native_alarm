import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/add_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../main.dart';
import '../bloc/my_alarms_bloc.dart';
import '../bloc/my_alarms_event.dart';
import '../bloc/my_alarms_state.dart';
import '../widgets/slot_meter.dart';
import '../widgets/thought_ring_button.dart';

/// The "My Alarms" tab of the Dashboard.
class MyAlarmsPage extends StatelessWidget {
  const MyAlarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<MyAlarmsBloc>()..add(const LoadMyAlarmsEvent()),
      child: const _MyAlarmsView(),
    );
  }
}

class _MyAlarmsView extends StatefulWidget {
  const _MyAlarmsView();

  @override
  State<_MyAlarmsView> createState() => _MyAlarmsViewState();
}

class _MyAlarmsViewState extends State<_MyAlarmsView>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // Keeps the page (and its BLoC) alive while another Dashboard tab is shown.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Alarms may have rung or been removed while the app was away.
    if (state == AppLifecycleState.resumed) {
      context.read<MyAlarmsBloc>().add(const LoadMyAlarmsEvent());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = appLanguage(context);
    return SafeArea(
      bottom: false,
      child: BlocBuilder<MyAlarmsBloc, MyAlarmsState>(
        builder: (context, state) {
          final loaded = state is MyAlarmsLoaded ? state : null;
          final alarmCount = loaded?.alarmCount ?? 0;
          final alarmLimit = loaded?.alarmLimit ?? AppConstant.maxAlarmCount;
          return ListView(
            // Bottom padding lets the last row scroll clear of the tab bar.
            padding: REdgeInsets.fromLTRB(24, 14, 24, 100),
            children: [
              SizedBox(
                height: 42.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        strings.my_alarms_title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appTheme(context).textTheme.headlineLarge,
                      ),
                    ),
                    const ThoughtRingButton(),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SectionHeader(
                title: strings.my_alarms_your_alarms,
                trailing: SlotMeter(used: alarmCount, total: alarmLimit),
              ),
              SizedBox(height: 10.h),
              if (loaded != null)
                AddCard(
                  first: alarmCount == 0,
                  title: strings.my_alarms_add_first_alarm_title,
                  subtitle: strings.my_alarms_add_first_alarm_subtitle,
                  label: strings.my_alarms_add_alarm,
                ),
            ],
          );
        },
      ),
    );
  }
}
