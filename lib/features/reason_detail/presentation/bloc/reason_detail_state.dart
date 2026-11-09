import 'package:equatable/equatable.dart';

import '../../../../core/utils/load_status.dart';
import '../../../alarm/domain/entities/alarm.dart';
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

  /// The alarms saved on the device (followed), to find the one that plays it.
  final List<Alarm> alarms;

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
    this.alarms = const [],
    this.saving = false,
    this.deleting = false,
    this.deleted = false,
    this.saveFailures = 0,
    this.renameFailures = 0,
    this.deleteFailures = 0,
  }) : draft = draft ?? reason.draft;

  /// The alarm on this device that plays it (one alarm, one Reason).
  Alarm? get alarm {
    for (final a in alarms) {
      if (a.reasonId == reason.id) return a;
    }
    return null;
  }

  /// An alarm plays it: on this device, or on the server (`reason.alarm_id`). Deleting
  /// it deletes that alarm too.
  bool get hasAlarm => alarm != null || reason.alarmId != null;

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
    List<Alarm>? alarms,
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
    alarms: alarms ?? this.alarms,
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
    alarms,
    saving,
    deleting,
    deleted,
    saveFailures,
    renameFailures,
    deleteFailures,
  ];
}
