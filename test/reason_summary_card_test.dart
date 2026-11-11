import 'package:eala/features/create_reason/presentation/widgets/reason_summary_card.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/l10n/app_localizations.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

Widget host(
  Reason reason, {
  Animation<double>? timeline,
  double total = 2.5,
  double delay = 1.2,
}) => ScreenUtilInit(
  designSize: const Size(414, 900),
  builder: (context, _) => MaterialApp(
    navigatorKey: navigatorKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: ReasonSummaryCard(
          reason: reason,
          name: const Text('Getting fit'),
          timeline: timeline,
          total: total,
          delay: delay,
        ),
      ),
    ),
  ),
);

Finder label(String text) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').toLowerCase() == text.toLowerCase(),
);

void main() {
  testWidgets('three lines in the order of the questions, then the choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        testReason(
          purpose: 'Run a 5K by spring',
          why: 'I want energy for the people I love',
          tone: 'Focused',
          lengthSeconds: 45,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final top = [
      for (final text in ['Wake up for', 'Goal', 'Why'])
        tester.getTopLeft(label(text)).dy,
    ];
    expect(top[0], lessThan(top[1]));
    expect(top[1], lessThan(top[2]));

    expect(find.text('Getting fit'), findsOneWidget);
    expect(find.text('Run a 5K by spring'), findsOneWidget);
    expect(find.text('I want energy for the people I love'), findsOneWidget);
    for (final text in ['Voice', 'Tone', 'Length']) {
      expect(label(text), findsOneWidget);
    }
    expect(find.text('Astra'), findsOneWidget);
    expect(find.text('Focused'), findsOneWidget);
    expect(find.text('45 sec'), findsOneWidget);
  });

  testWidgets('no "Why" when there is none', (tester) async {
    await tester.pumpWidget(host(testReason(why: '  ')));
    await tester.pumpAndSettle();
    expect(label('Why'), findsNothing);
    expect(label('Goal'), findsOneWidget);
  });

  testWidgets('the choices sit in three equal columns', (tester) async {
    await tester.pumpWidget(host(testReason(tone: 'Focused')));
    await tester.pumpAndSettle();
    final card = tester.getSize(find.byType(ReasonSummaryCard)).width;
    final voice = tester.getTopLeft(label('Voice')).dx;
    final tone = tester.getTopLeft(label('Tone')).dx;
    final length = tester.getTopLeft(label('Length')).dx;
    // Tone and length are plain cells, so their labels are one column apart.
    expect(length - tone, closeTo(card / 3, 2));
    expect(voice, lessThan(tone));
  });

  testWidgets('a goal is at most three lines, a why at most two', (
    tester,
  ) async {
    final long = List.filled(60, 'word').join(' ');
    await tester.pumpWidget(host(testReason(purpose: long, why: long)));
    await tester.pumpAndSettle();
    for (final text in tester.widgetList<Text>(find.text(long))) {
      expect(text.overflow, TextOverflow.ellipsis);
    }
    expect(
      [for (final t in tester.widgetList<Text>(find.text(long))) t.maxLines],
      [3, 2],
    );
  });

  testWidgets('it arrives one line after another, then the choices', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 2500),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(testReason(why: 'Because'), timeline: controller),
    );

    double opacityOf(String text) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    // Before the card starts, nothing shows.
    expect(opacityOf('Getting fit'), 0);
    controller.value = 1.2 / 2.5; // the card starts
    await tester.pump();
    expect(opacityOf('Getting fit'), 0);
    controller.value = 1.5 / 2.5; // first line in, second on its way
    await tester.pump();
    expect(opacityOf('Getting fit'), greaterThan(0.5));
    expect(
      opacityOf('Sleep well every night'),
      lessThan(opacityOf('Getting fit')),
    );
    controller.value = 1;
    await tester.pump();
    expect(opacityOf('Getting fit'), 1);
    expect(opacityOf('Because'), 1);
    expect(opacityOf('Astra'), 1);
  });
}
