import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/utils/load_status.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/back_chevron.dart';
import '../../../../core/widgets/cached_svg_icon.dart';
import '../../../../core/widgets/choice_sheet.dart';
import '../../../../core/widgets/hinted_scroll_view.dart';
import '../../../../core/widgets/list_group.dart';
import '../../../../core/widgets/text_sheet.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../main.dart';
import '../../../create_reason/presentation/widgets/reason_choice_items.dart';
import '../../../create_reason/presentation/widgets/reason_name_field.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../create_alarm/domain/entities/alarm_draft.dart';
import '../../../create_alarm/domain/entities/alarm_schedule.dart';
import '../../../create_alarm/presentation/widgets/schedule_cards.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../voice/domain/entities/voice.dart';
import '../../../reasons/presentation/widgets/reason_emblem.dart';
import '../bloc/reason_detail_bloc.dart';
import '../bloc/reason_detail_event.dart';
import '../bloc/reason_detail_state.dart';
import '../widgets/reason_actions_sheet.dart';
import '../widgets/save_bar.dart';
import '../widgets/voice_sheet.dart';

/// A reason's own screen: its name (renamed in place), what it is about, how it
/// speaks, and its alarm. Opened from the reasons list with the cached [reason], so it
/// shows at once and offline.
///
/// Every row opens its sheet (area, tone, length: choice sheets; purpose, why: text
/// sheets; voice: the voice sheet) already showing the current choice. A sheet changes
/// nothing by itself: the choice is HELD here, its row reads orange, and the Save bar
/// slides up. Choosing the saved value again is no change. "Save Changes" saves all of
/// it (server, then the device copy, which the list follows); "Discard" and back ask
/// first ("Discard changes?").
class ReasonDetailPage extends StatelessWidget {
  const ReasonDetailPage({super.key, required this.reason});

  final Reason reason;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<ReasonDetailBloc>(param1: reason)
            ..add(const ReasonDetailStartedEvent()),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  late final ReasonDetailBloc _bloc = context.read<ReasonDetailBloc>();

  ReasonDetailState get _state => _bloc.state;

  // ------------------------------------------------------------------ sheets

