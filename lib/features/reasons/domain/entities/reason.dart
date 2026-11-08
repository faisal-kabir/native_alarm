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
  final int areaId;
  final AreaOfLife? area;
  final int soundTypeId;
  final SoundType? sound;
  final int voiceId;
  final Voice? voice;
  final DateTime? createdAt;

  const Reason({
    required this.id,
    required this.name,
    this.purpose = '',
    this.why = '',
    required this.lengthSeconds,
    required this.areaId,
    this.area,
    required this.soundTypeId,
    this.sound,
    required this.voiceId,
    this.voice,
    this.createdAt,
  });

  /// The area's display name, e.g. "Health" (empty when unknown).
  String get areaTitle => area?.title ?? '';

  /// The tone's display name, e.g. "Calm" (empty when unknown).
  String get toneTitle => sound?.title ?? '';

  /// What the user chose, as it is saved now.
  ReasonDraft get draft => ReasonDraft(
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
    areaId,
    area,
    soundTypeId,
    sound,
    voiceId,
    voice,
    createdAt,
  ];
}
