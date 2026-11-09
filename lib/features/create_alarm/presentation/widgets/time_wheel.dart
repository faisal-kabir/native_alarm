import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../main.dart';
import '../../domain/entities/alarm_draft.dart';

/// The clock's wheel: hours, minutes and AM / PM as three snapping columns on one grey
/// band (188 tall; a 56 band; columns 78 wide with rows of 56; the chosen row white,
/// the others grey at 55 %). Hours run 1-12 and minutes 0-59, not in a loop. A tick
/// of haptic feedback on every row it passes; for a screen reader each column is an
/// adjustable value ("Hour, 6"). It follows [time] when that changes from outside.
class TimeWheel extends StatelessWidget {
  const TimeWheel({
    super.key,
    required this.time,
    required this.onChanged,
    required this.hourLabel,
    required this.minuteLabel,
    required this.meridiemLabel,
  });

  final AlarmTime time;
  final ValueChanged<AlarmTime> onChanged;

  /// Spoken names of the three columns.
  final String hourLabel;
  final String minuteLabel;
  final String meridiemLabel;

  /// The wheel's height before scaling (the schedule cards fold it).
  static const double height = 188;

  static const _hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static final _minutes = [for (var m = 0; m < 60; m++) m];
  static const _meridiems = [false, true];

  @override
  Widget build(BuildContext context) {
    final digits = appTheme(context).textTheme.titleLarge!
        .copyWith(fontSize: 26.spMin, height: 1, color: AppColor.white);
    return SizedBox(
      height: height.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The band sits behind the columns, so the numbers draw over it.
          Container(
            height: 56.h,
            decoration: BoxDecoration(
              color: AppColor.controlFill,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Column<int>(
                label: hourLabel,
                values: _hours,
                value: time.hour,
                onChanged: (h) => onChanged(time.copyWith(hour: h)),
              ),
              SizedBox(
                width: 10.w,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(':', textAlign: TextAlign.center, style: digits),
                ),
              ),
              _Column<int>(
                label: minuteLabel,
                values: _minutes,
                value: time.minute,
                format: (m) => m.toString().padLeft(2, '0'),
                onChanged: (m) => onChanged(time.copyWith(minute: m)),
              ),
              SizedBox(width: 2.w),
              _Column<bool>(
                label: meridiemLabel,
                values: _meridiems,
                value: time.pm,
                format: (pm) => pm ? 'PM' : 'AM',
                onChanged: (pm) => onChanged(time.copyWith(pm: pm)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One snapping column of [values] (78 x 168, rows of 56).
class _Column<T> extends StatefulWidget {
  const _Column({
    required this.values,
    required this.value,
    required this.onChanged,
    required this.label,
    this.format,
  });

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String label;
  final String Function(T)? format;

  @override
  State<_Column<T>> createState() => _ColumnState<T>();
}

class _ColumnState<T> extends State<_Column<T>> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _index(widget.value));

  int _index(T v) =>
      widget.values.indexOf(v).clamp(0, widget.values.length - 1);

  String _text(T v) => widget.format?.call(v) ?? '$v';

  @override
  void didUpdateWidget(_Column<T> old) {
    super.didUpdateWidget(old);
    // Follow a value that changed from outside the wheel.
    final i = _index(widget.value);
    if (_controller.hasClients && _controller.selectedItem != i) {
      _controller.jumpToItem(i);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final now = _index(widget.value);
    final i = (now + delta).clamp(0, widget.values.length - 1);
    if (i == now) return;
    HapticFeedback.selectionClick();
    widget.onChanged(widget.values[i]);
  }

  @override
  Widget build(BuildContext context) {
    final active = _index(widget.value);
    final last = widget.values.length - 1;
    final style = appTheme(context).textTheme.titleLarge!.copyWith(
      fontSize: 26.spMin,
      height: 1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: widget.label,
      value: _text(widget.value),
      increasedValue: _text(widget.values[(active + 1).clamp(0, last)]),
      decreasedValue: _text(widget.values[(active - 1).clamp(0, last)]),
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 78.w,
          height: 168.h,
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 56.h,
            // Flat, like the design: no curve, no magnifier.
            diameterRatio: 100,
            perspective: 0.0001,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              final v = widget.values[i];
              if (v == widget.value) return;
              HapticFeedback.selectionClick();
              widget.onChanged(v);
            },
            childDelegate: ListWheelChildListDelegate(
              children: [
                for (var i = 0; i <= last; i++)
                  Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: i == active ? 1 : 0.55,
                      child: Text(
                        _text(widget.values[i]),
                        style: style.copyWith(
                          color: i == active
                              ? AppColor.white
                              : AppColor.textSecondary,
                        ),
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
