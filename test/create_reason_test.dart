import 'dart:async';

import 'package:eala/core/constants/app_constant.dart';
import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/core/widgets/add_card.dart';
import 'package:eala/core/widgets/pill_button.dart';
import 'package:eala/core/widgets/play_button.dart';
import 'package:eala/core/widgets/select_list_skeleton.dart';
import 'package:eala/core/widgets/sliding_border.dart';
import 'package:eala/features/create_alarm/presentation/pages/create_alarm_page.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_bloc.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_event.dart';
import 'package:eala/features/create_reason/presentation/bloc/create_reason_state.dart';
import 'package:eala/features/create_reason/presentation/pages/create_reason_page.dart';
import 'package:eala/features/create_reason/presentation/pages/reason_ready_page.dart';
import 'package:eala/features/create_reason/presentation/widgets/reason_name_field.dart';
import 'package:eala/features/create_reason/presentation/widgets/select_sound_step.dart';
import 'package:eala/features/create_reason/presentation/widgets/voice_row.dart';
import 'package:eala/features/goal_topic/domain/entities/goal_topic.dart';
import 'package:eala/features/goal_topic/domain/usecases/refresh_goal_topics_usecase.dart';
import 'package:eala/features/goal_topic/domain/usecases/watch_general_whys_usecase.dart';
import 'package:eala/features/goal_topic/domain/usecases/watch_goal_topics_usecase.dart';
import 'package:eala/features/reasons/domain/entities/reason_draft.dart';
import 'package:eala/features/reasons/domain/usecases/create_reason_usecase.dart';
import 'package:eala/features/reasons/presentation/widgets/reason_row.dart';
import 'package:eala/features/sound/domain/entities/sound_type.dart';
import 'package:eala/features/sound/domain/usecases/get_sound_types_usecase.dart';
import 'package:eala/features/voice/domain/entities/voice.dart';
import 'package:eala/features/voice/domain/entities/voice_group.dart';
import 'package:eala/features/voice/domain/usecases/refresh_voices_usecase.dart';
import 'package:eala/features/voice/domain/usecases/watch_voices_usecase.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

const fit = GoalTopic(
  id: 1,
  label: 'Getting fit',
  keywords: 'gym run workout',
  sortOrder: 1,
  goals: ['Run a 5K by spring', 'Lift three times a week', 'Walk every day'],
  whys: ['I want more energy', 'I want to feel strong', 'For my future self'],
);
const grief = GoalTopic(
  id: 2,
  label: 'Grief',
  gentle: true,
  sortOrder: 2,
  goals: [
    'Be kind to myself today',
    'Let myself rest',
    'Reach out to a friend',
  ],
  whys: ['I am allowed to heal', 'Small steps count', 'I am not alone'],
);
const family = GoalTopic(
  id: 3,
  label: 'My family',
  sortOrder: 3,
  goals: ['Be home for dinner', 'Call my parents', 'Plan a family day'],
  whys: ['They are my world', 'Time passes fast', 'I want to be present'],
);
const topics = [fit, grief, family];
const generalWhys = [
  'Because it matters to me',
  'I owe it to myself',
  'I want a better life',
];

CreateReasonBloc buildBloc(
  FakeGoalTopicRepository repo, [
  FakeVoiceRepository? voices,
  FakeSoundRepository? sound,
  FakeReasonRepository? reasons,
]) {
  final voiceRepo = voices ?? FakeVoiceRepository();
  final soundRepo = sound ?? FakeSoundRepository();
  return CreateReasonBloc(
    WatchGoalTopicsUseCase(repo),
    WatchGeneralWhysUseCase(repo),
    RefreshGoalTopicsUseCase(repo),
    WatchVoicesUseCase(voiceRepo),
    RefreshVoicesUseCase(voiceRepo),
    GetSoundTypesUseCase(soundRepo),
    CreateReasonUseCase(reasons ?? FakeReasonRepository()),
  );
}

FakeGoalTopicRepository savedTopics() => FakeGoalTopicRepository(
  saved: topics,
  server: topics,
  savedWhys: generalWhys,
  serverWhys: generalWhys,
);

