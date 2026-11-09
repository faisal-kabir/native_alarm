import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/hinted_scroll_view.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../../create_reason/presentation/pages/create_reason_page.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../bloc/create_alarm_bloc.dart';
import '../bloc/create_alarm_event.dart';
import '../bloc/create_alarm_state.dart';
import '../widgets/alarm_pickers.dart';
import '../widgets/alarm_reason_row.dart';
import '../widgets/ring_again_control.dart';
import '../widgets/schedule_cards.dart';

/// "Every alarm place is taken" ([AppConstant.maxAlarmCount]).
Future<void> showAlarmLimitAlert(BuildContext context) {
  final strings = appLanguage(context);
  return showAppAlert<void>(
    context,
    title: strings.create_alarm_limit_title,
    message: strings.create_alarm_limit_note(AppConstant.maxAlarmCount),
    actions: [AppAlertAction(label: strings.common_ok, value: null)],
  );
}

/// "Add Alarm": when it rings (schedule cards), what it plays (a Reason, a soundtrack,
/// an alarm sound), ring again, enabled. Everything it offers comes from the device
/// (cached reasons, alarm sounds and sound tracks), so it works offline. The Reason is
/// the one choice with no default: until there is one, the button chooses it.
///
/// Opened from My Alarms (which checks there is a free place first); [reasonId] is a
/// Reason it arrives with. It pops with `true` once the alarm is saved.
class CreateAlarmPage extends StatelessWidget {
  const CreateAlarmPage({super.key, this.reasonId});

  final int? reasonId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<CreateAlarmBloc>(param1: reasonId)
            ..add(const CreateAlarmStartedEvent()),
      child: const _CreateAlarmView(),
    );
  }
}

class _CreateAlarmView extends StatelessWidget {
  const _CreateAlarmView();

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocListener<CreateAlarmBloc, CreateAlarmState>(
      listener: (context, state) {
        switch (state.status) {
          case CreateAlarmStatus.saved:
            context.pop(true);
          case CreateAlarmStatus.full:
            // Every way in checks first; this catches one that did not.
            context.pop();
            showAlarmLimitAlert(appContext);
          case CreateAlarmStatus.editing || CreateAlarmStatus.saving:
            break;
        }
      },
      listenWhen: (a, b) => a.status != b.status,
      child: BlocListener<CreateAlarmBloc, CreateAlarmState>(
        listenWhen: (a, b) => a.saveFailures != b.saveFailures,
        listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.create_alarm_save_failed)),
        ),
        child: Scaffold(
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: _NavBar(
                  title: strings.create_alarm_title,
                  cancel: strings.common_cancel,
                  onCancel: () => context.pop(),
                ),
              ),
              Expanded(
                child: HintedScrollView(
                  padding: REdgeInsets.fromLTRB(24, 10, 24, 26),
                  child: const _Body(),
                ),
              ),
              const _SaveBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's actions on the Reason, shared by its row and the Save bar.
extension on BuildContext {
  CreateAlarmBloc get _bloc => read<CreateAlarmBloc>();

  /// One door for "pick one": the list when there is a Reason to pick, the maker
  /// when there is not.
  Future<void> chooseReason() =>
      _bloc.state.hasPickableReason ? _openReasonPicker() : _makeReason();

  Future<void> _openReasonPicker() async {
    HapticFeedback.selectionClick();
    final state = _bloc.state;
    final pick = await showReasonPicker(
      this,
      pickable: state.pickableReasons,
      anyReasons: state.reasons.isNotEmpty,
      selectedId: state.draft.reasonId,
    );
    if (!mounted) return;
    switch (pick) {
      case ReasonPicked(:final id):
        _bloc.add(CreateAlarmReasonChosenEvent(id));
      case ReasonMakeRequested():
        await _makeReason();
      case null:
        break;
    }
  }

