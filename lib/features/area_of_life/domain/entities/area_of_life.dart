import 'package:equatable/equatable.dart';

/// One "area of life" the user can build a reason around (health, work, ...).
///
/// The list lives on the server (table `area_of_life`), so names, texts, colours and
/// icons can change without an app update.
class AreaOfLife extends Equatable {
  final int id;

  /// Stable key of the area.
  final String name;

  /// Headline shown in lists.
  final String title;
  final String? description;

  /// Path of the area's single-colour SVG icon on the server, when it has one (not a
  /// full URL: widgets add the base URL, see `mediaUrl`).
  final String? icon;

  /// Tint of the area as an ARGB value (`0xFFRRGGBB`); null when the server sent none.
  final int? color;

  const AreaOfLife({
    required this.id,
    required this.name,
    required this.title,
    this.description,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => [id, name, title, description, icon, color];
}
