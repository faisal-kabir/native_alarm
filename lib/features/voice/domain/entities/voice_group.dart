import 'package:equatable/equatable.dart';

/// A heading voices are grouped under, e.g. "Warm" / "Kind, and on your side"
/// (table `voice_group` on the server; a voice points to it with `group_id`).
class VoiceGroup extends Equatable {
  final int id;
  final String title;
  final String? description;

  const VoiceGroup({required this.id, required this.title, this.description});

  @override
  List<Object?> get props => [id, title, description];
}
