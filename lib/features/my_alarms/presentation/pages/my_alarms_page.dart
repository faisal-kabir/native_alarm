import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/add_card.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../main.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../create_alarm/domain/entities/alarm_draft.dart';
import '../../../create_alarm/domain/entities/alarm_schedule.dart';
import '../../../create_alarm/presentation/pages/create_alarm_page.dart';
import '../../domain/entities/alarm_list.dart';
import '../bloc/my_alarms_bloc.dart';
import '../bloc/my_alarms_event.dart';
import '../bloc/my_alarms_state.dart';
import '../widgets/alarm_access_banner.dart';
import '../widgets/alarm_card.dart';
import '../widgets/glide.dart';
import '../widgets/slot_meter.dart';
import '../widgets/swipe_to_delete.dart';
import '../widgets/thought_ring_button.dart';

/// The "My Alarms" tab of the Dashboard, top to bottom:
/// * "My Alarms" and the thought ring;
/// * "Alarm access is off / Enable Alarm Access" while the system has not granted it;
///   the list below is then dimmed (never disabled: switching, deleting and adding
///   still work, ready for the permission that may come a minute later);
/// * no alarm: "Your alarms" + the slot meter and the big "Set your first alarm" card;
/// * "Next alarm" + the meter and the large card of the switched-on alarm that rings
///   first; "All alarms" (with the meter when there is no next alarm) and every other
///   alarm by the time of day it rings next (`arrangeAlarms`);
/// * the quiet "Add alarm" row, only while a place is free.
/// A card that changes place glides there ([Glide]); swiped left, a card is deleted
/// after "Delete this alarm?" ([SwipeToDelete]). The clock is read again every 30 s, so
/// countdowns and the order stay true by themselves.
class MyAlarmsPage extends StatelessWidget {
  const MyAlarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => instance<MyAlarmsBloc>()
        ..add(const WatchMyAlarmsEvent())
        ..add(const LoadMyAlarmsEvent())
        ..add(const WatchMyAlarmsReasonsEvent()),
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

  final _listKey = GlobalKey();
  late final Timer _tick = Timer.periodic(const Duration(seconds: 30), (_) {
    if (mounted) setState(() {});
  });

