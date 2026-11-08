import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/ghost_button.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/spring_in.dart';
import '../../../../main.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../bloc/reason_ready_bloc.dart';
import '../bloc/reason_ready_event.dart';
import '../bloc/reason_ready_state.dart';
import '../widgets/reason_name_field.dart';
import '../widgets/reason_summary_card.dart';

/// "Your reason is ready." - shown after the reason is saved (it replaces the Create
/// Reason page). The name can be changed in place (the `reason` row is updated by
/// its id). There is no close button: back (button or gesture) does what "Save for
/// later" does - return to the reasons list, where the new reason rises in.
///
/// Arrival, on one 2.5 s timeline: the seal springs in (0.15 s), its tick is drawn
/// (0.55 s), a green ring leaves it (0.9 s), the heading (0.9 s), the card (1.2 s)
/// and the buttons (1.6 s) rise in; one light haptic at 0.65 s. With reduced motion
/// everything is simply there.
class ReasonReadyPage extends StatelessWidget {
  const ReasonReadyPage({super.key, required this.reason});

  /// The reason just saved (its area, sound and voice joined in).
  final Reason reason;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<ReasonReadyBloc>()
            ..add(ReasonReadyStartedEvent(reason.id, reason.name)),
      child: _ReadyView(reason: reason),
    );
  }
}

class _ReadyView extends StatefulWidget {
  const _ReadyView({required this.reason});

  final Reason reason;

  @override
  State<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<_ReadyView>
    with SingleTickerProviderStateMixin {
  /// Seconds the arrival timeline runs; every piece is a window inside it.
  static const double _total = 2.5;

  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  // The windows of the timeline, made once (they listen to [_t] only while shown).
  late final Animation<double> _tick = _window(0.55, 0.45);
  late final Animation<double> _ring = _t.drive(
    CurveTween(curve: Interval(0.9 / _total, 1)),
  );
  late final Animation<double> _heading = _window(0.9, 0.7);
  late final Animation<double> _card = _window(1.2, 0.7);
  late final Animation<double> _buttons = _window(1.6, 0.6);

  Timer? _hapticTimer;
  bool _started = false;

  /// A rise-and-fade window of the timeline ([start] and [dur] in seconds).
  Animation<double> _window(double start, double dur) => _t.drive(
    CurveTween(
      curve: Interval(
        start / _total,
        (start + dur) / _total,
        curve: RiseIn.curve,
      ),
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _hapticTimer = Timer(
      const Duration(milliseconds: 650),
      HapticFeedback.lightImpact,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = 1;
    } else {
      _t.forward();
    }
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _t.dispose();
    super.dispose();
  }

  /// Back to the reasons list (the new reason is already in it). A name being edited
  /// is saved first.
  void _saveForLater() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveForLater();
      },
      child: BlocListener<ReasonReadyBloc, ReasonReadyState>(
        listenWhen: (a, b) => a.renameFailures != b.renameFailures,
        listener: (context, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.reason_rename_failed))),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Read out once, politely, when the screen arrives.
                Semantics(
                  liveRegion: true,
                  label: strings.reason_ready_announcement,
                  child: const SizedBox.shrink(),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: REdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24.h,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: _Seal(tick: _tick, ring: _ring),
                              ),
                              SizedBox(height: 24.h),
                              RiseTransition(
                                animation: _heading,
                                dy: 12,
                                child: HighlightedTitle(
                                  strings.reason_ready_title,
                                  fontSize: 36,
                                  textAlign: TextAlign.center,
                                  animate: false,
                                ),
                              ),
                              SizedBox(height: 28.h),
                              RiseTransition(
                                animation: _card,
                                dy: 16,
                                child: ReasonSummaryCard(
                                  reason: widget.reason,
                                  name:
                                      BlocBuilder<
                                        ReasonReadyBloc,
                                        ReasonReadyState
                                      >(
                                        buildWhen: (a, b) => a.name != b.name,
                                        builder: (context, state) =>
                                            ReasonNameField(
                                              value: state.name,
                                              onCommit: (name) => context
                                                  .read<ReasonReadyBloc>()
                                                  .add(
                                                    ReasonRenamedEvent(name),
                                                  ),
                                            ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                RiseTransition(
                  animation: _buttons,
                  dy: 12,
                  child: Padding(
                    padding: REdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PillButton(
                          label: strings.reason_ready_use_with_alarm,
                          enabled: true,
                          onPressed: _saveForLater,
                        ),
                        SizedBox(height: 10.h),
                        GhostButton(
                          label: strings.reason_ready_save_for_later,
                          onPressed: _saveForLater,
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
}

// ------------------------------------------------------------------------ seal

/// A green disc that springs in (after 0.15 s) with a drawn [tick]; a green ring
/// leaves it once ([ring], 0 → 1). Painters only: nothing rebuilds per frame.
class _Seal extends StatelessWidget {
  const _Seal({required this.tick, required this.ring});

  final Animation<double> tick;
  final Animation<double> ring;

  @override
  Widget build(BuildContext context) {
    final size = 64.r;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RingPainter(ring),
          child: SpringIn(
            delay: const Duration(milliseconds: 150),
            spring: const SpringDescription(
              mass: 1,
              stiffness: 260,
              damping: 20,
            ),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.success.withValues(alpha: 0.16),
                border: Border.all(
                  color: AppColor.success.withValues(alpha: 0.35),
                ),
              ),
              child: CustomPaint(
                size: Size.square(28.r),
                painter: _TickPainter(tick),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ring leaving the seal: it grows to 1.7x while its opacity goes 0 → .45 → 0.
class _RingPainter extends CustomPainter {
  _RingPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final r = progress.value;
    if (r <= 0 || r >= 1) return;
    final half = r < 0.5;
    final eased = Curves.easeOut.transform(half ? r / 0.5 : (r - 0.5) / 0.5);
    final opacity = 0.45 * (half ? eased : 1 - eased);
    final radius = size.width / 2 * (1 + 0.7 * Curves.easeOut.transform(r));
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColor.success.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// The tick (24 grid: M5 12.5 l4.2 4.2 L19 7, round, 2.6 wide) drawn from its start
/// to [progress] of its length. Repaints itself; nothing rebuilds.
class _TickPainter extends CustomPainter {
  _TickPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value.clamp(0.0, 1.0);
    if (p <= 0) return;
    final k = size.width / 24;
    final path = Path()
      ..moveTo(5 * k, 12.5 * k)
      ..lineTo(9.2 * k, 16.7 * k)
      ..lineTo(19 * k, 7 * k);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * p),
      Paint()
        ..color = AppColor.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
