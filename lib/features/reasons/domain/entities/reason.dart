import 'package:equatable/equatable.dart';

import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../../../voice/domain/entities/voice.dart';
import 'reason_draft.dart';

/// "The why behind your day": one row of the server's `reason` table with what it
/// points at - its area of life, its sound (tone) and its voice - joined in, so one
/// object is enough to show it anywhere (list, ready screen, its own screen).
///
/// Areas, tones and voices are never fixed in the app: they come from the server with
/// the reason. [area], [sound] and [voice] are null only if the server did not send
/// them (e.g. a row it no longer has); their ids are always there.
class Reason extends Equatable {
  final int id;
  final String name;
  final String purpose;

  /// "Why it matters"; empty when there is none.
  final String why;
  final int lengthSeconds;

  /// What the goal is about (a chip or the person's own words, at most 20 characters);
  /// empty only for a reason the server has no topic for.
  final String topic;

  /// How it must be spoken to.
  final GoalFocus focus;

  /// The area of life of a reason made before topics existed; null for every newer one.
  final int? areaId;
  final AreaOfLife? area;
  final int soundTypeId;
  final SoundType? sound;
  final int voiceId;
  final Voice? voice;
  final DateTime? createdAt;

  /// The server's `alarm.id` of the alarm that plays it. A Reason belongs to one
  /// alarm at most: null means it is free for a new alarm.
  final int? alarmId;

  const Reason({
    required this.id,
    required this.name,
    this.purpose = '',
    this.why = '',
    required this.lengthSeconds,
    this.topic = '',
    this.focus = GoalFocus.general,
    this.areaId,
    this.area,
    required this.soundTypeId,
    this.sound,
    required this.voiceId,
    this.voice,
    this.createdAt,
    this.alarmId,
  });

  /// What the goal is about, e.g. "Getting fit"; for a reason made before topics
  /// existed, its area's name (empty when neither is known).
  String get areaTitle => topic.isNotEmpty ? topic : (area?.title ?? '');

  /// The tone's display name, e.g. "Calm" (empty when unknown).
  String get toneTitle => sound?.title ?? '';

  /// What the user chose, as it is saved now.
  ReasonDraft get draft => ReasonDraft(
    topic: topic,
    focus: focus,
    areaId: areaId,
    purpose: purpose,
    why: why,
    soundTypeId: soundTypeId,
    voiceId: voiceId,
    lengthSeconds: lengthSeconds,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    purpose,
    why,
    lengthSeconds,
    topic,
    focus,
    areaId,
    area,
    soundTypeId,
    sound,
    voiceId,
    voice,
    createdAt,
    alarmId,
  ];
}
