import 'package:equatable/equatable.dart';

/// How a reason should sound: "Encouraging", "Calm", ... (table `sound_type`).
class SoundType extends Equatable {
  final int id;
  final String title;

  /// One line about it, e.g. "Positive, warm and uplifting.".
  final String? description;

  /// Path of its single-colour SVG icon on the server (add the base URL to show it).
  final String? icon;

  /// Tint as an ARGB value (`0xFFRRGGBB`); null when the server sent none.
  final int? color;

  const SoundType({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => [id, title, description, icon, color];
}
