import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/entities/reason_area.dart';
import 'package:eala/features/reasons/domain/entities/reason_tone.dart';
import 'package:eala/features/reasons/presentation/widgets/reason_row.dart';
import 'package:eala/features/reasons/presentation/widgets/reason_view.dart';
import 'package:eala/l10n/app_localizations.dart';
import 'package:eala/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _reason = Reason(
  id: '1',
  name: 'Build my own thing',
  area: ReasonArea.business,
  tone: ReasonTone.focused,
);

Widget _host(ReasonAlarmBadge badge) => ScreenUtilInit(
  designSize: const Size(428, 900),
  builder: (context, _) => MaterialApp(
    navigatorKey: navigatorKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ReasonRow(reason: _reason, badge: badge),
    ),
  ),
);

void main() {
  testWidgets('screen reader label says whether an alarm plays the reason', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final cases = {
      ReasonAlarmBadge.none: 'Build my own thing. Business, Focused tone.',
      ReasonAlarmBadge.on:
          'Build my own thing. Business, Focused tone. Played by an alarm.',
      ReasonAlarmBadge.off:
          'Build my own thing. Business, Focused tone. Its alarm is off.',
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(_host(entry.key));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(entry.value), findsOneWidget);
    }
    handle.dispose();
  });
}
