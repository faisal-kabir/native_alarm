import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../gen/assets.gen.dart';
import '../../main.dart';
import '../theme/app_color.dart';
import 'app_svg_icon.dart';

/// Opens [builder]'s bottom sheet and returns what it closed with (null when it was
/// dismissed). Build the content with [AppSheet]; close it from inside with
/// `AppSheetScope.of(context).close(result)`.
///
/// The app's one bottom sheet (use it for every picker, never another kind):
/// * slides up from the bottom edge on a spring (stiffness 420, damping 40, mass 0.9)
///   while a black 50 % scrim fades in (200 ms); slides back down to close;
/// * follows a downward drag at 40 % (never up); let go past 110 dp or faster than
///   700 dp/s and it closes, otherwise it springs back. A list inside keeps its own
///   scrolling;
/// * a tap on the scrim, the close chip or the system back closes it;
/// * at most 88 % of the screen high, as high as its content below that;
/// * reduce motion: no slide, it is simply there / gone.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => Navigator.of(
  context,
  rootNavigator: true,
).push<T>(_SheetRoute<T>(builder: builder));

/// What a sheet's content uses to close it (with its exit animation).
class AppSheetScope extends InheritedWidget {
  const AppSheetScope._({required this.close, required super.child});

  /// Slides out, then pops with [result].
  final void Function([Object? result]) close;

  static AppSheetScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSheetScope>();
    assert(scope != null, 'No AppSheet above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppSheetScope old) => false;
}

abstract final class _Sheet {
  static const spring = SpringDescription(
    mass: 0.9,
    stiffness: 420,
    damping: 40,
  );
  static const maxHeightFactor = 0.88;
}

class _SheetRoute<T> extends PopupRoute<T> {
  _SheetRoute({required this.builder});

  final WidgetBuilder builder;

  // The sheet draws its own scrim and runs its own spring, in and out.
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _SheetHost(builder: builder);
}

class _SheetHost extends StatefulWidget {
  const _SheetHost({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> with TickerProviderStateMixin {
  // How much of the sheet is below the screen edge: 1 = away, 0 = in place.
  late final AnimationController _hidden = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late final AnimationController _scrim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scrimOpacity = _scrim.drive(
    CurveTween(curve: Curves.easeOut),
  );

  bool _started = false;
  bool _closing = false;
  double _height = 1;
  double _drag = 0; // finger travel, before the 40 % resistance

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_still) {
      _hidden.value = 0;
      _scrim.value = 1;
    } else {
      _scrim.forward();
      _hidden.animateWith(SpringSimulation(_Sheet.spring, 1, 0, 0));
    }
  }

  @override
  void dispose() {
    _hidden.dispose();
    _scrim.dispose();
    super.dispose();
  }

  void _close([Object? result]) {
    if (_closing || !mounted) return;
    _closing = true;
    if (_still) {
      Navigator.of(context).pop(result);
      return;
    }
    _scrim.reverse();
    _hidden
        .animateWith(SpringSimulation(_Sheet.spring, _hidden.value, 1, 0))
        .whenComplete(() {
          if (mounted) Navigator.of(context).pop(result);
        });
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_closing) return;
    _hidden.stop();
    _drag = (_drag + d.delta.dy).clamp(0.0, double.infinity);
    _hidden.value = 0.4 * _drag / _height;
  }

  void _dragEnd(DragEndDetails d) {
    if (_closing) return;
    final v = d.velocity.pixelsPerSecond.dy;
    final away = _drag > 110 || v > 700;
    _drag = 0;
    if (away) {
      _close();
      return;
    }
    _hidden.animateWith(
      SpringSimulation(_Sheet.spring, _hidden.value, 0, v / _height * 0.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.sizeOf(context).height * _Sheet.maxHeightFactor;
    final radius = Radius.circular(34.r);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: FadeTransition(
                opacity: _scrimOpacity,
                child: const ColoredBox(color: AppColor.scrim),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _hidden,
              builder: (_, child) => FractionalTranslation(
                translation: Offset(0, _hidden.value),
                child: child,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: GestureDetector(
                  onVerticalDragUpdate: _dragUpdate,
                  onVerticalDragEnd: _dragEnd,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      _height = c.maxHeight.isFinite && c.maxHeight > 0
                          ? c.maxHeight
                          : maxHeight;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColor.cardColor,
                          borderRadius: BorderRadius.vertical(top: radius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.scrim,
                              blurRadius: 40.r,
                              offset: Offset(0, -10.r),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: radius),
                          child: Material(
                            type: MaterialType.transparency,
                            child: AppSheetScope._(
                              close: _close,
                              child: Builder(builder: widget.builder),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A sheet's content: the grabber, the [title] with the round close chip, the
/// scrolling [body] and the optional [footer] (usually a `PillButton`, padded here).
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
  });

  final String title;

  /// One quiet line under the title ("Each alarm plays one reason.").
  final String? subtitle;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      // A text field inside keeps the footer above the keyboard.
      padding: EdgeInsets.only(bottom: keyboard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 9.h),
          Center(
            child: Container(
              width: 36.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColor.textMuted,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
          Padding(
            padding: REdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: appTheme(context).textTheme.headlineSmall!
                              .copyWith(
                                fontSize: 20.spMin,
                                height: 23.5 / 20,
                                letterSpacing: -0.4,
                                color: AppColor.titleColor,
                              ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 3.h),
                        Text(
                          subtitle!,
                          style: appTheme(context).textTheme.bodyMedium!
                              .copyWith(color: AppColor.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                const _CloseChip(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              // Without a footer the body keeps clear of the home indicator itself.
              padding: EdgeInsets.fromLTRB(
                20.w,
                0,
                20.w,
                (footer == null && keyboard == 0 ? bottom : 0) + 10.h,
              ),
              child: body,
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                10.h,
                20.w,
                (keyboard > 0 ? 0 : bottom) + 8.h,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class _CloseChip extends StatelessWidget {
  const _CloseChip();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: appLanguage(context).common_close,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => AppSheetScope.of(context).close(),
        child: Container(
          width: 30.r,
          height: 30.r,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColor.controlFill,
            shape: BoxShape.circle,
          ),
          child: AppSvgIcon(
            Assets.icons.voice.close,
            size: 15.r,
            color: AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}
