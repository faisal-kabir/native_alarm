import 'package:equatable/equatable.dart';

import 'reason_draft.dart';

/// What the Create Goal flow collected, ready to be saved as a reason.
class NewReason extends Equatable {
  /// The reason's name: its topic, as the person picked or wrote it. Two goals may
  /// share a name; the alarm pickers tell them apart by their voice and tone.
  final String name;
  final ReasonDraft draft;

  const NewReason({required this.name, required this.draft});

  @override
  List<Object?> get props => [name, draft];
}
