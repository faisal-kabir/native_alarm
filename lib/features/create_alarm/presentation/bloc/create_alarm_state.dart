import 'package:equatable/equatable.dart';

import '../../../alarm_audio/domain/entities/alarm_audio.dart';
import '../../../reasons/domain/entities/reason.dart';
import '../../domain/entities/alarm_draft.dart';
import '../../domain/entities/alarm_schedule.dart';

enum CreateAlarmStatus {
  /// Being filled in.
  editing,
  saving,

  /// Saved (and set to ring): the page closes.
  saved,

  /// Every alarm place is taken: the page closes and says so.
  full,
}

class CreateAlarmState extends Equatable {
  /// Everything but the schedule, which is [cards] (see [view]).
  final AlarmDraft draft;

  /// "When it rings": one card is a plain alarm, more are a time per day.
  final List<ScheduleCard> cards;

  /// The next card's id number (ids are local to the page).
  final int nextCardId;

  /// The cached reasons, alarm sounds and sound tracks (never the network).
  final List<Reason> reasons;
  final List<AlarmAudio> soundTracks;
  final List<AlarmAudio> alarmSounds;

  /// Reasons an alarm on this device plays, including one not on the server yet (made
  /// offline, so its Reason has no `alarm_id` yet).
  final Set<int> takenReasonIds;

  /// The system has not granted alarm access: "Enabled" reads off and a card says why.
  final bool accessDenied;

  final CreateAlarmStatus status;

  /// Goes up by one on every failed save, so the page can say so.
  final int saveFailures;

  CreateAlarmState({
    AlarmDraft? draft,
    this.cards = const [],
    this.nextCardId = 0,
    this.reasons = const [],
    this.soundTracks = const [],
    this.alarmSounds = const [],
    this.takenReasonIds = const {},
    this.accessDenied = false,
    this.status = CreateAlarmStatus.editing,
    this.saveFailures = 0,
  }) : draft = draft ?? AlarmDraft();

  /// The whole alarm as the page shows it (the cards folded into the draft).
  AlarmDraft get view => fromCards(draft, cards);

  /// The chosen Reason, once it is in the cached list.
  Reason? get reason {
    for (final r in reasons) {
      if (r.id == draft.reasonId) return r;
    }
    return null;
  }

  /// The Reasons that can be picked: the chosen one first, then every free one. A
  /// Reason belongs to one alarm: with an `alarm_id` ([Reason.alarmId]) it is taken.
  List<Reason> get pickableReasons => [
    ?reason,
    for (final r in reasons)
      if (r.id != draft.reasonId &&
          r.alarmId == null &&
          !takenReasonIds.contains(r.id))
        r,
  ];

  /// Something to pick (else "Add a reason" goes straight to making one).
  bool get hasPickableReason => pickableReasons.isNotEmpty;

  AlarmAudio? get soundTrack => _find(soundTracks, draft.soundTrackId);
  AlarmAudio? get alarmSound => _find(alarmSounds, draft.alarmSoundId);

  static AlarmAudio? _find(List<AlarmAudio> list, int? id) {
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }

  CreateAlarmState copyWith({
    AlarmDraft? draft,
    List<ScheduleCard>? cards,
    int? nextCardId,
    List<Reason>? reasons,
    List<AlarmAudio>? soundTracks,
    List<AlarmAudio>? alarmSounds,
    Set<int>? takenReasonIds,
    bool? accessDenied,
    CreateAlarmStatus? status,
    int? saveFailures,
  }) => CreateAlarmState(
    draft: draft ?? this.draft,
    cards: cards ?? this.cards,
    nextCardId: nextCardId ?? this.nextCardId,
    reasons: reasons ?? this.reasons,
    soundTracks: soundTracks ?? this.soundTracks,
    alarmSounds: alarmSounds ?? this.alarmSounds,
    takenReasonIds: takenReasonIds ?? this.takenReasonIds,
    accessDenied: accessDenied ?? this.accessDenied,
    status: status ?? this.status,
    saveFailures: saveFailures ?? this.saveFailures,
  );

  @override
  List<Object?> get props => [
    draft,
    cards,
    nextCardId,
    reasons,
    soundTracks,
    alarmSounds,
    takenReasonIds,
    accessDenied,
    status,
    saveFailures,
  ];
}
