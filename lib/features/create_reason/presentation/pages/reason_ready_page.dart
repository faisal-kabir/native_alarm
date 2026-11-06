import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/dimension.dart';
import '../../../../core/widgets/cached_svg_icon.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/suggestion_list.dart';
import '../../../../main.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../../../voice/domain/entities/voice.dart';
import '../bloc/reason_ready_bloc.dart';
import '../bloc/reason_ready_event.dart';
import '../bloc/reason_ready_state.dart';
import '../widgets/reason_name_field.dart';
import '../widgets/voice_row.dart';

/// What the ready screen shows: the saved reason and what it was made of.
class ReasonReadyArgs {
  const ReasonReadyArgs({
    required this.reason,
    required this.purpose,
    required this.why,
    required this.area,
    required this.voice,
    required this.sound,
  });

  final Reason reason;
  final String purpose;

  /// Empty when "why it matters" was skipped.
  final String why;
  final AreaOfLife area;
  final Voice voice;
  final SoundType sound;
}

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
  const ReasonReadyPage({super.key, required this.args});

  final ReasonReadyArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<ReasonReadyBloc>()
            ..add(ReasonReadyStartedEvent(args.reason.id, args.reason.name)),
      child: _ReadyView(args: args),
    );
  }
}

class _ReadyView extends StatefulWidget {
  const _ReadyView({required this.args});

  final ReasonReadyArgs args;

  @override
  State<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<_ReadyView> with TickerProviderStateMixin {
  /// Seconds the arrival timeline runs; every piece is a window inside it.
  static const double _total = 2.5;

  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );
  late final AnimationController _seal = AnimationController.unbounded(
    vsync: this,
  );
  Timer? _sealTimer;
  Timer? _hapticTimer;
  bool _started = false;

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
      _seal.value = 1;
      return;
    }
    _t.forward();
    _sealTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _seal.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 260, damping: 20),
          0,
          1,
          0,
        ),
      );
    });
  }

  @override
  void dispose() {
    _sealTimer?.cancel();
    _hapticTimer?.cancel();
    _t.dispose();
    _seal.dispose();
    super.dispose();
  }

  /// A rise-and-fade window of the timeline ([start] and [dur] in seconds).
  Animation<double> _window(double start, double dur) => CurvedAnimation(
    parent: _t,
    curve: Interval(
      start / _total,
      (start + dur) / _total,
      curve: RiseIn.curve,
    ),
  );

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
    final args = widget.args;
    final still = MediaQuery.disableAnimationsOf(context);
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
                                child: _Seal(
                                  t: _t,
                                  spring: _seal,
                                  still: still,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              _Rise(
                                animation: _window(0.9, 0.7),
                                dy: 12,
                                child: HighlightedTitle(
                                  strings.reason_ready_title,
                                  fontSize: 36,
                                  textAlign: TextAlign.center,
                                  animate: false,
                                ),
                              ),
                              SizedBox(height: 28.h),
                              _Rise(
                                animation: _window(1.2, 0.7),
                                dy: 16,
                                child: _ReadyCard(args: args),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _Rise(
                  animation: _window(1.6, 0.6),
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
                        _GhostButton(
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

/// Fades [child] in (an opacity layer, no rebuild) while it lifts [dy] into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.dy, required this.child});

  final Animation<double> animation;
  final double dy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lift = dy.h;
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, lift * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------ seal

/// A green disc with a drawn tick; a green ring leaves it once.
class _Seal extends StatelessWidget {
  const _Seal({required this.t, required this.spring, required this.still});

  final Animation<double> t;
  final Animation<double> spring;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final size = 64.r;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!still)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: t,
                    builder: (_, _) {
                      final s = t.value * _ReadyViewState._total;
                      final r = ((s - 0.9) / 1.6).clamp(0.0, 1.0);
                      if (r <= 0 || r >= 1) return const SizedBox.shrink();
                      final scale = 1 + 0.7 * Curves.easeOut.transform(r);
                      // Opacity 0 → .45 → 0, each half eased out.
                      final o = r < 0.5
                          ? 0.45 * Curves.easeOut.transform(r / 0.5)
                          : 0.45 *
                                (1 - Curves.easeOut.transform((r - 0.5) / 0.5));
                      return Transform.scale(
                        scale: scale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColor.success.withValues(alpha: o),
                              width: 1.5.r,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: spring,
                  builder: (_, child) {
                    final v = spring.value;
                    return Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * v,
                        child: child,
                      ),
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.success.withValues(alpha: 0.16),
                      border: Border.all(
                        color: AppColor.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: Size.square(28.r),
                        painter: _TickPainter(
                          CurvedAnimation(
                            parent: t,
                            curve: Interval(
                              0.55 / _ReadyViewState._total,
                              1.0 / _ReadyViewState._total,
                              curve: RiseIn.curve,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

// ------------------------------------------------------------------------ card

/// The reason: area, editable name, purpose, why, then voice and tone.
class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.args});

  final ReasonReadyArgs args;

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final textTheme = appTheme(context).textTheme;
    final tint = Color(args.area.color ?? AppColor.primary.toARGB32());
    final areaInk = Color.lerp(AppColor.white, tint, 0.7)!;
    final icon = args.area.icon;
    final why = args.why.trim();
    return Container(
      decoration: BoxDecoration(
        color: AppColor.cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColor.fieldRule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 16.h,
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        CachedSvgIcon(
                          path: icon,
                          size: 16.r,
                          color: areaInk,
                          fallback: const SizedBox.shrink(),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Flexible(
                        child: SuggestionLabel(args.area.title, color: areaInk),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                BlocBuilder<ReasonReadyBloc, ReasonReadyState>(
                  buildWhen: (a, b) => a.name != b.name,
                  builder: (context, state) => ReasonNameField(
                    value: state.name,
                    onCommit: (name) => context.read<ReasonReadyBloc>().add(
                      ReasonRenamedEvent(name),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  args.purpose,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge!.copyWith(
                    fontSize: 20.spMin,
                    height: 27 / 20,
                    letterSpacing: -0.2,
                    color: AppColor.textColor,
                  ),
                ),
                if (why.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  SuggestionLabel(strings.reason_ready_why),
                  SizedBox(height: 6.h),
                  Text(
                    why,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge!.copyWith(
                      fontSize: 15.spMin,
                      height: 21 / 15,
                      letterSpacing: 0,
                      color: AppColor.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 1,
            child: const ColoredBox(color: AppColor.fieldRule),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: REdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        VoiceAvatar(voice: args.voice, size: 32),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _Fact(
                            label: strings.reason_ready_voice,
                            value: args.voice.name,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColor.fieldRule),
                      ),
                    ),
                    padding: REdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: _Fact(
                      label: strings.reason_ready_tone,
                      value: args.sound.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "VOICE" over "Astra".
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionLabel(label),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appTheme(context).textTheme.bodyLarge!.copyWith(
            fontSize: 15.spMin,
            height: 17.5 / 15,
            fontWeight: Dimension.textMedium,
            letterSpacing: 0,
            color: AppColor.textColor,
          ),
        ),
      ],
    );
  }
}

/// The quiet "Save for later" under the main button.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: 44.h,
          alignment: Alignment.center,
          child: Text(
            label,
            style: appTheme(context).textTheme.bodyLarge!.copyWith(
              fontSize: 15.5.spMin,
              fontWeight: Dimension.textMedium,
              letterSpacing: 0,
              color: AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
