import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../main.dart';
import '../../domain/entities/alarm_draft.dart';
import '../../domain/entities/alarm_schedule.dart';
import 'time_wheel.dart';

/// The app's words for naming a set of days ([repeatLabel]).
RepeatWords repeatWordsOf(AppLocalizations strings) => RepeatWords(
  once: strings.repeat_once,
  everyDay: strings.repeat_every_day,
  weekdays: strings.repeat_weekdays,
  weekends: strings.repeat_weekends,
  everySingle: strings.repeat_every_single,
  everyExcept: strings.repeat_every_except,
  dayShort: strings.day_short.split(','),
);

/// "When it rings": a time and the days it rings at, as many times as needed (the
/// logic is in alarm_schedule.dart).
///
/// ONE schedule is the plain alarm: the wheel on the page itself (no card), the seven
/// days 14 below it. "Add another time" makes a second one, and only then do the
/// schedules become CARDS (radius 22, 10 apart): a 62 header (the time, the days'
/// name, a round chevron; orange while open), the wheel (always mounted, so it is at
/// its time when it opens; one card open at a time), and the days. A card opened lower
/// down is brought into view once its wheel has opened; a new card opens.
///
/// THE SEVEN DAYS mean one thing everywhere: tap a day to put it in THIS card. On
/// (orange, black letters), free (a quiet grey disc) or rung by another card (dashed
/// outline, dim letters; tapping moves it here). A move says so quietly: the card it
/// left glows once on its days' name, and the line under the cards reads "Sunday moved
/// from 6:30 AM" for 2.6 s before "Add another time" comes back.
///
/// (The design's first-time "peek" at a closed card's wheel belongs to editing an
/// alarm that already has several times; a new alarm's cards open as they come.)
class ScheduleCards extends StatefulWidget {
  const ScheduleCards({
    super.key,
    required this.cards,
    required this.onTime,
    required this.onDay,
    required this.onAdd,
  });

  final List<ScheduleCard> cards;
  final void Function(String id, AlarmTime time) onTime;
  final void Function(String id, int day) onDay;
  final VoidCallback onAdd;

  @override
  State<ScheduleCards> createState() => _ScheduleCardsState();
}

class _Moved {
  const _Moved(this.day, this.fromId, this.from, this.n);

  final int day;
  final String fromId;
  final String from;

  /// Counts the moves, so the same card can glow again.
  final int n;
}

class _ScheduleCardsState extends State<ScheduleCards> {
  String? _openId;
  _Moved? _moved;
  Timer? _movedTimer;
  Timer? _scrollTimer;
  final _keys = <String, GlobalKey>{};
  final _seen = <String>{};

  /// Cards that just left, kept while they fold away (with where they stood).
  final _leaving = <({ScheduleCard card, int index})>[];

