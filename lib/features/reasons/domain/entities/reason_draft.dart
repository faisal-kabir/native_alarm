import 'package:equatable/equatable.dart';

/// The parts of a reason the user chooses (everything but its name): what a new
/// reason is made of, and what the reason screen holds while it is being changed.
class ReasonDraft extends Equatable {
  final int areaId;
  final String purpose;

  /// "Why it matters"; empty when there is none.
  final String why;
  final int soundTypeId;
  final int voiceId;
  final int lengthSeconds;

  const ReasonDraft({
    required this.areaId,
    required this.purpose,
    this.why = '',
    required this.soundTypeId,
    required this.voiceId,
    required this.lengthSeconds,
  });

  ReasonDraft copyWith({
    int? areaId,
    String? purpose,
    String? why,
    int? soundTypeId,
    int? voiceId,
    int? lengthSeconds,
  }) => ReasonDraft(
    areaId: areaId ?? this.areaId,
    purpose: purpose ?? this.purpose,
    why: why ?? this.why,
    soundTypeId: soundTypeId ?? this.soundTypeId,
    voiceId: voiceId ?? this.voiceId,
    lengthSeconds: lengthSeconds ?? this.lengthSeconds,
  );

  @override
  List<Object?> get props => [
    areaId,
    purpose,
    why,
    soundTypeId,
    voiceId,
    lengthSeconds,
  ];
}
