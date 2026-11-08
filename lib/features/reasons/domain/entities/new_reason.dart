import 'package:equatable/equatable.dart';

import 'reason_draft.dart';

/// What the Create Reason flow collected, ready to be saved as a reason.
class NewReason extends Equatable {
  /// The area's `name`: the reason is named after it (with " 2", " 3", ... added when
  /// the user already has a reason of that name, see `nextReasonName`).
  final String baseName;
  final ReasonDraft draft;

  const NewReason({required this.baseName, required this.draft});

  @override
  List<Object?> get props => [baseName, draft];
}