  /// The Reason maker runs on top of this page and comes back with what it made (or
  /// nothing, if it was left); the rest of the alarm is exactly as it was.
  Future<void> _makeReason() async {
    final made = await push<Reason>(
      RouteNames.createReasonPath,
      extra: CreateReasonPage.returnReasonExtra,
    );
    if (mounted && made != null) {
      _bloc.add(CreateAlarmReasonChosenEvent(made.id));
    }
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateAlarmBloc>();
    return BlocBuilder<CreateAlarmBloc, CreateAlarmState>(
      builder: (context, state) {
        final draft = state.draft;
        final again = draft.again.clamp(0, 2);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RiseIn(
              delay: const Duration(milliseconds: 40),
              child: ScheduleCards(
                cards: state.cards,
                onTime: (id, time) =>
                    bloc.add(CreateAlarmTimeChangedEvent(id, time)),
                onDay: (id, day) =>
                    bloc.add(CreateAlarmDayToggledEvent(id, day)),
                onAdd: () => bloc.add(const CreateAlarmCardAddedEvent()),
              ),
            ),
            RiseIn(
              delay: const Duration(milliseconds: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: REdgeInsets.only(left: 2),
                    child: SectionHeader(title: strings.create_alarm_section),
                  ),
                  SizedBox(height: 10.h),
                  ListGroup(
                    children: [
                      AlarmReasonRow(
                        reason: state.reason,
                        title: state.hasPickableReason
                            ? strings.create_alarm_choose_reason
                            : strings.create_alarm_add_reason,
                        hint: strings.create_alarm_reason_hint,
                        action: state.reason != null
                            ? strings.create_alarm_change
                            : state.hasPickableReason
                            ? strings.create_alarm_choose
                            : strings.common_add,
                        onTap: context.chooseReason,
                      ),
                      ListGroupRow(
                        icon: Assets.icons.editor.ambient,
                        label: strings.create_alarm_soundtrack,
                        value: state.soundTrack?.title ?? '',
                        chevron: true,
                        onTap: () => _pickSound(context, soundtrack: true),
                      ),
                      ListGroupRow(
                        icon: Assets.icons.settings.bell,
                        label: strings.create_alarm_alarm_sound,
                        value: state.alarmSound?.title ?? '',
                        chevron: true,
                        onTap: () => _pickSound(context, soundtrack: false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            RiseIn(
              delay: const Duration(milliseconds: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 22.h),
                  ListGroup(
                    children: [
                      Padding(
                        padding: REdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                AppSvgIcon(
                                  Assets.icons.editor.bellRing,
                                  size: 22.r,
                                  color: AppColor.textSecondary,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    strings.create_alarm_ring_again,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: appTheme(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            SegmentedControl(
                              value: again,
                              label: strings.create_alarm_ring_again,
                              options: [
                                strings.create_alarm_again_off,
                                strings.create_alarm_again_once,
                                strings.create_alarm_again_twice,
                              ],
                              onChanged: (v) =>
                                  bloc.add(CreateAlarmRingAgainChangedEvent(v)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: REdgeInsets.symmetric(horizontal: 4),
                    child: RingAgainCaption(
                      value: again,
                      sentence: [
                        strings.create_alarm_again_note_0,
                        strings.create_alarm_again_note_1,
                        strings.create_alarm_again_note_2,
                      ][again]('\u0000'),
                      count: [
                        strings.create_alarm_again_count_0,
                        strings.create_alarm_again_count_1,
                        strings.create_alarm_again_count_2,
                      ][again],
                    ),
                  ),
                  SizedBox(height: 22.h),
                  ListGroup(
                    children: [
                      // Reads off while access is missing, without touching the
                      // draft, so the intent comes back with access.
                      ListGroupSwitchRow(
                        icon: Assets.icons.alarm,
                        label: strings.create_alarm_enabled,
                        value: draft.enabled && !state.accessDenied,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          bloc.add(
                            state.accessDenied
                                ? const CreateAlarmAccessRequestedEvent()
                                : CreateAlarmEnabledChangedEvent(v),
                          );
                        },
                      ),
                    ],
                  ),
                  if (state.accessDenied) ...[
                    SizedBox(height: 8.h),
                    ListGroup(
                      children: [
                        ListGroupRow(
                          icon: Assets.icons.editor.alarmOff,
                          label: strings.create_alarm_blocked_title,
                          value: strings.create_alarm_blocked_action,
                          danger: true,
                          chevron: true,
                          onTap: () =>
                              bloc.add(const CreateAlarmAccessRequestedEvent()),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickSound(
    BuildContext context, {
    required bool soundtrack,
  }) async {
    HapticFeedback.selectionClick();
    final strings = appLanguage(context);
    final bloc = context.read<CreateAlarmBloc>();
    final state = bloc.state;
    final options = soundtrack ? state.soundTracks : state.alarmSounds;
    if (options.isEmpty) {
      // Nothing on the device yet (first launch offline): it comes with the next
      // open that has a connection.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.common_list_error)));
      return;
    }
    final id = await showSoundSheet(
      context,
      title: soundtrack
          ? strings.create_alarm_soundtrack
          : strings.create_alarm_alarm_sound,
      subtitle: soundtrack
          ? strings.soundtrack_sheet_subtitle
          : strings.alarm_sound_sheet_subtitle,
      selectLabel: soundtrack
          ? strings.soundtrack_sheet_select
          : strings.alarm_sound_sheet_select,
      options: options,
      selectedId: soundtrack
          ? state.draft.soundTrackId
          : state.draft.alarmSoundId,
      playAlsoChooses: soundtrack,
    );
    if (id == null) return;
    bloc.add(
      soundtrack
          ? CreateAlarmSoundTrackChosenEvent(id)
          : CreateAlarmAlarmSoundChosenEvent(id),
    );
  }
}

/// "Cancel" on the left, the title in the middle (50 tall).
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.title,
    required this.cancel,
    required this.onCancel,
  });

  final String title;
  final String cancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = appTheme(context).textTheme;
    return SizedBox(
      height: 50.h,
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: cancel,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCancel,
                  child: SizedBox(
                    height: 44.h,
                    child: Padding(
                      padding: REdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          cancel,
                          style: textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(title, maxLines: 1, style: textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// ONE orange button. Never a dead button: until there is a Reason it chooses one
/// (and says so), then it saves.
class _SaveBar extends StatelessWidget {
  const _SaveBar();

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocBuilder<CreateAlarmBloc, CreateAlarmState>(
      buildWhen: (a, b) =>
          a.reason != b.reason ||
          a.status != b.status ||
          a.hasPickableReason != b.hasPickableReason,
      builder: (context, state) {
        final needsReason = state.reason == null;
        final saving = state.status == CreateAlarmStatus.saving;
        return ColoredBox(
          color: AppColor.backgroundColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.w,
              14.h,
              24.w,
              MediaQuery.paddingOf(context).bottom + 6.h,
            ),
            child: PillButton(
              enabled: !saving,
              label: needsReason
                  ? (state.hasPickableReason
                        ? strings.create_alarm_choose_reason
                        : strings.create_alarm_add_reason)
                  : saving
                  ? strings.common_saving
                  : strings.create_alarm_save,
              onPressed: needsReason
                  ? context.chooseReason
                  : () {
                      HapticFeedback.lightImpact();
                      context.read<CreateAlarmBloc>().add(
                        const CreateAlarmSavedEvent(),
                      );
                    },
            ),
          ),
        );
      },
    );
  }
}