  bool get _multi => widget.cards.length > 1;
  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _seen.addAll(widget.cards.map((c) => c.id));
  }

  @override
  void didUpdateWidget(ScheduleCards old) {
    super.didUpdateWidget(old);
    final ids = widget.cards.map((c) => c.id).toSet();
    for (var i = 0; i < old.cards.length; i++) {
      final card = old.cards[i];
      if (!ids.contains(card.id) &&
          !_leaving.any((g) => g.card.id == card.id)) {
        _leaving.add((card: card, index: i));
      }
    }
    // A new card opens; the one that was open folds.
    final added = widget.cards.where(
      (c) => !old.cards.any((o) => o.id == c.id),
    );
    if (added.isNotEmpty) _open(added.last.id);
  }

  @override
  void dispose() {
    _movedTimer?.cancel();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _open(String? id) {
    setState(() => _openId = id);
    if (id == null) return;
    // Bring a card opened further down into view once its wheel has opened.
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 420), () {
      final ctx = _keys[id]?.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: _still ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _pickDay(ScheduleCard card, int day) {
    HapticFeedback.selectionClick();
    ScheduleCard? from;
    for (final c in widget.cards) {
      if (c.id != card.id && c.days.contains(day)) from = c;
    }
    if (from != null) {
      setState(
        () => _moved = _Moved(
          day,
          from!.id,
          from.time.label,
          (_moved?.n ?? 0) + 1,
        ),
      );
      _movedTimer?.cancel();
      _movedTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _moved = null);
      });
    }
    widget.onDay(card.id, day);
  }

  @override
  Widget build(BuildContext context) {
    final entries = <({ScheduleCard card, bool leaving})>[
      for (final c in widget.cards) (card: c, leaving: false),
    ];
    for (final g in _leaving) {
      entries.insert(g.index.clamp(0, entries.length), (
        card: g.card,
        leaving: true,
      ));
    }
    final fresh = {
      for (final c in widget.cards)
        if (!_seen.contains(c.id)) c.id,
    };
    _seen.addAll(widget.cards.map((c) => c.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          _Presence(
            key: ValueKey(entries[i].card.id),
            visible: !entries[i].leaving,
            animateIn: fresh.contains(entries[i].card.id),
            onGone: () {
              if (!mounted) return;
              final id = entries[i].card.id;
              setState(() => _leaving.removeWhere((g) => g.card.id == id));
            },
            child: Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10.h),
              child: _card(entries[i].card, entries[i].leaving),
            ),
          ),
        _roomLine(),
      ],
    );
  }

  Widget _card(ScheduleCard card, bool leaving) {
    final strings = appLanguage(context);
    final words = repeatWordsOf(strings);
    final multi = _multi || leaving;
    final open = !multi || _openId == card.id;
    final others = [
      for (final c in widget.cards)
        if (c.id != card.id) c,
    ];
    final repeat = repeatLabel(card.days, words);
    final dayNames = strings.day_names.split(',');

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (multi)
          _Header(
            time: card.time,
            repeat: repeat,
            open: open,
            glow: _moved?.fromId == card.id ? _moved!.n : 0,
            hint: open
                ? strings.create_alarm_close_clock
                : strings.create_alarm_open_clock,
            onTap: () => _open(open ? null : card.id),
          ),
        TweenAnimationBuilder<double>(
          // Opens in 400 ms, folds in 450 (height and opacity together).
          tween: Tween(end: open ? 1 : 0),
          duration: _still
              ? Duration.zero
              : Duration(milliseconds: open ? 400 : 450),
          curve: RiseIn.curve,
          builder: (_, f, child) => ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: f.clamp(0.0, 1.0),
              child: Opacity(opacity: f.clamp(0.0, 1.0), child: child),
            ),
          ),
          child: IgnorePointer(
            ignoring: !open,
            child: ExcludeSemantics(
              excluding: !open,
              child: TimeWheel(
                time: card.time,
                hourLabel: strings.create_alarm_hour,
                minuteLabel: strings.create_alarm_minute,
                meridiemLabel: strings.create_alarm_meridiem,
                onChanged: (t) => widget.onTime(card.id, t),
              ),
            ),
          ),
        ),
        Padding(
          padding: multi
              ? REdgeInsets.fromLTRB(14, 8, 14, 14)
              : EdgeInsets.only(top: 14.h),
          child: _Weekdays(
            days: card.days,
            taken: [for (final c in others) ...c.days],
            dayShort: words.dayShort,
            dayNames: dayNames,
            awayLabel: (d) => strings.create_alarm_day_away(
              dayNames[d],
              others.firstWhere((c) => c.days.contains(d)).time.label,
            ),
            onToggle: leaving ? (_) {} : (d) => _pickDay(card, d),
          ),
        ),
      ],
    );

    return KeyedSubtree(
      key: _keys.putIfAbsent(card.id, GlobalKey.new),
      child: IgnorePointer(
        ignoring: leaving,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: multi ? AppColor.cardColor : AppColor.transparent,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: body,
        ),
      ),
    );
  }

  /// The one line under the cards (so nothing jumps when a day is tapped): the move
  /// note, "Add another time" while there is room, the "Rings once" hint while no day
  /// is lit, or nothing once every day is taken.
  Widget _roomLine() {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final cards = widget.cards;
    final nothingLit = cards.length == 1 && cards[0].days.isEmpty;
    final moved = _moved;

    final Widget child;
    final double height;
    if (moved != null) {
      height = 80;
      child = Padding(
        key: ValueKey('moved${moved.n}'),
        padding: EdgeInsets.only(top: 6.h),
        child: SizedBox(
          height: 44.h,
          child: Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSvgIcon(
                  Assets.icons.check,
                  size: 14.r,
                  color: AppColor.primary,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    strings.create_alarm_moved(
                      strings.day_names.split(',')[moved.day],
                      moved.from,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontSize: 14.5.spMin,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (nothingLit) {
      height = 88;
      child = Padding(
        key: const ValueKey('hint'),
        padding: EdgeInsets.only(top: 14.h),
        child: Text(
          strings.create_alarm_hint_once,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium!.copyWith(
            fontSize: 14.5.spMin,
            color: AppColor.textMuted,
          ),
        ),
      );
    } else if (canAddCard(cards)) {
      height = 80;
      child = Padding(
        key: const ValueKey('add'),
        padding: EdgeInsets.only(top: 6.h),
        child: Center(
          child: _AddTimeLink(
            label: strings.create_alarm_add_time,
            onTap: widget.onAdd,
          ),
        ),
      );
    } else {
      height = 30;
      child = const SizedBox.shrink(key: ValueKey('none'));
    }

    return AnimatedContainer(
      duration: _still ? Duration.zero : const Duration(milliseconds: 300),
      height: height.h,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _still ? Duration.zero : const Duration(milliseconds: 220),
        child: child,
      ),
    );
  }
}

/// A card's arrival and leaving: it grows in (400 ms) lifting 10 and fading in, and
/// leaves fading, shrinking to 97 % and giving its height back.
class _Presence extends StatefulWidget {
  const _Presence({
    super.key,
    required this.visible,
    required this.animateIn,
    required this.onGone,
    required this.child,
  });

  final bool visible;
  final bool animateIn;
  final VoidCallback onGone;
  final Widget child;

  @override
  State<_Presence> createState() => _PresenceState();
}

class _PresenceState extends State<_Presence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    reverseDuration: const Duration(milliseconds: 260),
    value: widget.animateIn ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: RiseIn.curve,
    reverseCurve: Curves.easeOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animateIn &&
        _controller.value == 0 &&
        !_controller.isAnimating) {
      MediaQuery.disableAnimationsOf(context)
          ? _controller.value = 1
          : _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_Presence old) {
    super.didUpdateWidget(old);
    if (old.visible && !widget.visible) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 0;
        widget.onGone();
      } else {
        _controller.reverse().whenComplete(widget.onGone);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) {
        final v = _curve.value;
        final leaving = !widget.visible;
        final shown = Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: leaving ? Offset.zero : Offset(0, 10 * (1 - v)),
            child: Transform.scale(
              scale: leaving ? 0.97 + 0.03 * v : 1,
              child: child,
            ),
          ),
        );
        // Settled: no clipping or measuring at all.
        if (_controller.value >= 1) return shown;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: v.clamp(0.0, 1.0),
            child: shown,
          ),
        );
      },
    );
  }
}

