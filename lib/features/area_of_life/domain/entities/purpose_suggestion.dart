import 'package:equatable/equatable.dart';

/// A suggested answer to "What are you working toward?" for one area of life
/// (table `purpose_suggestion` on the server).
class PurposeSuggestion extends Equatable {
  final int id;
  final int areaId;

  /// The suggested wording (column `suggestion`).
  final String text;

  const PurposeSuggestion({
    required this.id,
    required this.areaId,
    required this.text,
  });

  @override
  List<Object?> get props => [id, areaId, text];
}
