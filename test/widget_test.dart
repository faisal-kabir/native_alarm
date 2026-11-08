import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

void main() {
  testWidgets('app opens on the Dashboard with the My Alarms page', (
    WidgetTester tester,
  ) async {
    await registerFakeAlarmDependencies(FakeAlarmRepository());
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Alarms'), findsOneWidget);
    expect(find.text('Your alarms'), findsOneWidget);
    expect(find.text('Up to 3'), findsOneWidget);
    expect(find.text('Set your first alarm'), findsOneWidget);
    expect(find.text('Pick a time and a reason.'), findsOneWidget);
    // The glass lens draws a second copy of the selected tab's label.
    expect(find.text('Alarms'), findsWidgets);
    expect(find.text('Reasons'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('tapping the tabs moves between the pages', (
    WidgetTester tester,
  ) async {
    await registerFakeAlarmDependencies(FakeAlarmRepository());
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reasons').first);
    await tester.pumpAndSettle();
    expect(find.text('My Reasons'), findsOneWidget);
    expect(find.text('Add your first Reason'), findsOneWidget);
    expect(find.text('The why behind your day.'), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(find.text('Alarms').first);
    await tester.pumpAndSettle();
    expect(find.text('My Alarms'), findsOneWidget);
  });

  testWidgets('swiping the pages moves the tab and keeps My Alarms alive', (
    WidgetTester tester,
  ) async {
    await registerFakeAlarmDependencies(FakeAlarmRepository());
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.fling(find.text('My Alarms'), const Offset(-600, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Add your first Reason'), findsOneWidget);

    await tester.fling(
      find.text('Add your first Reason'),
      const Offset(600, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('My Alarms'), findsOneWidget);
  });

  testWidgets('the add card is hidden once an alarm exists', (
    WidgetTester tester,
  ) async {
    final repo = FakeAlarmRepository();
    await repo.saveAlarm(
      Alarm(
        id: 'a1',
        enabled: true,
        time: DateTime.now().add(const Duration(hours: 1)),
        audioTrackId: 'morning_message',
        ringtoneId: 'default',
      ),
    );
    await registerFakeAlarmDependencies(repo);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('My Alarms'), findsOneWidget);
    expect(find.text('Set your first alarm'), findsNothing);
  });

  testWidgets(
    'Reasons tab lists reasons with area and tone, then the New Reason row',
    (WidgetTester tester) async {
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        reasonRepository: FakeReasonRepository([
          testReason(
            id: 1,
            name: 'First reason',
            area: 'Alpha',
            areaColor: 0xFF112233,
            tone: 'Tone A',
          ),
          testReason(
            id: 2,
            name: 'Second reason',
            area: 'Beta',
            tone: 'Tone B',
          ),
        ]),
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reasons').first);
      await tester.pumpAndSettle();

      expect(find.text('First reason'), findsOneWidget);
      expect(find.text('Alpha · Tone A'), findsOneWidget);
      expect(find.text('Second reason'), findsOneWidget);
      expect(find.text('Beta · Tone B'), findsOneWidget);
      // The emblem shows the first letter of the area's name.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('New Reason'), findsOneWidget);
      expect(find.text('Add your first Reason'), findsNothing);
    },
  );

  testWidgets('Settings tab shows the groups, version and saves a switch', (
    WidgetTester tester,
  ) async {
    final settings = FakeSettingsRepository();
    await registerFakeAlarmDependencies(
      FakeAlarmRepository(),
      settingsRepository: settings,
    );
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();

    expect(find.text('Set your name'), findsOneWidget);
    expect(find.text('Not signed in'), findsOneWidget);

    // The third switch ("Thoughts for the day") is off by default; turn it on.
    await tester.tap(find.byType(CupertinoSwitch).last);
    await tester.pumpAndSettle();
    expect(settings.saved?.notifyQuotes, isTrue);

    for (final text in [
      'Trial & billing',
      'Alarm reminders',
      'Thoughts for the day',
      'Free',
      'Help & Support',
      'Privacy Policy',
      'Sign In',
      'Delete account',
      'Eala 1.0.0 (1)',
    ]) {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(text), findsOneWidget);
    }
  });
}
