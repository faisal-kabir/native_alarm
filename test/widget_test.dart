import 'package:eala/features/alarm/domain/entities/alarm.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/entities/reason_area.dart';
import 'package:eala/features/reasons/domain/entities/reason_tone.dart';
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
    expect(find.text('My Reasons'), findsOneWidget);
    expect(find.text('Add your first Reason'), findsOneWidget);
    expect(find.text('The why behind your day.'), findsOneWidget);

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
        reasonRepository: FakeReasonRepository(const [
          Reason(
            id: '1',
            name: 'Stronger Every Day',
            area: ReasonArea.health,
            tone: ReasonTone.encouraging,
          ),
          Reason(
            id: '2',
            name: 'Study for the exam',
            area: ReasonArea.study,
            tone: ReasonTone.focused,
          ),
        ]),
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reasons').first);
      await tester.pumpAndSettle();

      expect(find.text('Stronger Every Day'), findsOneWidget);
      expect(find.text('Health · Encouraging'), findsOneWidget);
      expect(find.text('Study for the exam'), findsOneWidget);
      expect(find.text('Learning & Skills · Focused'), findsOneWidget);
      expect(find.text('New Reason'), findsOneWidget);
      expect(find.text('Add your first Reason'), findsNothing);
    },
  );
}
