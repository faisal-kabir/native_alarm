import 'package:eala/features/reasons/presentation/widgets/reason_emblem.dart';
import 'package:eala/features/voice/domain/entities/voice.dart';
import 'package:eala/l10n/app_localizations.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const astra = Voice(id: 1, name: 'Astra', voiceId: 'a');

Widget host(Widget child) => ScreenUtilInit(
  designSize: const Size(414, 900),
  builder: (context, _) => MaterialApp(
    navigatorKey: navigatorKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  ),
);

/// The face's one filter (grey + dim), or null in full colour.
ColorFilter? faceFilter(WidgetTester tester) {
  final filtered = find.descendant(
    of: find.byType(ReasonEmblem),
    matching: find.byType(ColorFiltered),
  );
  return filtered.evaluate().isEmpty
      ? null
      : tester.widget<ColorFiltered>(filtered).colorFilter;
}

void main() {
  testWidgets(
    'a goal wears the face of its voice (its first letter without a picture)',
    (tester) async {
      await tester.pumpWidget(
        host(const ReasonEmblem(voice: astra, name: 'Getting fit')),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('G'), findsNothing);
    },
  );

  testWidgets('no voice joined yet: the first letter of the goal\'s name', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const ReasonEmblem(voice: null, name: 'Getting fit')),
    );
    expect(find.text('G'), findsOneWidget);
  });

  testWidgets('it is 46 round by default, or the size asked for', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ReasonEmblem(voice: astra, name: 'x')));
    final big = tester.getSize(find.byType(ReasonEmblem));
    expect(big.width, big.height);
    await tester.pumpWidget(
      host(const ReasonEmblem(voice: astra, name: 'x', size: 28)),
    );
    expect(
      tester.getSize(find.byType(ReasonEmblem)).width,
      lessThan(big.width),
    );
  });

  testWidgets(
    'a switched-off alarm greys and dims the face, and it comes back',
    (tester) async {
      await tester.pumpWidget(
        host(const ReasonEmblem(voice: astra, name: 'x', muted: true)),
      );
      await tester.pumpAndSettle();
      expect(faceFilter(tester), ReasonEmblem.mutedFilter(0));

      await tester.pumpWidget(
        host(const ReasonEmblem(voice: astra, name: 'x')),
      );
      await tester.pump(const Duration(milliseconds: 150));
      final midway = faceFilter(tester);
      expect(midway, isNotNull);
      expect(midway, isNot(ReasonEmblem.mutedFilter(0)));
      await tester.pumpAndSettle();
      // Back in full colour: no filter (and no layer) at all.
      expect(faceFilter(tester), isNull);
    },
  );

  testWidgets('the alarm badge hangs off the corner only when asked', (
    tester,
  ) async {
    for (final badge in ReasonAlarmBadge.values) {
      await tester.pumpWidget(
        host(ReasonEmblem(voice: astra, name: 'x', badge: badge)),
      );
      final face = tester.getRect(find.byType(ReasonEmblem));
      final marks = find.descendant(
        of: find.byType(ReasonEmblem),
        matching: find.byType(DecoratedBox),
      );
      final hasBadge = badge != ReasonAlarmBadge.none;
      // Face (clipped oval) aside, the badge is the one circle hanging past the corner.
      final outside = [
        for (final e in marks.evaluate())
          tester.getRect(find.byWidget(e.widget)).right > face.right + 1,
      ].any((x) => x);
      expect(outside, hasBadge, reason: '$badge');
    }
  });
}
