import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

void main() {
  setUp(() => appRouter.go(RouteNames.dashboardPath));

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'on ${platform.name} a page slides in from the right and back out to it',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        await registerFakeAlarmDependencies(FakeAlarmRepository());
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        final screenWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;

        appRouter.push(RouteNames.createReasonPath);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        // Half-way in: the new page is still right of its place.
        final enteringX = tester
            .getTopLeft(find.textContaining('wake up for'))
            .dx;
        expect(enteringX, greaterThan(screenWidth * 0.2));

        await tester.pumpAndSettle();
        final restingX = tester
            .getTopLeft(find.textContaining('wake up for'))
            .dx;
        expect(restingX, lessThan(enteringX));

        // Back: it moves right again on its way out.
        appRouter.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final leavingX = tester
            .getTopLeft(find.textContaining('wake up for'))
            .dx;
        expect(leavingX, greaterThan(restingX));

        await tester.pumpAndSettle();
        expect(find.textContaining('wake up for'), findsNothing);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
