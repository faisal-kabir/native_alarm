import 'package:eala/features/splash/presentation/widgets/eala_splash.dart';
import 'package:eala/features/splash/presentation/widgets/splash_timeline.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

void main() {
  group('SplashTimeline', () {
    const w = [40.0, 44.0, 20.0, 44.0];

    test('the first letter starts centred, the whole word ends centred', () {
      // Only the "e" shown: the word is moved so the "e" sits in the middle.
      expect(SplashTimeline.glide(0, w), (148 - 40) / 2);
      expect(SplashTimeline.glide(SplashTimeline.hold, w), closeTo(0, 1e-9));
    });

    test('the e turns once, after the word is written', () {
      expect(SplashTimeline.turns(SplashTimeline.turn), 0);
      expect(SplashTimeline.turns(SplashTimeline.turn + 0.9), 1);
      expect(
        SplashTimeline.eLetter(SplashTimeline.turn + 0.6),
        closeTo(0, 1e-6),
      );
      expect(SplashTimeline.markE(0.6), 1);
    });

    test('the word and the black are gone at the end', () {
      expect(SplashTimeline.wordOpacity(0), 1);
      expect(SplashTimeline.blackOpacity(0), 1);
      expect(SplashTimeline.wordOpacity(SplashTimeline.hold), 0);
      // The black is all but gone; the splash leaves at that moment.
      expect(SplashTimeline.blackOpacity(SplashTimeline.hold), lessThan(0.02));
    });
  });

  group('splash on a cold start', () {
    setUp(() async {
      await registerFakeAlarmDependencies(FakeAlarmRepository());
      SplashGate.shown = false;
    });

    testWidgets('plays over the home screen, then leaves it', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.byType(EalaSplash), findsOneWidget);
      expect(find.text('My Alarms'), findsOneWidget); // loading underneath

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.byType(EalaSplash), findsNothing);
    });

    testWidgets('a tap skips it', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(EalaSplash));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byType(EalaSplash), findsNothing);
    });

    testWidgets('with reduced motion it is gone after 200 ms', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.byType(EalaSplash), findsNothing);
    });

    testWidgets('a page opened over it (an alarm) ends it', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 300));
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(EalaSplash), findsNothing);
    });

    testWidgets('shows once per run', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(SplashGate.shown, isTrue);
      await tester.pump(const Duration(seconds: 5));
      // The home screen built again later (gone home from the ringing page).
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SplashGate(child: SizedBox()),
        ),
      );
      expect(find.byType(EalaSplash), findsNothing);
    });
  });
}
