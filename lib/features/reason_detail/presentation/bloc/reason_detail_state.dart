import 'package:equatable/equatable.dart';

import '../../../../core/utils/load_status.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../../reasons/domain/entities/reason_draft.dart';
import '../../../sound/domain/entities/sound_type.dart';
import '../../../voice/domain/entities/voice.dart';

class ReasonDetailState extends Equatable {
  /// The reason as saved (follows the device's copy).
  final Reason reason;

  /// What the screen shows: the saved values with the user's held changes on top.
  final ReasonDraft draft;

  /// What the sheets offer: cached areas and voices, and the tones from the server.
  final List<AreaOfLife> areas;
  final List<Voice> voices;
  final List<SoundType> soundTypes;
  final LoadStatus soundTypesStatus;

  final bool saving;

  /// Deleting now, and deleted (the screen leaves).
  final bool deleting;
  final bool deleted;

  /// Go up by one on every failed save / rename / delete, so the page can say so.
  final int saveFailures;
  final int renameFailures;
  final int deleteFailures;

  ReasonDetailState({
    required this.reason,
    ReasonDraft? draft,
    this.areas = const [],
    this.voices = const [],
    this.soundTypes = const [],
    this.soundTypesStatus = LoadStatus.loading,
    this.saving = false,
    this.deleting = false,
    this.deleted = false,
    this.saveFailures = 0,
    this.renameFailures = 0,
    this.deleteFailures = 0,
  }) : draft = draft ?? reason.draft;

  /// Something is held that differs from what is saved (the Save bar shows).
  bool get dirty => draft != reason.draft;

  /// The chosen area, voice and tone (as held), from the lists or else the reason's
  /// own copy.
  AreaOfLife? get area =>
      _pick(areas, (a) => a.id == draft.areaId) ??
      (reason.areaId == draft.areaId ? reason.area : null);

  Voice? get voice =>
      _pick(voices, (v) => v.id == draft.voiceId) ??
      (reason.voiceId == draft.voiceId ? reason.voice : null);

  SoundType? get sound =>
      _pick(soundTypes, (s) => s.id == draft.soundTypeId) ??
      (reason.soundTypeId == draft.soundTypeId ? reason.sound : null);

  static T? _pick<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  ReasonDetailState copyWith({
    Reason? reason,
    ReasonDraft? draft,
    List<AreaOfLife>? areas,
    List<Voice>? voices,
    List<SoundType>? soundTypes,
    LoadStatus? soundTypesStatus,
    bool? saving,
    bool? deleting,
    bool? deleted,
    int? saveFailures,
    int? renameFailures,
    int? deleteFailures,
  }) => ReasonDetailState(
    reason: reason ?? this.reason,
    draft: draft ?? this.draft,
    areas: areas ?? this.areas,
    voices: voices ?? this.voices,
    soundTypes: soundTypes ?? this.soundTypes,
    soundTypesStatus: soundTypesStatus ?? this.soundTypesStatus,
    saving: saving ?? this.saving,
    deleting: deleting ?? this.deleting,
    deleted: deleted ?? this.deleted,
    saveFailures: saveFailures ?? this.saveFailures,
    renameFailures: renameFailures ?? this.renameFailures,
    deleteFailures: deleteFailures ?? this.deleteFailures,
  );

  @override
  List<Object?> get props => [
    reason,
    draft,
    areas,
    voices,
    soundTypes,
    soundTypesStatus,
    saving,
    deleting,
    deleted,
    saveFailures,
    renameFailures,
    deleteFailures,
  ];
}