const calm = Voice(
  id: 1,
  name: 'Calm',
  voiceId: 'v_calm',
  audio: 'voices/calm.mp3',
  avatar: '/voices/calm.png',
  isPremium: true,
);
const bold = Voice(id: 2, name: 'Bold', voiceId: 'v_bold');

const encouraging = SoundType(
  id: 1,
  title: 'Encouraging',
  description: 'Positive, warm and uplifting.',
  sample: 'You can do this.',
);
const calmSound = SoundType(
  id: 2,
  title: 'Calm',
  description: 'Calm, peaceful and reassuring.',
  sample: 'Slow down, breathe.',
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CreateReasonBloc', () {
    test(
      'first time: loading until the server answers, then the chips',
      () async {
        final answer = Completer<void>();
        final repo = FakeGoalTopicRepository(
          server: topics,
          serverWhys: generalWhys,
          serverAnswer: answer.future,
        );
        final bloc = buildBloc(repo)..add(const LoadTopicsEvent());
        await settle();
        expect(bloc.state.topics, isEmpty);
        expect(bloc.state.topicsStatus, LoadStatus.loading);

        answer.complete();
        await settle();
        await settle();
        expect(bloc.state.topics, topics);
        expect(bloc.state.generalWhys, generalWhys);
        expect(bloc.state.topicsStatus, LoadStatus.loaded);
        await bloc.close();
      },
    );

    test(
      'with chips saved on the device they show at once, offline too',
      () async {
        final repo = FakeGoalTopicRepository(
          saved: topics,
          server: const [],
          offline: true,
        );
        final bloc = buildBloc(repo)..add(const LoadTopicsEvent());
        await settle();
        expect(bloc.state.topics, topics);
        await settle();
        expect(bloc.state.topics, topics, reason: 'a failed update is silent');
        await bloc.close();
      },
    );

    test(
      'offline with nothing saved is a failure, Try again recovers',
      () async {
        final repo = FakeGoalTopicRepository(server: topics, offline: true);
        final bloc = buildBloc(repo)..add(const LoadTopicsEvent());
        await settle();
        await settle();
        expect(bloc.state.topicsStatus, LoadStatus.failed);

        repo.offline = false;
        bloc.add(const RefreshTopicsEvent());
        await settle();
        await settle();
        expect(bloc.state.topics, topics);
        expect(bloc.state.topicsStatus, LoadStatus.loaded);
        await bloc.close();
      },
    );

    group('topic (step 1)', () {
      late CreateReasonBloc bloc;
      setUp(() async {
        bloc = buildBloc(savedTopics())..add(const LoadTopicsEvent());
        await settle();
      });
      tearDown(() => bloc.close());

      test('a chip is the answer; Continue is on', () async {
        expect(bloc.state.canContinue, isFalse);
        bloc.add(const TopicPickedEvent(1));
        await settle();
        expect(bloc.state.chip, fit);
        expect(bloc.state.topic, 'Getting fit');
        expect(bloc.state.topicText, '');
        expect(bloc.state.canContinue, isTrue);
      });

      test('a chip that is not in the list can not be picked', () async {
        bloc.add(const TopicPickedEvent(99));
        await settle();
        expect(bloc.state.chip, isNull);
      });

      test('own words are the answer, two characters are enough', () async {
        bloc.add(const TopicTypedEvent('a'));
        await settle();
        expect(bloc.state.canContinue, isFalse);
        bloc.add(const TopicTypedEvent('My garden'));
        await settle();
        expect(bloc.state.chip, isNull);
        expect(bloc.state.topic, 'My garden');
        expect(bloc.state.canContinue, isTrue);
      });

      test('typing lets go of a chip, a chip clears the typing', () async {
        bloc.add(const TopicPickedEvent(1));
        bloc.add(const TopicTypedEvent('Surfing'));
        await settle();
        expect(bloc.state.selectedTopicId, isNull);
        expect(bloc.state.topic, 'Surfing');

        bloc.add(const TopicPickedEvent(3));
        await settle();
        expect(bloc.state.topicText, '');
        expect(bloc.state.topic, 'My family');
      });

      test('typing a chip\'s exact name is that chip', () async {
        bloc.add(const TopicTypedEvent('getting FIT'));
        await settle();
        expect(bloc.state.chip, fit);
        expect(bloc.state.goalSuggestions, fit.goals);
      });

      test('at most 20 characters, one line', () async {
        bloc.add(const TopicTypedEvent('  Learning to play\nthe violin well'));
        await settle();
        expect(bloc.state.topicText.length, lessThanOrEqualTo(20));
        expect(bloc.state.topicText.contains('\n'), isFalse);
        expect(bloc.state.topicText.startsWith(' '), isFalse);
      });

      test('suggestions: a chip brings its goals and whys', () async {
        bloc.add(const TopicPickedEvent(1));
        await settle();
        expect(bloc.state.goalSuggestions, fit.goals);
        expect(bloc.state.whySuggestions, fit.whys);
      });

      test(
        'suggestions: own words get no goals, only the general whys',
        () async {
          bloc.add(const TopicTypedEvent('My garden'));
          await settle();
          expect(bloc.state.goalSuggestions, isEmpty);
          expect(bloc.state.whySuggestions, generalWhys);
        },
      );

      test('gentle: a chip\'s own mark, or the words typed', () async {
        bloc.add(const TopicPickedEvent(1));
        await settle();
        expect(bloc.state.focus, GoalFocus.general);
        bloc.add(const TopicPickedEvent(2));
        await settle();
        expect(bloc.state.focus, GoalFocus.gentle);
        bloc.add(const TopicTypedEvent('Staying sober'));
        await settle();
        expect(bloc.state.focus, GoalFocus.gentle);
        bloc.add(const TopicTypedEvent('Surfing'));
        await settle();
        expect(bloc.state.focus, GoalFocus.general);
      });

      test('a chip the server removed is no longer chosen', () async {
        final repo = savedTopics();
        final other = buildBloc(repo)..add(const LoadTopicsEvent());
        await settle();
        other.add(const TopicPickedEvent(3));
        await settle();
        expect(other.state.chip, family);

        repo.server = const [fit, grief];
        other.add(const RefreshTopicsEvent());
        await settle();
        await settle();
        expect(other.state.selectedTopicId, isNull);
        expect(other.state.canContinue, isFalse);
        await other.close();
      });

      test('Continue tidies a trailing full stop off own words', () async {
        bloc.add(const TopicTypedEvent('My garden.'));
        bloc.add(const NextStepEvent());
        await settle();
        expect(bloc.state.stepIndex, CreateReasonState.purposeStep);
        expect(bloc.state.topic, 'My garden');
      });

      test('Continue without an answer asks for nothing', () async {
        bloc.add(const NextStepEvent());
        await settle();
        expect(bloc.state.stepIndex, 0);
      });
    });

    group('goal (step 2)', () {
      late CreateReasonBloc bloc;
      setUp(() async {
        bloc = buildBloc(savedTopics())
          ..add(const LoadTopicsEvent())
          ..add(const TopicPickedEvent(1))
          ..add(const NextStepEvent());
        await settle();
      });
      tearDown(() => bloc.close());

      test('needs 12 characters and 2 words; the mic holds Continue', () async {
        expect(bloc.state.stepIndex, CreateReasonState.purposeStep);
        bloc.add(const PurposeChangedEvent('Run'));
        await settle();
        expect(bloc.state.canContinue, isFalse);
        bloc.add(const PurposeChangedEvent('Run a 5K by spring'));
        await settle();
        expect(bloc.state.canContinue, isTrue);
        bloc.add(const DictationChangedEvent(true));
        await settle();
        expect(bloc.state.canContinue, isFalse);
      });

      test(
        'changing the chip takes away a goal picked from the old one',
        () async {
          bloc.add(const PurposeChangedEvent('Run a 5K by spring'));
          bloc.add(const TopicPickedEvent(3));
          await settle();
          expect(bloc.state.purpose, '');
        },
      );

      test('...but not what the person wrote themselves', () async {
        bloc.add(const PurposeChangedEvent('Finish my first marathon'));
        bloc.add(const TopicPickedEvent(3));
        await settle();
        expect(bloc.state.purpose, 'Finish my first marathon');
      });
    });

    group('why (step 3, optional)', () {
      late CreateReasonBloc bloc;
      setUp(() async {
        bloc = buildBloc(savedTopics())
          ..add(const LoadTopicsEvent())
          ..add(const TopicPickedEvent(1))
          ..add(const NextStepEvent())
          ..add(const PurposeChangedEvent('Run a 5K by spring'))
          ..add(const NextStepEvent());
        await settle();
      });
      tearDown(() => bloc.close());

      test('empty reads Skip for now; a little text is held back', () async {
        expect(bloc.state.stepIndex, CreateReasonState.matterStep);
        expect(bloc.state.continueSkips, isTrue);
        expect(bloc.state.canContinue, isTrue);
        bloc.add(const MatterChangedEvent('Because'));
        await settle();
        expect(bloc.state.continueSkips, isFalse);
        expect(bloc.state.matterTooShort, isTrue);
        expect(bloc.state.canContinue, isFalse);
        bloc.add(const MatterChangedEvent('I want more energy'));
        await settle();
        expect(bloc.state.canContinue, isTrue);
      });
    });

    group('voice and sound (steps 4 and 5)', () {
      late CreateReasonBloc bloc;
      late FakeReasonRepository reasons;

      Future<void> toVoiceStep() async {
        bloc
          ..add(const LoadTopicsEvent())
          ..add(const LoadVoicesEvent())
          ..add(const LoadSoundTypesEvent())
          ..add(const TopicPickedEvent(2))
          ..add(const NextStepEvent())
          ..add(const PurposeChangedEvent('Be kind to myself today'))
          ..add(const NextStepEvent())
          ..add(const NextStepEvent());
        await settle();
        await settle();
      }

      setUp(() {
        reasons = FakeReasonRepository();
        bloc = buildBloc(
          savedTopics(),
          FakeVoiceRepository(saved: [calm, bold], server: [calm, bold]),
          FakeSoundRepository(sounds: [encouraging, calmSound]),
          reasons,
        );
      });
      tearDown(() => bloc.close());

      test('voice comes after why; Continue needs a chosen voice', () async {
        await toVoiceStep();
        expect(bloc.state.stepIndex, CreateReasonState.voiceStep);
        expect(bloc.state.canContinue, isFalse);
        bloc.add(const VoiceSelectedEvent(99));
        await settle();
        expect(bloc.state.selectedVoice, isNull);
        bloc.add(const VoiceSelectedEvent(2));
        await settle();
        expect(bloc.state.selectedVoice, bold);
        expect(bloc.state.canContinue, isTrue);
      });

      test('a voice the server removed is no longer chosen', () async {
        await toVoiceStep();
        bloc.add(const VoiceSelectedEvent(2));
        await settle();
        final repo = FakeVoiceRepository(saved: [calm], server: [calm]);
        final other = buildBloc(savedTopics(), repo)
          ..add(const LoadVoicesEvent());
        await settle();
        expect(other.state.selectedVoiceId, isNull);
        await other.close();
      });

      test(
        'the first tone is chosen until another is picked; 30 s by default',
        () async {
          await toVoiceStep();
          expect(bloc.state.selectedSound, encouraging);
          expect(bloc.state.lengthSeconds, 30);
          bloc.add(const SoundSelectedEvent(2));
          bloc.add(const LengthSelectedEvent(45));
          bloc.add(const LengthSelectedEvent(99));
          await settle();
          expect(bloc.state.selectedSound?.sample, 'Slow down, breathe.');
          expect(bloc.state.lengthSeconds, 45);
        },
      );

      test('Create saves the goal named after its topic', () async {
        await toVoiceStep();
        bloc
          ..add(const VoiceSelectedEvent(1))
          ..add(const NextStepEvent())
          ..add(const LengthSelectedEvent(45))
          ..add(const CreateReasonSubmittedEvent());
        await settle();
        await settle();
        expect(bloc.state.saveStatus, SaveStatus.saved);
        final saved = reasons.created.single;
        expect(saved.name, 'Grief');
        expect(
          saved.draft,
          const ReasonDraft(
            topic: 'Grief',
            focus: GoalFocus.gentle,
            purpose: 'Be kind to myself today',
            soundTypeId: 1,
            voiceId: 1,
            lengthSeconds: 45,
          ),
        );
        expect(bloc.state.createdReason?.name, 'Grief');
      });

      test('a failed save says so and can be tried again', () async {
        reasons.offline = true;
        await toVoiceStep();
        bloc
          ..add(const VoiceSelectedEvent(1))
          ..add(const NextStepEvent())
          ..add(const CreateReasonSubmittedEvent());
        await settle();
        await settle();
        expect(bloc.state.saveStatus, SaveStatus.failed);
        reasons.offline = false;
        bloc.add(const CreateReasonSubmittedEvent());
        await settle();
        await settle();
        expect(bloc.state.saveStatus, SaveStatus.saved);
      });
    });

    test('Previous on the first step does nothing', () async {
      final bloc = buildBloc(savedTopics())..add(const PreviousStepEvent());
      await settle();
      expect(bloc.state.stepIndex, 0);
      await bloc.close();
    });
  });

  group('Create Goal page', () {
    // The router is one app-wide object: start every test from the Dashboard.
    setUp(() => appRouter.go(RouteNames.dashboardPath));

    Future<void> openPage(
      WidgetTester tester, {
      FakeGoalTopicRepository? topicRepo,
      FakeVoiceRepository? voiceRepo,
      FakeSoundRepository? soundRepo,
      FakeReasonRepository? reasons,
    }) async {
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        goalTopicRepository: topicRepo ?? savedTopics(),
        voiceRepository: voiceRepo,
        soundRepository: soundRepo,
        reasonRepository: reasons,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Goal').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AddCard));
      // The page slides in; the rows then rise in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> tapContinue(WidgetTester tester) async {
      await tester.tap(find.byType(PillButton));
      await tester.pumpAndSettle();
    }

    bool continueEnabled(WidgetTester tester) =>
        tester.widget<PillButton>(find.byType(PillButton)).enabled;

    testWidgets('opens on the topic step: skeleton first, then the chips', (
      tester,
    ) async {
      final answer = Completer<void>();
      await openPage(
        tester,
        topicRepo: FakeGoalTopicRepository(
          server: topics,
          serverAnswer: answer.future,
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('wake up for'), findsOneWidget);
      expect(find.byType(SelectListSkeleton), findsOneWidget);
      expect(find.text('Getting fit'), findsNothing);

      answer.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SelectListSkeleton), findsNothing);
      expect(find.text('Getting fit'), findsOneWidget);
      expect(find.text('Grief'), findsOneWidget);
      expect(find.text('My family'), findsOneWidget);
      expect(continueEnabled(tester), isFalse);
    });

    testWidgets('offline with nothing saved shows the message and Try again', (
      tester,
    ) async {
      final repo = FakeGoalTopicRepository(server: topics, offline: true);
      await openPage(tester, topicRepo: repo);
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t load'), findsOneWidget);

      repo.offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Getting fit'), findsOneWidget);
    });

    testWidgets('a chip lights up, Continue wakes up, one answer at a time', (
      tester,
    ) async {
      await openPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Getting fit'));
      await tester.pumpAndSettle();
      expect(continueEnabled(tester), isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
        reason: 'a chip does not write into the field',
      );

      await tester.enterText(find.byType(TextField), 'Surf');
      await tester.pumpAndSettle();
      expect(continueEnabled(tester), isTrue);
    });

    testWidgets('typing is a search: matches come first, the rest stay', (
      tester,
    ) async {
      await openPage(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'gym');
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Getting fit')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Grief')).dy),
      );
      expect(find.text('Grief'), findsOneWidget, reason: 'still there to tap');
    });

    testWidgets('back on the first step closes the page', (tester) async {
      await openPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('My Goals'), findsOneWidget);
    });

    group('goal and why steps', () {
      Future<void> toGoalStep(WidgetTester tester, String chip) async {
        await openPage(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text(chip));
        await tester.pumpAndSettle();
        await tapContinue(tester);
      }

      testWidgets(
        'a chip\'s three goals are suggested; picking fills the field',
        (tester) async {
          await toGoalStep(tester, 'Getting fit');
          expect(find.textContaining('working toward'), findsOneWidget);
          for (final goal in fit.goals) {
            expect(find.text(goal), findsOneWidget);
          }
          await tester.tap(find.text('Run a 5K by spring'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Run a 5K by spring',
          );
          expect(find.text('Lift three times a week'), findsNothing);
          expect(continueEnabled(tester), isTrue);
        },
      );

      testWidgets('own words as the topic: no goal suggestions at all', (
        tester,
      ) async {
        await openPage(tester);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'My garden');
        await tester.pumpAndSettle();
        await tapContinue(tester);
        expect(find.textContaining('working toward'), findsOneWidget);
        for (final chip in topics) {
          for (final goal in chip.goals) {
            expect(find.text(goal), findsNothing);
          }
        }
      });

      testWidgets('why: the chip\'s own whys, and Skip for now', (
        tester,
      ) async {
        await toGoalStep(tester, 'Getting fit');
        await tester.enterText(find.byType(TextField), 'Run a 5K by spring');
        await tester.pumpAndSettle();
        await tapContinue(tester);
        expect(find.textContaining('matter to you'), findsOneWidget);
        for (final why in fit.whys) {
          expect(find.text(why), findsOneWidget);
        }
        expect(find.text('Skip for now'), findsOneWidget);
      });

      testWidgets('why for own words: the three general whys', (tester) async {
        await openPage(tester);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'My garden');
        await tester.pumpAndSettle();
        await tapContinue(tester);
        await tester.enterText(find.byType(TextField), 'Grow my own food');
        await tester.pumpAndSettle();
        await tapContinue(tester);
        for (final why in generalWhys) {
          expect(find.text(why), findsOneWidget);
        }
      });

      testWidgets('back returns to the topic with the answer still there', (
        tester,
      ) async {
        await toGoalStep(tester, 'Getting fit');
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();
        expect(find.textContaining('wake up for'), findsOneWidget);
        expect(continueEnabled(tester), isTrue);
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
        await openPage(
          tester,
          voiceRepo: FakeVoiceRepository(
            saved: [orion, astra],
            server: [orion, astra],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Getting fit'));
        await tester.pumpAndSettle();
        await tapContinue(tester);
        await tester.enterText(
          find.byType(TextField),
          'Sleep well every night',
        );
        await tester.pumpAndSettle();
        await tapContinue(tester);
        await tapContinue(tester); // why: Skip for now
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
        expect(
          tester.getTopLeft(find.text('Astra')).dy,
          lessThan(tester.getTopLeft(find.text('Orion')).dy),
        );
        expect(continueEnabled(tester), isFalse);
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
        expect(continueEnabled(tester), isTrue);
      });

      testWidgets(
        'play plays the sample (base URL added), shows the animation, and stops',
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
          expect(continueEnabled(tester), isTrue);

          await tester.tap(playOf('Astra'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(player.stops, 1);
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

    group('tone step', () {
      const astra = Voice(id: 1, name: 'Astra', voiceId: 'a');

      Future<void> toToneStep(
        WidgetTester tester, {
        List<SoundType> sounds = const [encouraging, calmSound],
        FakeReasonRepository? reasons,
        String chip = 'Getting fit',
      }) async {
        await openPage(
          tester,
          voiceRepo: FakeVoiceRepository(saved: [astra], server: [astra]),
          soundRepo: FakeSoundRepository(sounds: sounds),
          reasons: reasons,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(chip));
        await tester.pumpAndSettle();
        await tapContinue(tester);
        await tester.enterText(
          find.byType(TextField),
          'Sleep well every night',
        );
        await tester.pumpAndSettle();
        await tapContinue(tester);
        await tapContinue(tester); // why: Skip for now
        await tester.tap(find.text('Astra'));
        await tester.pumpAndSettle();
        await tapContinue(tester);
      }

      testWidgets(
        'first tone chosen, its own example, description and lengths',
        (tester) async {
          await toToneStep(tester);
          expect(find.textContaining('sound'), findsWidgets);
          expect(find.text('Example'), findsOneWidget);
          expect(find.text('You'), findsOneWidget); // word by word
          expect(find.text('Positive, warm and uplifting.'), findsOneWidget);
          expect(find.text('LENGTH'), findsOneWidget);
          expect(find.text('30 sec'), findsOneWidget);
          expect(find.text('45 sec'), findsOneWidget);
          final pill = tester.widget<PillButton>(find.byType(PillButton));
          expect(pill.label, 'Create Goal');
          expect(pill.enabled, isTrue);
        },
      );

      testWidgets('another tone shows its own example at once (no loading)', (
        tester,
      ) async {
        await toToneStep(tester);
        await tester.tap(find.bySemanticsLabel('Calm'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('You'), findsNothing);
        expect(find.text('Slow'), findsOneWidget);
        expect(find.text('Calm, peaceful and reassuring.'), findsOneWidget);
      });

      // The step itself is a PageView too: this is the card's.
      final tonePager = find.descendant(
        of: find.byType(SelectSoundStep),
        matching: find.byType(PageView),
      );

      List<double> dotWidths(WidgetTester tester) => [
        for (final e in find.byType(AnimatedContainer).evaluate())
          if (tester.getSize(find.byWidget(e.widget)).height < 12)
            tester.getSize(find.byWidget(e.widget)).width,
      ];

      testWidgets('the card is a PageView with one page dot per tone', (
        tester,
      ) async {
        await toToneStep(tester);
        expect(tonePager, findsOneWidget);
        final dots = dotWidths(tester);
        expect(dots.length, 2);
        expect(dots[0], greaterThan(dots[1]), reason: 'the first is current');
      });

      testWidgets('swiping the card chooses the next tone, dots follow', (
        tester,
      ) async {
        await toToneStep(tester);
        await tester.drag(tonePager, const Offset(-400, 0));
        await tester.pumpAndSettle();
        expect(find.text('Slow'), findsOneWidget);
        expect(find.text('You'), findsNothing);
        expect(find.text('Calm, peaceful and reassuring.'), findsOneWidget);
        final dots = dotWidths(tester);
        expect(dots[1], greaterThan(dots[0]), reason: 'the second is current');

        await tester.drag(tonePager, const Offset(400, 0));
        await tester.pumpAndSettle();
        expect(find.text('You'), findsOneWidget);
        expect(find.text('Positive, warm and uplifting.'), findsOneWidget);
      });

      testWidgets('a swipe is the same choice as a dial: it is what is saved', (
        tester,
      ) async {
        final reasons = FakeReasonRepository(
          const [],
          const [],
          const [encouraging, calmSound],
          const [astra],
        );
        await toToneStep(tester, reasons: reasons);
        await tester.drag(tonePager, const Offset(-400, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create Goal'));
        await tester.pumpAndSettle();
        expect(reasons.created.single.draft.soundTypeId, 2);
      });

      testWidgets('a short drag springs back and chooses nothing', (
        tester,
      ) async {
        await toToneStep(tester);
        await tester.drag(tonePager, const Offset(-40, 0));
        await tester.pumpAndSettle();
        expect(find.text('You'), findsOneWidget);
        expect(find.text('Slow'), findsNothing);
      });

      testWidgets('the card keeps its height whichever tone shows', (
        tester,
      ) async {
        await toToneStep(tester);
        final first = tester.getSize(tonePager).height;
        await tester.tap(find.bySemanticsLabel('Calm'));
        await tester.pumpAndSettle();
        expect(tester.getSize(tonePager).height, first);
      });

      testWidgets('a single tone has no dots', (tester) async {
        await toToneStep(tester, sounds: const [encouraging]);
        expect(dotWidths(tester), isEmpty);
      });

      testWidgets('the example is the tone\'s, whatever the topic', (
        tester,
      ) async {
        await toToneStep(tester, chip: 'Grief');
        expect(find.text('You'), findsOneWidget);
      });

      testWidgets('a tone with no sample yet shows an empty letter', (
        tester,
      ) async {
        await toToneStep(
          tester,
          sounds: const [SoundType(id: 1, title: 'Plain')],
        );
        expect(find.text('Example'), findsOneWidget);
        expect(find.text('You'), findsNothing);
        expect(continueEnabled(tester), isTrue);
      });

      testWidgets('the length note follows the chosen box', (tester) async {
        await toToneStep(tester);
        await tester.tap(find.text('45 sec'));
        await tester.pumpAndSettle();
        expect(find.text('A full thought, not a ramble.'), findsOneWidget);
      });

      group('save and ready', () {
        Future<FakeReasonRepository> toReady(
          WidgetTester tester, {
          String chip = 'Getting fit',
        }) async {
          final reasons = FakeReasonRepository(
            const [],
            const [],
            const [encouraging, calmSound],
            const [astra],
          );
          await toToneStep(tester, reasons: reasons, chip: chip);
          await tester.tap(find.text('Create Goal'));
          await tester.pumpAndSettle();
          return reasons;
        }

        testWidgets('Create Goal saves what was chosen and shows it ready', (
          tester,
        ) async {
          final reasons = await toReady(tester);
          final saved = reasons.created.single;
          expect(saved.name, 'Getting fit');
          expect(
            saved.draft,
            const ReasonDraft(
              topic: 'Getting fit',
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
          expect(find.text('Getting fit'), findsWidgets);
          expect(find.text('Sleep well every night'), findsOneWidget);
          expect(find.text('Astra'), findsOneWidget);
          expect(find.text('Encouraging'), findsOneWidget);
        });

        testWidgets('a gentle chip is saved gentle', (tester) async {
          final reasons = await toReady(tester, chip: 'Grief');
          expect(reasons.created.single.draft.focus, GoalFocus.gentle);
        });

        testWidgets('the name is the topic and can be renamed in place', (
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
          await tester.enterText(field, '  Morning run ');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(reasons.renames, [(100, 'Morning run')]);
          expect(find.text('Morning run'), findsWidgets);
        });

        testWidgets('a name is at most 20 characters', (tester) async {
          await toReady(tester);
          await tester.tap(find.byType(ReasonNameField));
          await tester.pumpAndSettle();
          final field = find.descendant(
            of: find.byType(ReasonNameField),
            matching: find.byType(TextField),
          );
          await tester.enterText(field, 'A name that is far too long to keep');
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(field).controller!.text.length,
            lessThanOrEqualTo(AppConstant.reasonNameMaxLength),
          );
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
          expect(find.text('Getting fit'), findsWidgets);
          expect(find.text('Other'), findsNothing);
        });

        testWidgets('Save for later returns to the list with the new goal', (
          tester,
        ) async {
          await toReady(tester);
          await tester.tap(find.text('Save for later'));
          await tester.pumpAndSettle();
          expect(find.byType(ReasonReadyPage), findsNothing);
          expect(find.byType(ReasonRow), findsOneWidget);
          expect(find.text('Getting fit'), findsWidgets);
        });

        testWidgets('Use with alarm opens the alarm editor, the goal chosen', (
          tester,
        ) async {
          await toReady(tester);
          await tester.tap(find.text('Use with alarm'));
          await tester.pumpAndSettle();
          expect(find.byType(ReasonReadyPage), findsNothing);
          expect(find.byType(CreateAlarmPage), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(CreateAlarmPage),
              matching: find.text('Getting fit'),
            ),
            findsWidgets,
          );
          expect(find.text('Save Alarm'), findsOneWidget);

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(find.byType(CreateAlarmPage), findsNothing);
          expect(find.byType(ReasonRow), findsOneWidget);
        });

        testWidgets('back does what Save for later does', (tester) async {
          await toReady(tester);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(ReasonReadyPage), findsNothing);
          expect(find.byType(CreateReasonPage), findsNothing);
          expect(find.byType(ReasonRow), findsOneWidget);
        });

        testWidgets('a failed save says so and stays on the tone step', (
          tester,
        ) async {
          final reasons = FakeReasonRepository()..offline = true;
          await toToneStep(tester, reasons: reasons);
          await tester.tap(find.text('Create Goal'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Couldn’t save your goal'),
            findsOneWidget,
          );
          expect(find.byType(CreateReasonPage), findsOneWidget);
          expect(find.byType(ReasonReadyPage), findsNothing);
        });
      });
    });
  });
}