/// A card's header: the time (32 light, a 15 "AM"), the days' name (glows orange
/// once when a day left this card) and a 28 round chevron, orange while open.
class _Header extends StatelessWidget {
  const _Header({
    required this.time,
    required this.repeat,
    required this.open,
    required this.glow,
    required this.hint,
    required this.onTap,
  });

  final AlarmTime time;
  final String repeat;
  final bool open;
  final int glow;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final still = MediaQuery.disableAnimationsOf(context);
    const duration = Duration(milliseconds: 300);
    return Semantics(
      button: true,
      expanded: open,
      label: strings.create_alarm_card_semantics(time.label, repeat, hint),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: REdgeInsets.fromLTRB(16, 14, 16, 6),
          child: SizedBox(
            height: 42.h,
            child: Row(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    style: textTheme.titleLarge!.copyWith(
                      fontSize: 32.spMin,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                      color: open ? AppColor.primary : AppColor.white,
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: time.clock),
                          WidgetSpan(child: SizedBox(width: 6.w)),
                          TextSpan(
                            text: time.meridiem,
                            style: TextStyle(
                              fontSize: 15.spMin,
                              letterSpacing: 0,
                              color: open
                                  ? AppColor.primary
                                  : AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TweenAnimationBuilder<Color?>(
                      key: ValueKey(glow > 0 ? 'moved$glow' : 'still'),
                      tween: ColorTween(
                        begin: glow > 0 && !still
                            ? AppColor.primary
                            : AppColor.textSecondary,
                        end: AppColor.textSecondary,
                      ),
                      duration: still
                          ? Duration.zero
                          : const Duration(milliseconds: 1650),
                      // 0.25 s of waiting, then easing back to grey.
                      curve: const Interval(250 / 1650, 1, curve: RiseIn.curve),
                      builder: (_, color, _) => Text(
                        repeat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge!.copyWith(color: color),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                AnimatedContainer(
                  duration: duration,
                  width: 28.r,
                  height: 28.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: open
                        ? AppColor.primary.withValues(alpha: 0.16)
                        : AppColor.surfaceSecondary,
                  ),
                  child: AnimatedRotation(
                    // The forward chevron points down when shut, up when open.
                    turns: open ? -0.25 : 0.25,
                    duration: duration,
                    child: AppSvgIcon(
                      Assets.icons.page.chevron,
                      size: 15.r,
                      color: open ? AppColor.primary : AppColor.textSecondary,
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
}

/// "+ Add another time": a 44 tall orange link.
class _AddTimeLink extends StatelessWidget {
  const _AddTimeLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: SizedBox(
          height: 44.h,
          child: Padding(
            padding: REdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  Assets.icons.page.plus,
                  size: 15.r,
                  color: AppColor.primary,
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: appTheme(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 15.5.spMin,
                    fontWeight: FontWeight.w500,
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The seven days as circles of (width - 30) / 7, at most 46, spread to the edges.
class _Weekdays extends StatelessWidget {
  const _Weekdays({
    required this.days,
    required this.taken,
    required this.dayShort,
    required this.dayNames,
    required this.awayLabel,
    required this.onToggle,
  });

  final List<int> days;

  /// Days another card rings (drawn dashed).
  final List<int> taken;
  final List<String> dayShort;
  final List<String> dayNames;
  final String Function(int day) awayLabel;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = ((c.maxWidth - 30) / 7).clamp(0.0, 46.r);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 0; d < 7; d++)
              _Day(
                size: size,
                label: dayShort[d],
                on: days.contains(d),
                away: !days.contains(d) && taken.contains(d),
                semanticsLabel: !days.contains(d) && taken.contains(d)
                    ? awayLabel(d)
                    : dayNames[d],
                onTap: () => onToggle(d),
              ),
          ],
        );
      },
    );
  }
}

class _Day extends StatefulWidget {
  const _Day({
    required this.size,
    required this.label,
    required this.on,
    required this.away,
    required this.semanticsLabel,
    required this.onTap,
  });

  final double size;
  final String label;
  final bool on;
  final bool away;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  State<_Day> createState() => _DayState();
}

class _DayState extends State<_Day> {
  bool _down = false;

  void _press(bool down) => setState(() => _down = down);

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    final away = widget.away;
    return Semantics(
      button: true,
      toggled: on,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.92 : 1,
          duration: const Duration(milliseconds: 250),
          curve: const Cubic(0.3, 1.4, 0.5, 1),
          child: CustomPaint(
            foregroundPainter: away ? const _DashedRing() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on
                    ? AppColor.primary
                    : away
                    ? AppColor.transparent
                    : AppColor.controlFill,
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: appTheme(context).textTheme.labelLarge!.copyWith(
                  fontSize: 13.5.spMin,
                  letterSpacing: -0.2,
                  color: on
                      ? AppColor.onPrimary
                      : away
                      ? AppColor.textTertiary
                      : AppColor.white.withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1.5 dashed circle inside the day's box (a day another card rings).
class _DashedRing extends CustomPainter {
  const _DashedRing();

  @override
  void paint(Canvas canvas, Size size) {
    const w = 1.5;
    final path = Path()
      ..addOval(
        Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: (size.shortestSide - w) / 2,
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = AppColor.textMuted;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7.5) {
        canvas.drawPath(m.extractPath(d, (d + 4.5).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => false;
}
