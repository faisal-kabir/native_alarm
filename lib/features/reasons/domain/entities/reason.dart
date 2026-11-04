import 'package:equatable/equatable.dart';

import 'reason_area.dart';
import 'reason_tone.dart';

/// "The why behind your day": a named message in one area of life, in one tone.
class Reason extends Equatable {
  final String id;
  final String name;
  final ReasonArea area;
  final ReasonTone tone;

  const Reason({
    required this.id,
    required this.name,
    required this.area,
    required this.tone,
  });

  @override
  List<Object?> get props => [id, name, area, tone];
}
