import 'package:equatable/equatable.dart';

/// What the Create Reason flow collected, ready to be saved as a reason.
class NewReason extends Equatable {
  final int areaId;

  /// The area's `name`: the reason is named after it (with " 2", " 3", ... added when
  /// the user already has a reason of that name, see `nextReasonName`).
  final String baseName;
  final String purpose;

  /// "Why it matters"; null when the user skipped it.
  final String? why;
  final int soundTypeId;
  final int voiceId;
  final int lengthSeconds;

  /// Shown in the reasons list on the device: the area's title and tint and the
  /// sound's title.
  final String areaTitle;
  final int? areaColor;
  final String soundTitle;

  const NewReason({
    required this.areaId,
    required this.baseName,
    required this.purpose,
    this.why,
    required this.soundTypeId,
    required this.voiceId,
    required this.lengthSeconds,
    required this.areaTitle,
    this.areaColor,
    required this.soundTitle,
  });

  @override
  List<Object?> get props => [
    areaId,
    baseName,
    purpose,
    why,
    soundTypeId,
    voiceId,
    lengthSeconds,
    areaTitle,
    areaColor,
    soundTitle,
  ];
}
