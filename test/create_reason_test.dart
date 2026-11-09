import 'dart:async';

import 'package:eala/core/constants/app_constant.dart';
import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/core/widgets/animated_select_list.dart';
import 'package:eala/core/widgets/add_card.dart';
import 'package:eala/core/widgets/shimmer.dart';
import 'package:eala/core/widgets/sliding_border.dart';
import 'package:eala/core/widgets/dictation_bar.dart';
import 'package:eala/core/widgets/pill_button.dart';
import 'package:eala/core/widgets/play_button.dart';
import 'package:eala/features/create_reason/presentation/widgets/voice_row.dart';
import 'package:eala/features/voice/domain/entities/voice_group.dart';
import 'package:eala/core/widgets/select_list_skeleton.dart';
import 'package:eala/features/area_of_life/domain/entities/area_of_life.dart';
import 'package:eala/features/area_of_life/domain/entities/purpose_suggestion.dart';
import 'package:eala/features/area_of_life/domain/entities/matter_suggestion.dart';
import 'package:eala/features/area_of_life/domain/usecases/get_matter_suggestions_usecase.dart';
import 'package:eala/features/area_of_life/domain/usecases/get_purpose_suggestions_usecase.dart';
import 'package:eala/features/area_of_life/domain/usecases/refresh_areas_of_life_usecase.dart';
import 'package:eala/features/sound/domain/entities/sound_quote.dart';
import 'package:eala/features/sound/domain/entities/sound_type.dart';
import 'package:eala/features/sound/domain/usecases/get_sound_quote_usecase.dart';
import 'package:eala/features/sound/domain/usecases/get_sound_types_usecase.dart';
import 'package:eala/features/voice/domain/entities/voice.dart';
import 'package:eala/features/voice/domain/usecases/refresh_voices_usecase.dart';
import 'package:eala/features/voice/domain/usecases/watch_voices_usecase.dart';
import 'package:eala/features/area_of_life/domain/usecases/watch_areas_of_life_usecase.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_bloc.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_event.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_state.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:eala/features/reasons/domain/usecases/create_reason_usecase.dart';
import 'package:eala/features/create_reason/presentation/pages/create_reason_page.dart';
import 'package:eala/features/create_reason/presentation/pages/reason_ready_page.dart';
import 'package:eala/features/create_alarm/presentation/pages/create_alarm_page.dart';
import 'package:eala/features/create_reason/presentation/widgets/reason_name_field.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/entities/reason_draft.dart';
import 'package:eala/features/reasons/presentation/widgets/reason_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

const health = AreaOfLife(
  id: 1,
  name: 'health',
  title: 'Health',
  description: 'Body and mind',
  color: 0xFF30D158,
);
const work = AreaOfLife(
  id: 2,
  name: 'work',
  title: 'Work',
  description: 'Get things done',
);

CreateReasonBloc buildBloc(
  FakeAreaOfLifeRepository repo, [
  FakeVoiceRepository? voices,
  FakeSoundRepository? sound,
  FakeReasonRepository? reasons,
]) {
  final voiceRepo = voices ?? FakeVoiceRepository();
  final soundRepo = sound ?? FakeSoundRepository();
  return CreateReasonBloc(
    WatchAreasOfLifeUseCase(repo),
    RefreshAreasOfLifeUseCase(repo),
    WatchVoicesUseCase(voiceRepo),
    RefreshVoicesUseCase(voiceRepo),
    GetPurposeSuggestionsUseCase(repo),
    GetMatterSuggestionsUseCase(repo),
    GetSoundTypesUseCase(soundRepo),
    GetSoundQuoteUseCase(soundRepo),
    CreateReasonUseCase(reasons ?? FakeReasonRepository()),
  );
}