  Future<void> _pickTone() async {
    HapticFeedback.selectionClick();
    final strings = appLanguage(context);
    if (_state.soundTypes.isEmpty) {
      // Not here yet: ask again unless a request is already on its way.
      if (_state.soundTypesStatus != LoadStatus.loading) {
        _bloc.add(const ReasonDetailSoundTypesRequestedEvent());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.common_list_error)));
      return;
    }
    final id = await showChoiceSheet(
      context,
      title: strings.reason_detail_tone_sheet,
      items: [for (final sound in _state.soundTypes) soundChoice(sound)],
      selectedId: _state.draft.soundTypeId,
      keepLabel: strings.reason_detail_keep_tone,
      useLabel: (item) => strings.sheet_use_choice(item.title),
    );
    if (id is int && mounted) {
      _bloc.add(
        ReasonDetailDraftChangedEvent(_state.draft.copyWith(soundTypeId: id)),
      );
    }
  }

  Future<void> _pickLength() async {
    HapticFeedback.selectionClick();
    final strings = appLanguage(context);
    final id = await showChoiceSheet(
      context,
      title: strings.reason_detail_length_sheet,
      items: [
        for (final s in AppConstant.reasonLengthsSeconds)
          lengthChoice(strings, s),
      ],
      selectedId: _state.draft.lengthSeconds,
      keepLabel: strings.reason_detail_keep_length,
      useLabel: (item) => strings.sheet_use_choice(item.title),
    );
    if (id is int && mounted) {
      _bloc.add(
        ReasonDetailDraftChangedEvent(_state.draft.copyWith(lengthSeconds: id)),
      );
    }
  }

  Future<void> _pickVoice() async {
    HapticFeedback.selectionClick();
    final id = await showVoiceSheet(
      context,
      voices: _state.voices,
      selectedId: _state.draft.voiceId,
    );
    if (id != null && mounted) {
      _bloc.add(
        ReasonDetailDraftChangedEvent(_state.draft.copyWith(voiceId: id)),
      );
    }
  }

  Future<void> _pickText({required bool why}) async {
    HapticFeedback.selectionClick();
    final strings = appLanguage(context);
    final draft = _state.draft;
    final text = await showTextSheet(
      context,
      title: why
          ? strings.reason_detail_why_sheet
          : strings.reason_detail_purpose_sheet,
      initialText: why ? draft.why : draft.purpose,
      hintText: why
          ? strings.create_reason_matter_hint
          : strings.create_reason_purpose_hint,
      maxLength: AppConstant.purposeMaxLength,
      minLength: why
          ? AppConstant.matterMinLength
          : AppConstant.purposeMinLength,
      minWords: why ? 1 : AppConstant.purposeMinWords,
      allowEmpty: why,
      shortNote: why
          ? strings.reason_detail_why_short
          : strings.reason_detail_purpose_short,
    );
    if (text != null && mounted) {
      final draft = _state.draft;
      _bloc.add(
        ReasonDetailDraftChangedEvent(
          why ? draft.copyWith(why: text) : draft.copyWith(purpose: text),
        ),
      );
    }
  }

  // --------------------------------------------------------- save / discard

  /// "Discard changes?"; true when the user chose to discard.
  Future<bool> _confirmDiscard() async {
    final strings = appLanguage(context);
    final discard = await showAppAlert<bool>(
      context,
      title: strings.reason_detail_discard_title,
      message: strings.reason_detail_discard_message,
      actions: [
        AppAlertAction(label: strings.reason_detail_keep_editing, value: false),
        AppAlertAction(
          label: strings.reason_detail_discard,
          value: true,
          destructive: true,
        ),
      ],
    );
    return discard ?? false;
  }

  Future<void> _discard() async {
    if (!await _confirmDiscard() || !mounted) return;
    HapticFeedback.selectionClick();
    _bloc.add(const ReasonDetailDiscardedEvent());
  }

  /// "…": the actions sheet. "Use with an alarm" opens the alarm editor; Delete asks
  /// once ("Delete “name”?", saying its alarm goes too when it has one), then deletes.
  Future<void> _more() async {
    HapticFeedback.selectionClick();
    final strings = appLanguage(context);
    final name = _state.reason.name;
    final action = await showReasonActions(
      context,
      name: name,
      canUseWithAlarm: !_state.hasAlarm,
    );
    if (action == null || !mounted) return;
    if (action == ReasonAction.useWithAlarm) return _useWithAlarm();
    // The sheet is gone first; the question comes a moment later.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final delete = await showAppAlert<bool>(
      context,
      title: strings.reason_delete_title(name),
      message: _state.hasAlarm
          ? strings.reason_delete_alarm_message
          : strings.reason_delete_message,
      actions: [
        AppAlertAction(label: strings.common_cancel, value: false),
        AppAlertAction(
          label: strings.common_delete,
          value: true,
          destructive: true,
        ),
      ],
    );
    if ((delete ?? false) && mounted) {
      _bloc.add(const ReasonDetailDeleteRequestedEvent());
    }
  }

  /// "Connect an alarm" / "Use with an alarm": the alarm editor with this reason
  /// already chosen. Back here, the page shows the alarm it made (it follows the
  /// saved alarms).
  Future<void> _useWithAlarm() async {
    HapticFeedback.selectionClick();
    await context.push<bool>(
      RouteNames.createAlarmPath,
      extra: _state.reason.id,
    );
  }

  Future<void> _back() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_state.dirty && !await _confirmDiscard()) return;
    if (mounted) context.pop();
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<ReasonDetailBloc, ReasonDetailState>(
          listenWhen: (a, b) => a.saveFailures != b.saveFailures,
          listener: (context, _) => _snack(strings.reason_detail_save_failed),
        ),
        BlocListener<ReasonDetailBloc, ReasonDetailState>(
          listenWhen: (a, b) => a.renameFailures != b.renameFailures,
          listener: (context, _) => _snack(strings.reason_rename_failed),
        ),
        BlocListener<ReasonDetailBloc, ReasonDetailState>(
          listenWhen: (a, b) => a.deleteFailures != b.deleteFailures,
          listener: (context, _) => _snack(strings.reason_delete_failed),
        ),
        // Deleted: back to the list (which has already dropped it).
        BlocListener<ReasonDetailBloc, ReasonDetailState>(
          listenWhen: (a, b) => !a.deleted && b.deleted,
          listener: (context, _) => context.pop(),
        ),
      ],
      child: BlocBuilder<ReasonDetailBloc, ReasonDetailState>(
        builder: (context, state) => PopScope(
          canPop: !state.dirty || state.deleted,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: _NavBar(onBack: _back, onMore: _more),
                ),
                Expanded(
                  child: HintedScrollView(
                    padding: REdgeInsets.fromLTRB(24, 10, 24, 26),
                    child: _Body(
                      state: state,
                      onRename: (name) =>
                          _bloc.add(ReasonDetailRenamedEvent(name)),
                      onConnectAlarm: _useWithAlarm,
                      onPurpose: () => _pickText(why: false),
                      onWhy: () => _pickText(why: true),
                      onTone: _pickTone,
                      onVoice: _pickVoice,
                      onLength: _pickLength,
                    ),
                  ),
                ),
                SaveBar(
                  visible: state.dirty,
                  saving: state.saving,
                  onSave: () {
                    HapticFeedback.lightImpact();
                    _bloc.add(const ReasonDetailSavedEvent());
                  },
                  onDiscard: _discard,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// "‹ Goals": back to the list (asks first when something is held).
class _NavBar extends StatelessWidget {
  const _NavBar({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return SizedBox(
      height: 50.h,
      child: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: strings.common_back,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: SizedBox(
                  height: 44.h,
                  child: Padding(
                    padding: REdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BackChevron(size: 21.r, color: AppColor.primary),
                        SizedBox(width: 3.w),
                        Text(
                          strings.reason_detail_back,
                          style: appTheme(context).textTheme.bodyLarge!
                              .copyWith(
                                fontSize: 17.spMin,
                                letterSpacing: 0,
                                color: AppColor.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: strings.reason_detail_more,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMore,
                child: SizedBox(
                  height: 44.h,
                  child: Padding(
                    padding: REdgeInsets.symmetric(horizontal: 8),
                    child: CustomPaint(
                      size: Size(22.r, 44.h),
                      painter: const _MoreDots(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "…": three round orange dots, 2.4 across and 6 apart on a 24 grid.
class _MoreDots extends CustomPainter {
  const _MoreDots();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()..color = AppColor.primary;
    for (final x in const [6.0, 12.0, 18.0]) {
      canvas.drawCircle(Offset(x * k, size.height / 2), 1.2 * k, paint);
    }
  }

  @override
  bool shouldRepaint(_MoreDots old) => false;
}

/// The header and the three sections.
class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onRename,
    required this.onConnectAlarm,
    required this.onPurpose,
    required this.onWhy,
    required this.onTone,
    required this.onVoice,
    required this.onLength,
  });

  final ReasonDetailState state;
  final ValueChanged<String> onRename;
  final VoidCallback onConnectAlarm;
  final VoidCallback onPurpose;
  final VoidCallback onWhy;
  final VoidCallback onTone;
  final VoidCallback onVoice;
  final VoidCallback onLength;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final saved = state.reason;
    final draft = state.draft;
    final length = draft.lengthSeconds;
    final icons = Assets.icons.detail;
    final alarm = state.alarm;

    Widget row({
      SvgGenImage? icon,
      Widget? leading,
      required String label,
      required String value,
      required bool changed,
      required VoidCallback onTap,
      bool sentence = false,
    }) {
      final shown = value.isEmpty ? strings.common_add : value;
      return ListGroupRow(
        icon: icon,
        leading: leading,
        label: label,
        value: shown,
        // A changed row says so in its value, and so does an empty one ("Add").
        highlight: changed || value.isEmpty,
        chevron: true,
        sentence: sentence,
        semanticsLabel: strings.reason_detail_row_semantics(
          label,
          shown,
          changed ? strings.reason_detail_changed_note : '',
        ),
        onTap: onTap,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          reason: saved,
          voice: state.voice,
          renameFailures: state.renameFailures,
          onRename: onRename,
        ),
        SizedBox(height: 24.h),
        // A goal that has its alarm (one alarm, one goal) shows it below instead.
        if (!state.hasAlarm) _ConnectAlarm(onTap: onConnectAlarm),
        _Section(strings.reason_detail_about),
        ListGroup(
          children: [
            row(
              icon: icons.flag,
              label: strings.reason_detail_purpose,
              value: draft.purpose,
              changed: draft.purpose != saved.purpose,
              onTap: onPurpose,
              sentence: true,
            ),
            row(
              icon: Assets.icons.bulb,
              label: strings.reason_detail_why,
              value: draft.why,
              changed: draft.why != saved.why,
              onTap: onWhy,
              sentence: true,
            ),
          ],
        ),
        _Section(strings.reason_detail_speaks),
        ListGroup(
          children: [
            row(
              leading: _ToneIcon(path: state.sound?.icon),
              label: strings.reason_detail_tone,
              value: state.sound?.title ?? '',
              changed: draft.soundTypeId != saved.soundTypeId,
              onTap: onTone,
            ),
            row(
              icon: icons.volume,
              label: strings.reason_detail_voice,
              value: state.voice?.name ?? '',
              changed: draft.voiceId != saved.voiceId,
              onTap: onVoice,
            ),
            row(
              icon: icons.clock,
              label: strings.reason_detail_length,
              value: strings.reason_detail_length_value(
                reasonLengthName(strings, length),
                length,
              ),
              changed: length != saved.lengthSeconds,
              onTap: onLength,
            ),
          ],
        ),
        if (alarm != null) ...[
          _Section(strings.reason_detail_alarm),
          _AlarmRows(alarm: alarm),
        ] else if (!state.hasAlarm) ...[
          _Section(strings.reason_detail_alarm),
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 4),
            child: Text(
              strings.reason_detail_no_alarm,
              style: appTheme(context).textTheme.bodyLarge!.copyWith(
                fontSize: 16.spMin,
                height: 1.5,
                letterSpacing: 0,
                color: AppColor.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The alarm that plays the goal, as a way through to it: one row with the time it rings
/// next and the days ("6:34 AM · Every day"), the clock orange; switched off, the clock
/// is grey and the value reads "Off". It reports, it does not switch: the switch is on
/// the alarm. A row opens the alarm in the editor.
class _AlarmRows extends StatelessWidget {
  const _AlarmRows({required this.alarm});

  final Alarm alarm;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final draft = alarmDraftOf(alarm);
    final next = nextRingOf(alarm, DateTime.now());
    final time = AlarmTime.fromMinutes(next.hour * 60 + next.minute);
    // Every day any of its times rings on.
    final days = draft.byDay?.keys ?? draft.days;
    return ListGroup(
      children: [
        ListGroupRow(
          icon: Assets.icons.alarm,
          iconColor: alarm.enabled ? AppColor.primary : AppColor.textMuted,
          label: time.label,
          value: alarm.enabled
              ? repeatLabel(days, repeatWordsOf(strings))
              : strings.my_alarms_off,
          chevron: true,
          onTap: () {
            HapticFeedback.selectionClick();
            context.push<bool>(RouteNames.editAlarmPath, extra: alarm);
          },
        ),
      ],
    );
  }
}

/// The voice's face beside the name, which is the page title and renamed in place. The
/// face follows the voice held on the Voice row (the one you tapped on My Goals is the
/// one you land on).
class _Header extends StatelessWidget {
  const _Header({
    required this.reason,
    required this.voice,
    required this.renameFailures,
    required this.onRename,
  });

  final Reason reason;
  final Voice? voice;

  /// A failed rename rebuilds the field, which puts the saved name back.
  final int renameFailures;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReasonEmblem(voice: voice, name: reason.name, size: 52),
        SizedBox(width: 14.w),
        Expanded(
          child: ReasonNameField(
            key: ValueKey(renameFailures),
            value: reason.name,
            large: true,
            onCommit: onRename,
          ),
        ),
      ],
    );
  }
}

/// "Connect an alarm": the one action on a goal that has no alarm yet, a warm card (the
/// brand colour at 7 % with a 28 % rim) with an alarm mark, the words and a chevron.
class _ConnectAlarm extends StatelessWidget {
  const _ConnectAlarm({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return Padding(
      padding: REdgeInsets.only(bottom: 4),
      child: Material(
        color: Color.alphaBlend(
          AppColor.primary.withValues(alpha: 0.07),
          AppColor.cardColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
          side: BorderSide(color: AppColor.primary.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: strings.reason_detail_connect_alarm,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: REdgeInsets.symmetric(horizontal: 15, vertical: 11),
              child: SizedBox(
                height: 26.h,
                child: Row(
                  children: [
                    AppSvgIcon(
                      Assets.icons.alarm,
                      size: 18.r,
                      color: AppColor.primary,
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Text(
                        strings.reason_detail_connect_alarm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appTheme(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 16.spMin,
                          fontWeight: Dimension.textMedium,
                          letterSpacing: -0.1,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    AppSvgIcon(
                      Assets.icons.page.chevron,
                      size: 16.r,
                      color: AppColor.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tone's own icon (its server path), grey like the other rows' icons; a heart until
/// it loads or when the server has none.
class _ToneIcon extends StatelessWidget {
  const _ToneIcon({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final size = 22.r;
    final heart = AppSvgIcon(
      Assets.icons.detail.heart,
      size: size,
      color: AppColor.textSecondary,
    );
    final path = this.path;
    if (path == null || path.isEmpty) return heart;
    return CachedSvgIcon(
      path: path,
      size: size,
      color: AppColor.textSecondary,
      fallback: heart,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.fromLTRB(2, 24, 2, 10),
      child: Semantics(
        header: true,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appTheme(context).textTheme.headlineSmall!.copyWith(
            fontSize: 20.spMin,
            height: 23.5 / 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
