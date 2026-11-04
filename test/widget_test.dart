import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/main.dart';
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
    expect(find.text('Reasons screen will be here'), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Settings screen will be here'), findsOneWidget);

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
    expect(find.text('Reasons screen will be here'), findsOneWidget);

    await tester.fling(
      find.text('Reasons screen will be here'),
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
}
