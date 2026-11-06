import 'package:equatable/equatable.dart';

/// A suggested answer to "Why does it matter to you?" (table `matter_suggestion`).
/// It belongs to an area of life and, optionally, to one purpose suggestion.
class MatterSuggestion extends Equatable {
  final int id;
  final int areaId;

  /// The purpose suggestion it follows, or null for the area's general ones (shown
  /// when the user wrote their own purpose).
  final int? purposeSuggestionId;

  /// The suggested wording (column `suggestion`).
  final String text;

  const MatterSuggestion({
    required this.id,
    required this.areaId,
    this.purposeSuggestionId,
    required this.text,
  });

  @override
  List<Object?> get props => [id, areaId, purposeSuggestionId, text];
}