  MyAlarmsBloc get _bloc => context.read<MyAlarmsBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Alarms may have rung, and alarm access may have changed, while the app was away.
    if (state == AppLifecycleState.resumed) {
      _bloc.add(const LoadMyAlarmsEvent());
    }
  }

  @override
  void dispose() {
    _tick.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// "Add alarm": the editor (the row only shows while a place is free; the list and
  /// the meter follow the saved alarms by themselves).
  Future<void> _addAlarm() => context.push<bool>(RouteNames.createAlarmPath);

  Future<bool> _askDelete() async {
    final strings = appLanguage(context);
    final delete = await showAppAlert<bool>(
      context,
      title: strings.my_alarms_delete_title,
      message: strings.my_alarms_delete_message,
      actions: [
        AppAlertAction(label: strings.common_cancel, value: false),
        AppAlertAction(
          label: strings.common_delete,
          value: true,
          destructive: true,
        ),
      ],
    );
    return delete ?? false;
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = appLanguage(context);
    return SafeArea(
      bottom: false,
      child: MultiBlocListener(
        listeners: [
          BlocListener<MyAlarmsBloc, MyAlarmsState>(
            listenWhen: (a, b) =>
                a is MyAlarmsLoaded &&
                b is MyAlarmsLoaded &&
                a.toggleFailures != b.toggleFailures,
            listener: (_, _) => _snack(strings.my_alarms_toggle_failed),
          ),
          BlocListener<MyAlarmsBloc, MyAlarmsState>(
            listenWhen: (a, b) =>
                a is MyAlarmsLoaded &&
                b is MyAlarmsLoaded &&
                a.deleteFailures != b.deleteFailures,
            listener: (_, _) => _snack(strings.my_alarms_delete_failed),
          ),
        ],
        child: BlocBuilder<MyAlarmsBloc, MyAlarmsState>(
          builder: (context, state) {
            final loaded = state is MyAlarmsLoaded ? state : null;
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
                if (loaded != null && loaded.accessDenied) ...[
                  SizedBox(height: 14.h),
                  AlarmAccessBanner(
                    onTap: () =>
                        _bloc.add(const MyAlarmsAccessRequestedEvent()),
                  ),
                ],
                if (loaded != null) _list(loaded),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(MyAlarmsLoaded state) {
    final strings = appLanguage(context);
    final now = DateTime.now();
    final (:next, :rest) = arrangeAlarms(state.alarms, now);
    final none = state.alarms.isEmpty;
    final meter = SlotMeter(
      used: state.alarmCount,
      total: state.alarmLimit,
      onTap: () => showAlarmLimitAlert(context),
    );

    // Every alarm is one keyed child of the same column (large or a row), so a card
    // that changes place keeps its state and can glide there. A delete that failed
    // gives it a new key, which brings the swiped-away card back.
    Widget card(Alarm alarm, {required bool hero, required double top}) {
      final time = nextRingOf(alarm, now);
      return Padding(
        key: ValueKey('alarm-${alarm.id}-${state.deleteFailures}'),
        padding: EdgeInsets.only(top: top),
        child: Glide(
          scope: _listKey,
          child: SwipeToDelete(
            label: strings.my_alarms_delete_semantics(
              AlarmTime.fromMinutes(time.hour * 60 + time.minute).label,
            ),
            confirm: _askDelete,
            onDelete: () => _bloc.add(MyAlarmsAlarmDeletedEvent(alarm)),
            child: AlarmCard(
              alarm: alarm,
              reason: state.reasonOf(alarm),
              now: now,
              hero: hero,
              blocked: state.accessDenied,
              onTap: () =>
                  context.push<bool>(RouteNames.editAlarmPath, extra: alarm),
              onEnabledChanged: (enabled) =>
                  _bloc.add(MyAlarmsAlarmToggledEvent(alarm, enabled: enabled)),
            ),
          ),
        ),
      );
    }

    Widget title(String text, {Widget? trailing}) => Padding(
      key: ValueKey('title-$text'),
      padding: REdgeInsets.only(top: 24, bottom: 10),
      child: SectionHeader(title: text, trailing: trailing),
    );

    return _Dimmed(
      dim: state.accessDenied && !none,
      child: Column(
        key: _listKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (none) title(strings.my_alarms_your_alarms, trailing: meter),
          if (next != null) ...[
            title(strings.my_alarms_next_alarm, trailing: meter),
            card(next, hero: true, top: 0),
          ],
          if (rest.isNotEmpty)
            title(
              strings.my_alarms_all_alarms,
              trailing: next == null ? meter : null,
            ),
          for (var i = 0; i < rest.length; i++)
            card(rest[i], hero: false, top: i == 0 ? 0 : 10.h),
          if (state.alarmCount < state.alarmLimit)
            Padding(
              key: const ValueKey('add'),
              padding: EdgeInsets.only(
                top: rest.isNotEmpty ? 10.h : (none ? 0 : 18.h),
              ),
              child: AddCard(
                first: none,
                title: strings.my_alarms_add_first_alarm_title,
                subtitle: strings.my_alarms_add_first_alarm_subtitle,
                label: strings.my_alarms_add_alarm,
                onTap: _addAlarm,
              ),
            ),
        ],
      ),
    );
  }
}

/// The list while nothing on it can ring: 42 % opacity and 35 % colour, eased in over
/// 500 ms (still, once there).
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.dim, required this.child});

  final bool dim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: dim ? 1 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, v, child) {
        if (v <= 0) return child!;
        final s = 1 - 0.65 * v;
        const lr = 0.2126, lg = 0.7152, lb = 0.0722;
        return Opacity(
          opacity: 1 - 0.58 * v,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              lr + (1 - lr) * s, lg - lg * s, lb - lb * s, 0, 0, //
              lr - lr * s, lg + (1 - lg) * s, lb - lb * s, 0, 0, //
              lr - lr * s, lg - lg * s, lb + (1 - lb) * s, 0, 0, //
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
        );
      },
    );
  }
}
