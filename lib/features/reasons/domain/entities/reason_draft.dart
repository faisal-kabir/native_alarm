import 'package:equatable/equatable.dart';

/// How a goal must be spoken to: [general], or [gentle] for tender ground (grief,
/// sobriety, illness...), where the writer is asked never to shame, guilt or blame.
/// Every tone is offered either way. Saved as the server's `reason.focus` text.
enum GoalFocus {
  general,
  gentle;

  /// The text the server stores.
  String get value => name;

  /// The focus a server text means; anything unknown is [general].
  static GoalFocus fromValue(Object? value) =>
      value == 'gentle' ? gentle : general;
}

/// The parts of a reason the user chooses (everything but its name): what a new
/// reason is made of, and what the reason screen holds while it is being changed.
class ReasonDraft extends Equatable {
  /// What the goal is about: a chip of the first step, or the person's own words (at
  /// most 20 characters). It is also the goal's name. Empty only for a reason made
  /// before topics existed.
  final String topic;

  /// How it must be spoken to.
  final GoalFocus focus;

  /// The area of life of a reason made before topics existed; null for every newer one.
  final int? areaId;
  final String purpose;

  /// "Why it matters"; empty when there is none.
  final String why;
  final int soundTypeId;
  final int voiceId;
  final int lengthSeconds;

  const ReasonDraft({
    this.topic = '',
    this.focus = GoalFocus.general,
    this.areaId,
    required this.purpose,
    this.why = '',
    required this.soundTypeId,
    required this.voiceId,
    required this.lengthSeconds,
  });

  ReasonDraft copyWith({
    String? topic,
    GoalFocus? focus,
    int? areaId,
    String? purpose,
    String? why,
    int? soundTypeId,
    int? voiceId,
    int? lengthSeconds,
  }) => ReasonDraft(
    topic: topic ?? this.topic,
    focus: focus ?? this.focus,
    areaId: areaId ?? this.areaId,
    purpose: purpose ?? this.purpose,
    why: why ?? this.why,
    soundTypeId: soundTypeId ?? this.soundTypeId,
    voiceId: voiceId ?? this.voiceId,
    lengthSeconds: lengthSeconds ?? this.lengthSeconds,
  );

  @override
  List<Object?> get props => [
    topic,
    focus,
    areaId,
    purpose,
    why,
    soundTypeId,
    voiceId,
    lengthSeconds,
  ];
}
