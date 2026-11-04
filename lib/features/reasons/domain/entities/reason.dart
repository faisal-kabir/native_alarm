import 'package:equatable/equatable.dart';

/// "The why behind your day": a named message in one area of life, in one tone.
///
/// Areas and tones are not fixed in the app: their names (and the area's colour)
/// come from the server together with the reason.
class Reason extends Equatable {
  final String id;
  final String name;

  /// Display name of the area of life, e.g. "Health".
  final String areaName;

  /// Tint of the area as an ARGB value (`0xFFRRGGBB`); null when the server sent none.
  final int? areaColor;

  /// Display name of the tone, e.g. "Calm".
  final String toneName;

  const Reason({
    required this.id,
    required this.name,
    required this.areaName,
    this.areaColor,
    required this.toneName,
  });

  @override
  List<Object?> get props => [id, name, areaName, areaColor, toneName];
}