const calm = Voice(
  id: 1,
  name: 'Calm',
  voiceId: 'v_calm',
  audio: 'voices/calm.mp3',
  avatar: '/voices/calm.png',
  isPremium: true,
);
const bold = Voice(id: 2, name: 'Bold', voiceId: 'v_bold');

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CreateReasonBloc', () {
    test(
      'first time: loading until the server answers, then the areas',
      () async {
        final answer = Completer<void>();
        final repo = FakeAreaOfLifeRepository(
          server: [health, work],
          serverAnswer: answer.future,
        );
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        expect(bloc.state.areas, isEmpty);
        expect(bloc.state.areasStatus, LoadStatus.loading);

        answer.complete();
        await settle();
        await settle();
        expect(bloc.state.areas, [health, work]);
        expect(bloc.state.areasStatus, LoadStatus.loaded);
        await bloc.close();
      },
    );

    test(
      'saved areas show at once; the update brings changes in later',
      () async {
        final answer = Completer<void>();
        final repo = FakeAreaOfLifeRepository(
          saved: [health],
          server: [health, work],
          serverAnswer: answer.future,
        );
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        expect(bloc.state.areas, [health]);

        answer.complete();
        await settle();
        await settle();
        expect(bloc.state.areas, [health, work]);
        await bloc.close();
      },
    );

    test(
      'offline with nothing saved: failed, and Try again recovers',
      () async {
        final repo = FakeAreaOfLifeRepository(server: [health], offline: true);
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        await settle();
        expect(bloc.state.areasStatus, LoadStatus.failed);

        repo.offline = false;
        bloc.add(const RefreshAreasEvent());
        await settle();
        await settle();
        expect(bloc.state.areas, [health]);
        expect(bloc.state.areasStatus, LoadStatus.loaded);
        await bloc.close();
      },
    );

    test('offline with saved areas: they stay and nothing breaks', () async {
      final repo = FakeAreaOfLifeRepository(saved: [health], offline: true);
      final bloc = buildBloc(repo)..add(const LoadAreasEvent());
      await settle();
      await settle();
      expect(bloc.state.areas, [health]);
      await bloc.close();
    });

    test(
      'choosing an area enables Continue; progress is 1 of the steps',
      () async {
        final bloc = buildBloc(
          FakeAreaOfLifeRepository(
            saved: [health, work],
            server: [health, work],
          ),
        )..add(const LoadAreasEvent());
        await settle();
        expect(bloc.state.canContinue, isFalse);
        expect(bloc.state.progress, closeTo(0.2, 1e-9));

        bloc.add(const AreaSelectedEvent(2));
        await settle();
        expect(bloc.state.selectedArea, work);
        expect(bloc.state.canContinue, isTrue);

        // On to step 2 (the purpose); nothing to continue to from there yet.
        bloc.add(const NextStepEvent());
        await settle();
        expect(bloc.state.stepIndex, 1);
        expect(bloc.state.progress, closeTo(0.4, 1e-9));
        expect(bloc.state.canContinue, isFalse);
        await bloc.close();
      },
    );

    test('a chosen area the server removed is no longer chosen', () async {
      final answer = Completer<void>();
      final repo = FakeAreaOfLifeRepository(
        saved: [health, work],
        server: [health],
        serverAnswer: answer.future,
      );
      final bloc = buildBloc(repo)..add(const LoadAreasEvent());
      await settle();
      bloc.add(const AreaSelectedEvent(2));
      await settle();
      expect(bloc.state.selectedAreaId, 2);

      answer.complete();
      await settle();
      await settle();
      expect(bloc.state.areas, [health]);
      expect(bloc.state.selectedAreaId, isNull);
      await bloc.close();
    });

    test('an area that is not in the list can not be chosen', () async {
      final bloc = buildBloc(
        FakeAreaOfLifeRepository(saved: [health], server: [health]),
      )..add(const LoadAreasEvent());
      await settle();
      bloc.add(const AreaSelectedEvent(99));
      await settle();
      expect(bloc.state.selectedAreaId, isNull);
      await bloc.close();
    });

    test(
      'voices load when asked: saved first, then the server update',
      () async {
        final voices = FakeVoiceRepository(saved: [calm], server: [calm, bold]);
        final bloc = buildBloc(FakeAreaOfLifeRepository(), voices)
          ..add(const LoadVoicesEvent());
        await settle();
        expect(bloc.state.voices, isNotEmpty);
        await settle();
        await settle();
        expect(bloc.state.voices, [calm, bold]);
        expect(bloc.state.voicesStatus, LoadStatus.loaded);
        await bloc.close();
      },
    );

    test(
      'voices: offline with nothing saved is a failure; saved ones stay',
      () async {
        final empty = buildBloc(
          FakeAreaOfLifeRepository(),
          FakeVoiceRepository(offline: true),
        )..add(const LoadVoicesEvent());
        await settle();
        await settle();
        expect(empty.state.voicesStatus, LoadStatus.failed);
        await empty.close();

        final kept = buildBloc(
          FakeAreaOfLifeRepository(),
          FakeVoiceRepository(saved: [calm], offline: true),
        )..add(const LoadVoicesEvent());
        await settle();
        await settle();
        expect(kept.state.voices, [calm]);
        await kept.close();
      },
    );

    test('voice files get the base URL from their paths', () {
      expect(calm.audioUrl, '${AppConstant.baseUrl}voices/calm.mp3');
      expect(calm.avatarUrl, '${AppConstant.baseUrl}voices/calm.png');
      expect(bold.audioUrl, isNull);
      expect(bold.avatarUrl, isNull);
    });

    test(
      'Continue loads the areaSuggestions of the chosen area, from the server',
      () async {
        const q1 = PurposeSuggestion(id: 1, areaId: 1, text: 'Rise.');
        const q2 = PurposeSuggestion(id: 2, areaId: 2, text: 'Work.');
        final repo = FakeAreaOfLifeRepository(
          saved: [health, work],
          server: [health, work],
          areaSuggestions: {
            1: [q1],
            2: [q2],
          },
        );
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        await settle();

        // Nothing is asked for before the user continues.
        expect(repo.suggestionRequests, isEmpty);

        bloc.add(const AreaSelectedEvent(2));
        await settle();
        bloc.add(const NextStepEvent());
        await settle();
        await settle();
        expect(repo.suggestionRequests, [2]);
        expect(bloc.state.suggestionsAreaId, 2);
        expect(bloc.state.areaSuggestions, [q2]);
        expect(bloc.state.suggestionsStatus, LoadStatus.loaded);

        // Back, another area, another request: suggestions are never reused.
        bloc
          ..add(const PreviousStepEvent())
          ..add(const AreaSelectedEvent(1));
        await settle();
        bloc.add(const NextStepEvent());
        await settle();
        await settle();
        expect(repo.suggestionRequests, [2, 1]);
        expect(bloc.state.areaSuggestions, [q1]);
        await bloc.close();
      },
    );

    test('an old area\'s late areaSuggestions are dropped', () async {
      const q1 = PurposeSuggestion(id: 1, areaId: 1, text: 'Rise.');
      const q2 = PurposeSuggestion(id: 2, areaId: 2, text: 'Work.');
      final slow = Completer<void>();
      final repo = FakeAreaOfLifeRepository(
        saved: [health, work],
        server: [health, work],
        areaSuggestions: {
          1: [q1],
          2: [q2],
        },
        suggestionsAnswer: slow.future,
      );
      final bloc = buildBloc(repo)..add(const LoadAreasEvent());
      await settle();
      await settle();
      bloc
        ..add(const AreaSelectedEvent(1))
        ..add(const NextStepEvent());
      await settle();
      // The user goes back for another area before the first answer arrives.
      bloc
        ..add(const PreviousStepEvent())
        ..add(const AreaSelectedEvent(2))
        ..add(const NextStepEvent());
      await settle();
      expect(bloc.state.suggestionsAreaId, 2);
      expect(bloc.state.suggestionsStatus, LoadStatus.loading);
      expect(bloc.state.areaSuggestions, isEmpty);

      slow.complete();
      await settle();
      await settle();
      expect(bloc.state.suggestionsAreaId, 2);
      expect(bloc.state.areaSuggestions, [q2]);
      await bloc.close();
    });

    test('areaSuggestions: offline is a failure (nothing is cached)', () async {
      final repo = FakeAreaOfLifeRepository(
        saved: [health],
        server: [health],
        suggestionsOffline: true,
      );
      final bloc = buildBloc(repo)..add(const LoadAreasEvent());
      await settle();
      await settle();
      bloc
        ..add(const AreaSelectedEvent(1))
        ..add(const NextStepEvent());
      await settle();
      await settle();
      expect(bloc.state.suggestionsStatus, LoadStatus.failed);
      expect(bloc.state.areaSuggestions, isEmpty);
      await bloc.close();
    });

    test('Continue without a chosen area asks for nothing', () async {
      final repo = FakeAreaOfLifeRepository(saved: [health], server: [health]);
      final bloc = buildBloc(repo)
        ..add(const LoadAreasEvent())
        ..add(const NextStepEvent());
      await settle();
      expect(repo.suggestionRequests, isEmpty);
      await bloc.close();
    });

    group('purpose (step 2)', () {
      const q1 = PurposeSuggestion(
        id: 11,
        areaId: 1,
        text: 'I want energy for my kids',
      );
      const q2 = PurposeSuggestion(
        id: 12,
        areaId: 1,
        text: 'Sleep well, feel strong',
      );
      const other = PurposeSuggestion(
        id: 21,
        areaId: 2,
        text: 'Ship the project',
      );

      Future<CreateReasonBloc> atPurposeStep({
        Map<int, List<PurposeSuggestion>> areaSuggestions = const {
          1: [q1, q2],
          2: [other],
        },
      }) async {
        final bloc = buildBloc(
          FakeAreaOfLifeRepository(
            saved: [health, work],
            server: [health, work],
            areaSuggestions: areaSuggestions,
          ),
        )..add(const LoadAreasEvent());
        await settle();
        await settle();
        bloc
          ..add(const AreaSelectedEvent(1))
          ..add(const NextStepEvent());
        await settle();
        await settle();
        expect(bloc.state.stepIndex, 1);
        return bloc;
      }

      test(
        'suggestions are the selected area\'s areaSuggestions only',
        () async {
          final bloc = await atPurposeStep();
          expect(bloc.state.suggestions, [q1, q2]);
          await bloc.close();
        },
      );

      test(
        'picking a suggestion fills the purpose and sets the flag',
        () async {
          final bloc = await atPurposeStep();
          bloc.add(const SuggestionPickedEvent(11));
          await settle();
          expect(bloc.state.purpose, q1.text);
          expect(bloc.state.purposeFromSuggestion, isTrue);
          expect(bloc.state.purposeSuggestion, q1);
          expect(bloc.state.canContinue, isTrue);

          // The field echoing the same text back keeps it a suggestion.
          bloc.add(PurposeChangedEvent(q1.text));
          await settle();
          expect(bloc.state.purposeFromSuggestion, isTrue);
          await bloc.close();
        },
      );

      test(
        'typing until it reads like a suggestion makes it that suggestion',
        () async {
          final bloc = await atPurposeStep();
          bloc.add(const PurposeChangedEvent('Sleep well'));
          await settle();
          expect(bloc.state.purposeFromSuggestion, isFalse);

          // Same words as q2, other spaces and letter case: still that suggestion.
          bloc.add(const PurposeChangedEvent('  sleep WELL,   feel strong '));
          await settle();
          expect(bloc.state.purposeSuggestion, q2);
          await bloc.close();
        },
      );

      test(
        'edited away from a pick and back again: the suggestion again',
        () async {
          final bloc = await atPurposeStep();
          bloc.add(const SuggestionPickedEvent(11));
          await settle();
          bloc.add(PurposeChangedEvent('${q1.text}!'));
          await settle();
          expect(bloc.state.purposeFromSuggestion, isFalse);

          bloc.add(PurposeChangedEvent(q1.text));
          await settle();
          expect(bloc.state.purposeSuggestion, q1);
          await bloc.close();
        },
      );

      test('editing a picked suggestion makes it the user\'s own', () async {
        final bloc = await atPurposeStep();
        bloc.add(const SuggestionPickedEvent(11));
        await settle();
        bloc.add(PurposeChangedEvent('${q1.text} every day'));
        await settle();
        expect(bloc.state.purposeFromSuggestion, isFalse);
        expect(bloc.state.purposeSuggestion, isNull);
        expect(bloc.state.purpose, '${q1.text} every day');
        await bloc.close();
      });

      test(
        'typed text is the user\'s own; too short cannot continue',
        () async {
          final bloc = await atPurposeStep();
          bloc.add(const PurposeChangedEvent('Run'));
          await settle();
          expect(bloc.state.purposeFromSuggestion, isFalse);
          expect(bloc.state.canContinue, isFalse);

          bloc.add(const PurposeChangedEvent('Run a marathon in spring'));
          await settle();
          expect(bloc.state.canContinue, isTrue);
          await bloc.close();
        },
      );

      test('a quote that is not suggested cannot be picked', () async {
        final bloc = await atPurposeStep();
        bloc.add(const SuggestionPickedEvent(21)); // belongs to another area
        await settle();
        expect(bloc.state.purpose, isEmpty);
        expect(bloc.state.purposeFromSuggestion, isFalse);
        await bloc.close();
      });

      test('while the mic listens, Continue waits', () async {
        final bloc = await atPurposeStep();
        bloc
          ..add(const PurposeChangedEvent('Run a marathon in spring'))
          ..add(const DictationChangedEvent(true));
        await settle();
        expect(bloc.state.canContinue, isFalse);
        bloc.add(const DictationChangedEvent(false));
        await settle();
        expect(bloc.state.canContinue, isTrue);
        await bloc.close();
      });

      test(
        'another area drops a picked suggestion but keeps own text',
        () async {
          final bloc = await atPurposeStep();
          bloc.add(const SuggestionPickedEvent(11));
          await settle();
          bloc.add(const AreaSelectedEvent(2));
          await settle();
          expect(bloc.state.purpose, isEmpty);
          expect(bloc.state.purposeSuggestion, isNull);

          bloc
            ..add(const AreaSelectedEvent(1))
            ..add(const PurposeChangedEvent('My own words here'));
          await settle();
          bloc.add(const AreaSelectedEvent(2));
          await settle();
          expect(bloc.state.purpose, 'My own words here');
          await bloc.close();
        },
      );
    });

    test('choosing a voice; Continue on the voice step needs one', () async {
      final bloc = buildBloc(
        FakeAreaOfLifeRepository(),
        FakeVoiceRepository(saved: [calm, bold], server: [calm, bold]),
      )..add(const LoadVoicesEvent());
      await settle();
      await settle();
      expect(bloc.state.selectedVoice, isNull);

      bloc.add(const VoiceSelectedEvent(99)); // not a voice
      await settle();
      expect(bloc.state.selectedVoiceId, isNull);

      bloc.add(const VoiceSelectedEvent(2));
      await settle();
      expect(bloc.state.selectedVoice, bold);
      expect(
        bloc.state.copyWith(stepIndex: 2).canContinue,
        isTrue,
        reason: 'step 3 is complete once a voice is chosen',
      );
      expect(
        bloc.state
            .copyWith(stepIndex: 2, selectedVoiceId: () => null)
            .canContinue,
        isFalse,
      );
      await bloc.close();
    });

    test('a chosen voice the server removed is no longer chosen', () async {
      final voices = FakeVoiceRepository(saved: [calm, bold], server: [calm]);
      final bloc = buildBloc(FakeAreaOfLifeRepository(), voices)
        ..add(const LoadVoicesEvent());
      await settle();
      bloc.add(const VoiceSelectedEvent(2));
      await settle();
      await settle();
      await settle();
      expect(bloc.state.voices, [calm]);
      expect(bloc.state.selectedVoiceId, isNull);
      await bloc.close();
    });

    group('why it matters (step 4)', () {
      const p1 = PurposeSuggestion(id: 11, areaId: 1, text: 'Sleep well again');
      const forP1 = MatterSuggestion(
        id: 1,
        areaId: 1,
        purposeSuggestionId: 11,
        text: 'I am tired of running on empty',
      );
      const general = MatterSuggestion(
        id: 2,
        areaId: 1,
        text: 'It is about feeling like me',
      );

      Future<(CreateReasonBloc, FakeAreaOfLifeRepository)> atPurpose() async {
        final repo = FakeAreaOfLifeRepository(
          saved: [health],
          server: [health],
          areaSuggestions: {
            1: [p1],
          },
          matterSuggestions: [forP1, general],
        );
        final bloc = buildBloc(repo)..add(const LoadAreasEvent());
        await settle();
        await settle();
        bloc
          ..add(const AreaSelectedEvent(1))
          ..add(const NextStepEvent());
        await settle();
        await settle();
        return (bloc, repo);
      }

      test(
        'an unchanged picked purpose loads the suggestions made for it',
        () async {
          final (bloc, repo) = await atPurpose();
          bloc.add(const SuggestionPickedEvent(11));
          await settle();
          bloc.add(const NextStepEvent());
          await settle();
          await settle();
          expect(repo.matterRequests, [(1, 11)]);
          expect(bloc.state.matterSuggestionsShown, [forP1]);
          expect(bloc.state.matterSuggestionsStatus, LoadStatus.loaded);
          await bloc.close();
        },
      );

      test('a typed purpose that matches a suggestion passes its id', () async {
        final (bloc, repo) = await atPurpose();
        bloc.add(const PurposeChangedEvent('sleep well again'));
        await settle();
        bloc.add(const NextStepEvent());
        await settle();
        await settle();
        expect(repo.matterRequests, [(1, 11)]);
        expect(bloc.state.matterSuggestionsShown, [forP1]);
        await bloc.close();
      });

      test(
        'an own (or edited) purpose loads the area\'s general ones',
        () async {
          final (bloc, repo) = await atPurpose();
          bloc
            ..add(const SuggestionPickedEvent(11))
            ..add(const PurposeChangedEvent('Sleep well again, truly'));
          await settle();
          bloc.add(const NextStepEvent());
          await settle();
          await settle();
          expect(repo.matterRequests, [(1, null)]);
          expect(bloc.state.matterSuggestionsShown, [general]);
          await bloc.close();
        },
      );

      test(
        'nothing is asked for before Continue on the purpose step',
        () async {
          final (bloc, repo) = await atPurpose();
          expect(repo.matterRequests, isEmpty);
          await bloc.close();
        },
      );

      test('empty skips, 1-7 characters wait, 8+ continue', () async {
        final (bloc, _) = await atPurpose();
        var state = bloc.state.copyWith(stepIndex: 3);
        expect(state.continueSkips, isTrue);
        expect(state.canContinue, isTrue);

        state = state.copyWith(matter: 'Because');
        expect(state.matterTooShort, isTrue);
        expect(state.canContinue, isFalse);
        expect(state.continueSkips, isFalse);

        state = state.copyWith(matter: 'Because I care');
        expect(state.matterTooShort, isFalse);
        expect(state.canContinue, isTrue);

        state = state.copyWith(dictating: true);
        expect(state.canContinue, isFalse);
        await bloc.close();
      });

      test('suggestions loaded for another purpose are not shown', () async {
        final (bloc, _) = await atPurpose();
        bloc.add(const SuggestionPickedEvent(11));
        await settle();
        bloc.add(const NextStepEvent());
        await settle();
        await settle();
        expect(bloc.state.matterSuggestionsShown, [forP1]);
        // Back on the purpose step the user edits: the loaded ones no longer apply.
        bloc
          ..add(const PreviousStepEvent())
          ..add(const PurposeChangedEvent('Something else entirely'));
        await settle();
        expect(bloc.state.matterSuggestionsShown, isEmpty);
        await bloc.close();
      });
    });

    group('sound (step 5)', () {
      const encouraging = SoundType(
        id: 1,
        title: 'Encouraging',
        description: 'Warm.',
      );
      const calmSound = SoundType(id: 2, title: 'Calm', description: 'Steady.');
      const q1 = SoundQuote(id: 1, areaId: 1, soundId: 1, text: 'You can.');
      const q2 = SoundQuote(id: 2, areaId: 1, soundId: 2, text: 'Breathe.');

      Future<(CreateReasonBloc, FakeSoundRepository)> atSoundStep({
        Future<void>? quoteAnswer,
      }) async {
        final sound = FakeSoundRepository(
          sounds: [encouraging, calmSound],
          quotes: [q1, q2],
          quoteAnswer: quoteAnswer,
        );
        final bloc =
            buildBloc(
                FakeAreaOfLifeRepository(saved: [health], server: [health]),
                FakeVoiceRepository(saved: [bold], server: [bold]),
                sound,
              )
              ..add(const LoadAreasEvent())
              ..add(const LoadVoicesEvent())
              ..add(const LoadSoundTypesEvent());
        await settle();
        await settle();
        bloc
          ..add(const AreaSelectedEvent(1))
          ..add(const NextStepEvent())
          ..add(const PurposeChangedEvent('Run a marathon in spring'))
          ..add(const NextStepEvent())
          ..add(const VoiceSelectedEvent(2))
          ..add(const NextStepEvent())
          ..add(const NextStepEvent());
        for (var i = 0; i < 6; i++) {
          await settle();
        }
        expect(bloc.state.stepIndex, 4);
        return (bloc, sound);
      }

      test(
        'the first sound is chosen; its example loads for the area',
        () async {
          final (bloc, sound) = await atSoundStep();
          expect(bloc.state.selectedSound, encouraging);
          expect(sound.quoteRequests, [(1, 1)]);
          expect(bloc.state.soundQuoteShown, q1);
          expect(bloc.state.isLastStep, isTrue);
          expect(bloc.state.canContinue, isTrue);
          expect(bloc.state.lengthSeconds, 30);
          await bloc.close();
        },
      );

      test('another sound loads its example again, from the server', () async {
        final (bloc, sound) = await atSoundStep();
        bloc.add(const SoundSelectedEvent(2));
        await settle();
        expect(bloc.state.soundQuoteStatus, LoadStatus.loading);
        expect(bloc.state.soundQuoteShown, isNull);
        await settle();
        await settle();
        expect(bloc.state.soundQuoteShown, q2);

        bloc.add(const SoundSelectedEvent(1));
        await settle();
        await settle();
        expect(sound.quoteRequests, [(1, 1), (1, 2), (1, 1)]);
        await bloc.close();
      });

      test('a late example for an old sound is dropped', () async {
        final gate = Completer<void>();
        final (bloc, _) = await atSoundStep(quoteAnswer: gate.future);
        bloc.add(const SoundSelectedEvent(2));
        await settle();
        gate.complete();
        await settle();
        await settle();
        expect(bloc.state.selectedSound, calmSound);
        expect(bloc.state.soundQuoteShown, q2);
        await bloc.close();
      });

      test('length is 30 or 45 seconds only', () async {
        final (bloc, _) = await atSoundStep();
        bloc.add(const LengthSelectedEvent(45));
        await settle();
        expect(bloc.state.lengthSeconds, 45);
        bloc.add(const LengthSelectedEvent(60));
        await settle();
        expect(bloc.state.lengthSeconds, 45);
        await bloc.close();
      });
    });

    test('Previous on the first step does nothing', () async {
      final bloc = buildBloc(FakeAreaOfLifeRepository())
        ..add(const PreviousStepEvent());
      await settle();
      expect(bloc.state.stepIndex, 0);
      await bloc.close();
    });
  });

  group('Create Reason page', () {
    // The router is one app-wide object: start every test from the Dashboard.
    setUp(() => appRouter.go(RouteNames.dashboardPath));

    Future<void> openPage(
      WidgetTester tester,
      FakeAreaOfLifeRepository repo,
    ) async {
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        areaOfLifeRepository: repo,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reasons').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add your first Reason'));
      // The page slides in; the rows then rise in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('opens from the Reasons tab: skeleton first, then the rows', (
      tester,
    ) async {
      final answer = Completer<void>();
      final repo = FakeAreaOfLifeRepository(
        server: [health, work],
        serverAnswer: answer.future,
      );
      await openPage(tester, repo);
      // The shimmer never stops, so settle by pumping a fixed time.
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('wake up for'), findsOneWidget);
      expect(find.byType(SelectListSkeleton), findsOneWidget);
      expect(find.text('Health'), findsNothing);

      answer.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(SelectListSkeleton), findsNothing);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Body and mind'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets(
      'choosing rows moves the one shared border; Continue wakes up',
      (tester) async {
        await openPage(
          tester,
          FakeAreaOfLifeRepository(
            saved: [health, work],
            server: [health, work],
          ),
        );
        await tester.pumpAndSettle();

        final list = tester.state<SlidingBorderScopeState>(
          find.byType(SlidingBorderScope),
        );
        expect(list.indicatorRect, isNull);

        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();
        final first = list.indicatorRect!;
        expect(
          first.top,
          closeTo(
            tester.getTopLeft(find.byType(SelectRow).first).dy -
                tester.getTopLeft(find.byType(AnimatedSelectList)).dy,
            0.5,
          ),
        );

        await tester.tap(find.text('Work'));
        await tester.pumpAndSettle();
        final second = list.indicatorRect!;
        expect(second.top, greaterThan(first.top));
        expect(second.height, closeTo(first.height, 0.01));
        expect(second.width, closeTo(first.width, 0.01));
      },
    );

    testWidgets('back on the first step closes the page', (tester) async {
      await openPage(
        tester,
        FakeAreaOfLifeRepository(saved: [health], server: [health]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('wake up for'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('My Reasons'), findsOneWidget);
    });

    testWidgets('offline with nothing saved shows the message and Try again', (
      tester,
    ) async {
      final repo = FakeAreaOfLifeRepository(server: [health], offline: true);
      await openPage(tester, repo);
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t load'), findsOneWidget);

      repo.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Health'), findsOneWidget);
      expect(find.textContaining('Couldn’t load'), findsNothing);
    });

    group('purpose step', () {
      final areaSuggestions = [
        for (var i = 1; i <= 5; i++)
          PurposeSuggestion(
            id: i,
            areaId: 1,
            text: 'Idea number $i for health',
          ),
      ];

      Future<void> toPurposeStep(WidgetTester tester) async {
        await openPage(
          tester,
          FakeAreaOfLifeRepository(
            saved: [health, work],
            server: [health, work],
            areaSuggestions: {1: areaSuggestions},
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      testWidgets('shows the area, the heading and 3 ideas; More adds 3', (
        tester,
      ) async {
        await toPurposeStep(tester);
        expect(find.text('HEALTH'), findsOneWidget);
        expect(find.textContaining('What are you'), findsOneWidget);
        expect(find.text('OR START FROM ONE OF THESE'), findsOneWidget);
        expect(find.text('Idea number 1 for health'), findsOneWidget);
        expect(find.text('Idea number 3 for health'), findsOneWidget);
        expect(find.text('Idea number 4 for health'), findsNothing);

        await tester.tap(find.text('More ideas'));
        await tester.pumpAndSettle();
        expect(find.text('Idea number 5 for health'), findsOneWidget);
        expect(find.text('More ideas'), findsNothing);
      });

      testWidgets('tapping the field focuses it (nothing steals the tap)', (
        tester,
      ) async {
        await toPurposeStep(tester);
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.focusNode.hasFocus, isTrue);
      });

      testWidgets('a picked idea fills the field, then the ideas go', (
        tester,
      ) async {
        await toPurposeStep(tester);
        await tester.tap(find.text('Idea number 2 for health'));
        await tester.pumpAndSettle();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, 'Idea number 2 for health');
        expect(find.text('OR START FROM ONE OF THESE'), findsNothing);

        // Clearing the field brings the ideas back.
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        expect(find.text('OR START FROM ONE OF THESE'), findsOneWidget);
      });

      testWidgets('speaking adds the words to the field', (tester) async {
        await toPurposeStep(tester);
        await tester.enterText(find.byType(TextField), 'I want');
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Say it out loud'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(DictationBar), findsOneWidget);
        expect(find.byType(LiveMeter), findsOneWidget);

        lastFakeDictation!.speak(['to', 'feel'], 'strong');
        await tester.pump(const Duration(milliseconds: 300));
        lastFakeDictation!.commit();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(DictationBar), findsNothing);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, 'I want to feel strong');
      });

      testWidgets('no speech input: a message explains it', (tester) async {
        await toPurposeStep(tester);
        lastFakeDictation!.available = false;
        await tester.tap(find.bySemanticsLabel('Say it out loud'));
        await tester.pump();
        expect(
          find.textContaining('Voice input isn’t available'),
          findsOneWidget,
        );
      });

      testWidgets('back returns to the area step with the area still chosen', (
        tester,
      ) async {
        await toPurposeStep(tester);
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();
        expect(find.textContaining('wake up for'), findsOneWidget);
        final list = tester.state<SlidingBorderScopeState>(
          find.byType(SlidingBorderScope),
        );
        expect(list.indicatorRect, isNotNull);
      });
    });

    group('voice step', () {
      const warm = VoiceGroup(
        id: 1,
        title: 'Warm',
        description: 'Kind, and on your side',
      );
      const calmGroup = VoiceGroup(id: 2, title: 'Calm', description: 'Steady');
      const astra = Voice(
        id: 1,
        name: 'Astra',
        voiceId: 'a',
        audio: 'audio/astra.mp3',
        group: warm,
        groupId: 1,
        gender: 'Female',
        accent: 'American',
        traits: 'Warm · Encouraging',
      );
      const orion = Voice(
        id: 2,
        name: 'Orion',
        voiceId: 'o',
        audio: 'audio/orion.mp3',
        group: calmGroup,
        groupId: 2,
        gender: 'Male',
        accent: 'British',
        traits: 'Calm',
      );

      Finder playOf(String name) => find.descendant(
        of: find.ancestor(of: find.text(name), matching: find.byType(VoiceRow)),
        matching: find.byType(PlayButton),
      );

      Future<void> toVoiceStep(WidgetTester tester) async {
        await registerFakeAlarmDependencies(
          FakeAlarmRepository(),
          areaOfLifeRepository: FakeAreaOfLifeRepository(
            saved: [health],
            server: [health],
          ),
          voiceRepository: FakeVoiceRepository(
            saved: [orion, astra],
            server: [orion, astra],
          ),
        );
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reasons').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add your first Reason'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Sleep well every night',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      testWidgets('voices sit under their group headings, in group order', (
        tester,
      ) async {
        await toVoiceStep(tester);
        expect(find.textContaining('Who should'), findsOneWidget);
        expect(find.text('Warm'), findsOneWidget);
        expect(find.text('Kind, and on your side'), findsOneWidget);
        expect(find.text('Calm'), findsOneWidget);
        expect(find.text('Female · American · Warm'), findsOneWidget);
        expect(find.text('Male · British · Calm'), findsOneWidget);
        // Group 1 (Warm, Astra) comes before group 2 (Calm, Orion).
        expect(
          tester.getTopLeft(find.text('Astra')).dy,
          lessThan(tester.getTopLeft(find.text('Orion')).dy),
        );
        // Continue waits for a voice.
        final pill = tester.widget<PillButton>(find.byType(PillButton));
        expect(pill.enabled, isFalse);
      });

      testWidgets('choosing moves the one border across groups', (
        tester,
      ) async {
        await toVoiceStep(tester);
        final border = tester.state<SlidingBorderScopeState>(
          find.byType(SlidingBorderScope),
        );
        await tester.tap(find.text('Astra'));
        await tester.pumpAndSettle();
        final first = border.indicatorRect!;
        await tester.tap(find.text('Orion'));
        await tester.pumpAndSettle();
        expect(border.indicatorRect!.top, greaterThan(first.top));
        expect(
          tester.widget<PillButton>(find.byType(PillButton)).enabled,
          isTrue,
        );
      });

      testWidgets(
        'play plays the sample (base URL added), shows the animation, '
        'and stops',
        (tester) async {
          await toVoiceStep(tester);
          await tester.tap(playOf('Astra'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final player = lastFakeSamplePlayer!;
          expect(player.played, ['${AppConstant.baseUrl}audio/astra.mp3']);
          expect(find.byType(PlayBars), findsOneWidget);
          expect(
            tester.widget<PlayButton>(playOf('Astra')).label,
            'Stop Astra',
          );
          // Playing a voice also chooses it.
          expect(
            tester.widget<PillButton>(find.byType(PillButton)).enabled,
            isTrue,
          );

          await tester.tap(playOf('Astra'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(player.stops, 1);
          expect(find.byType(PlayBars), findsNothing);

          // Playing another, then letting it finish on its own.
          await tester.tap(playOf('Orion'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(PlayBars), findsOneWidget);
          player.finish();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(PlayBars), findsNothing);
        },
      );

      testWidgets('a sample that cannot play says so', (tester) async {
        await toVoiceStep(tester);
        lastFakeSamplePlayer!.fail = true;
        await tester.tap(playOf('Astra'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(PlayBars), findsNothing);
        expect(find.textContaining('Couldn’t play this voice'), findsOneWidget);
      });

      testWidgets('leaving the step stops and releases the player', (
        tester,
      ) async {
        await toVoiceStep(tester);
        final player = lastFakeSamplePlayer!;
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();
        expect(player.disposed, isTrue);
      });
    });

    group('matter step', () {
      const p1 = PurposeSuggestion(id: 11, areaId: 1, text: 'Sleep well again');
      final matter = [
        for (var i = 1; i <= 4; i++)
          MatterSuggestion(
            id: i,
            areaId: 1,
            purposeSuggestionId: 11,
            text: 'Reason number $i',
          ),
      ];
      const astra = Voice(id: 1, name: 'Astra', voiceId: 'a');

      Future<void> toMatterStep(WidgetTester tester) async {
        await registerFakeAlarmDependencies(
          FakeAlarmRepository(),
          areaOfLifeRepository: FakeAreaOfLifeRepository(
            saved: [health],
            server: [health],
            areaSuggestions: {
              1: [p1],
            },
            matterSuggestions: matter,
          ),
          voiceRepository: FakeVoiceRepository(saved: [astra], server: [astra]),
        );
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reasons').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add your first Reason'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sleep well again'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Astra'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      testWidgets('shows OPTIONAL, the purpose as a quote and 3 suggestions', (
        tester,
      ) async {
        await toMatterStep(tester);
        expect(find.text('OPTIONAL'), findsOneWidget);
        expect(find.textContaining('matter to you'), findsOneWidget);
        expect(find.text('FOR'), findsOneWidget);
        expect(find.text('“Sleep well again”'), findsOneWidget);
        expect(find.text('Reason number 1'), findsOneWidget);
        expect(find.text('Reason number 3'), findsOneWidget);
        expect(find.text('Reason number 4'), findsNothing);
        expect(find.text('More ideas'), findsNothing);
        // Nothing written: the button skips, in the quiet look.
        final pill = tester.widget<PillButton>(find.byType(PillButton));
        expect(pill.label, 'Skip for now');
        expect(pill.quiet, isTrue);
        expect(pill.enabled, isTrue);
      });

      testWidgets(
        'too short shows the note and waits; a pick fills the field',
        (tester) async {
          await toMatterStep(tester);
          await tester.enterText(find.byType(TextField), 'Because');
          await tester.pumpAndSettle();
          expect(find.textContaining('A few more words'), findsOneWidget);
          var pill = tester.widget<PillButton>(find.byType(PillButton));
          expect(pill.enabled, isFalse);
          expect(pill.label, 'Continue');

          await tester.enterText(find.byType(TextField), '');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Reason number 2'));
          await tester.pumpAndSettle();
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(field.controller!.text, 'Reason number 2');
          expect(find.textContaining('A few more words'), findsNothing);
          pill = tester.widget<PillButton>(find.byType(PillButton));
          expect(pill.enabled, isTrue);
          expect(pill.quiet, isFalse);
        },
      );

      testWidgets('the mic works here too', (tester) async {
        await toMatterStep(tester);
        await tester.tap(find.bySemanticsLabel('Say it out loud'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(DictationBar), findsOneWidget);
        lastFakeDictation!.speak(['it', 'keeps', 'me'], 'going');
        lastFakeDictation!.commit();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, 'it keeps me going');
      });
    });

    group('sound step', () {
      const encouraging = SoundType(
        id: 1,
        title: 'Encouraging',
        description: 'Positive, warm and uplifting.',
      );
      const calmSound = SoundType(
        id: 2,
        title: 'Calm',
        description: 'Calm, peaceful and reassuring.',
      );
      const astra = Voice(id: 1, name: 'Astra', voiceId: 'a');

      Future<FakeSoundRepository> toSoundStep(
        WidgetTester tester, {
        Future<void>? quoteAnswer,
        FakeReasonRepository? reasons,
      }) async {
        final sound = FakeSoundRepository(
          sounds: [encouraging, calmSound],
          quotes: [
            const SoundQuote(
              id: 1,
              areaId: 1,
              soundId: 1,
              text: 'You can do this.',
            ),
            const SoundQuote(
              id: 2,
              areaId: 1,
              soundId: 2,
              text: 'Slow down, breathe.',
            ),
          ],
          quoteAnswer: quoteAnswer,
        );
        await registerFakeAlarmDependencies(
          FakeAlarmRepository(),
          areaOfLifeRepository: FakeAreaOfLifeRepository(
            saved: [health],
            server: [health],
          ),
          voiceRepository: FakeVoiceRepository(saved: [astra], server: [astra]),
          soundRepository: sound,
          reasonRepository: reasons,
        );
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reasons').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AddCard));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Sleep well every night',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Astra'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Skip for now'));
        return sound;
      }

      testWidgets('first sound chosen, its example, description and lengths', (
        tester,
      ) async {
        await toSoundStep(tester);
        await tester.pumpAndSettle();
        expect(find.textContaining('sound'), findsWidgets);
        expect(find.text('Example'), findsOneWidget);
        expect(find.text('You'), findsOneWidget); // word by word
        expect(find.text('Positive, warm and uplifting.'), findsOneWidget);
        expect(find.text('LENGTH'), findsOneWidget);
        expect(find.text('30 sec'), findsOneWidget);
        expect(find.text('45 sec'), findsOneWidget);
        final pill = tester.widget<PillButton>(find.byType(PillButton));
        expect(pill.label, 'Create Reason');
        expect(pill.enabled, isTrue);
      });

      testWidgets('changing the sound shows a shimmer, then its own example', (
        tester,
      ) async {
        final sound = await toSoundStep(tester);
        await tester.pumpAndSettle();
        // Hold the next answer so the loading look can be seen.
        final gate = Completer<void>();
        sound.quoteAnswer = gate.future;
        await tester.tap(find.bySemanticsLabel('Calm'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(Shimmer), findsOneWidget);
        expect(find.text('You'), findsNothing);

        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Shimmer), findsNothing);
        expect(find.text('Slow'), findsOneWidget);
        expect(find.text('Calm, peaceful and reassuring.'), findsOneWidget);
        expect(sound.quoteRequests, [(1, 1), (1, 2)]);
      });

      testWidgets('the length border moves to the chosen box', (tester) async {
        await toSoundStep(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('45 sec'));
        await tester.pumpAndSettle();
        expect(find.text('A full thought, not a ramble.'), findsOneWidget);
      });

      group('save and ready', () {
        // Reuses the sound group's walk through the steps.
        Future<FakeReasonRepository> toReady(
          WidgetTester tester, {
          List<Reason> existing = const [],
        }) async {
          final reasons = FakeReasonRepository(
            existing,
            const [health],
            const [encouraging, calmSound],
            const [astra],
          );
          await toSoundStep(tester, reasons: reasons);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Create Reason'));
          await tester.pumpAndSettle();
          return reasons;
        }

        testWidgets('Create Reason saves what was chosen and shows it ready', (
          tester,
        ) async {
          final reasons = await toReady(tester);
          final saved = reasons.created.single;
          expect(saved.baseName, 'health');
          expect(
            saved.draft,
            const ReasonDraft(
              areaId: 1,
              purpose: 'Sleep well every night',
              soundTypeId: 1,
              voiceId: 1,
              lengthSeconds: 30,
            ),
          );

          expect(find.byType(ReasonReadyPage), findsOneWidget);
          expect(find.byType(CreateReasonPage), findsNothing);
          expect(
            find.textContaining('ready', findRichText: true),
            findsWidgets,
          );
          expect(find.text('health'), findsWidgets);
          expect(find.text('Sleep well every night'), findsOneWidget);
          expect(find.text('Astra'), findsOneWidget);
          expect(find.text('Encouraging'), findsOneWidget);
        });

        testWidgets('a name already used gets the next number', (tester) async {
          await toReady(
            tester,
            existing: [
              testReason(id: 1, name: 'health'),
              testReason(id: 2, name: 'health 3'),
            ],
          );
          expect(
            find.descendant(
              of: find.byType(ReasonReadyPage),
              matching: find.text('health 4'),
            ),
            findsWidgets,
          );
        });

        testWidgets('renaming saves the new name for that reason', (
          tester,
        ) async {
          final reasons = await toReady(tester);
          final field = find.descendant(
            of: find.byType(ReasonNameField),
            matching: find.byType(TextField),
          );
          await tester.tap(find.byType(ReasonNameField));
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel('Save name'), findsOneWidget);
          await tester.enterText(field, '  Morning health ');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(reasons.renames, [(100, 'Morning health')]);
          expect(find.text('Morning health'), findsWidgets);
        });

        testWidgets('a rename that fails puts the old name back and says so', (
          tester,
        ) async {
          final reasons = await toReady(tester);
          reasons.offline = true;
          await tester.tap(find.byType(ReasonNameField));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.descendant(
              of: find.byType(ReasonNameField),
              matching: find.byType(TextField),
            ),
            'Other',
          );
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(find.textContaining('Couldn’t rename it'), findsOneWidget);
          expect(find.text('health'), findsWidgets);
          expect(find.text('Other'), findsNothing);
        });

        testWidgets('Save for later returns to the list with the new reason', (
          tester,
        ) async {
          await toReady(tester);
          await tester.tap(find.text('Save for later'));
          await tester.pumpAndSettle();
          expect(find.byType(ReasonReadyPage), findsNothing);
          expect(find.byType(ReasonRow), findsOneWidget);
          expect(find.text('health'), findsOneWidget);
        });

        testWidgets(
          'Use with alarm opens the alarm editor, the reason chosen',
          (tester) async {
            await toReady(tester);
            await tester.tap(find.text('Use with alarm'));
            await tester.pumpAndSettle();
            expect(find.byType(ReasonReadyPage), findsNothing);
            expect(find.byType(CreateAlarmPage), findsOneWidget);
            expect(
              find.descendant(
                of: find.byType(CreateAlarmPage),
                matching: find.text('health'),
              ),
              findsOneWidget,
            );
            expect(find.text('Save Alarm'), findsOneWidget);

            // Back returns to where Create Reason was opened.
            await tester.tap(find.text('Cancel'));
            await tester.pumpAndSettle();
            expect(find.byType(CreateAlarmPage), findsNothing);
            expect(find.byType(ReasonRow), findsOneWidget);
          },
        );

        testWidgets('back does what Save for later does', (tester) async {
          await toReady(tester);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(ReasonReadyPage), findsNothing);
          expect(find.byType(CreateReasonPage), findsNothing);
          expect(find.byType(ReasonRow), findsOneWidget);
        });

        testWidgets('a failed save says so and stays on the sound step', (
          tester,
        ) async {
          final reasons = FakeReasonRepository()..offline = true;
          await toSoundStep(tester, reasons: reasons);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Create Reason'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Couldn’t save your reason'),
            findsOneWidget,
          );
          expect(find.byType(CreateReasonPage), findsOneWidget);
          expect(find.byType(ReasonReadyPage), findsNothing);
        });
      });
    });
  });
}
