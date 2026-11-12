import 'dart:async';

import 'package:eala/core/error/failures.dart';
import 'package:eala/core/router/app_router.dart';
import 'package:eala/core/router/route_names.dart';
import 'package:eala/features/auth/domain/entities/app_user.dart';
import 'package:eala/features/auth/domain/entities/auth_provider.dart';
import 'package:eala/features/auth/domain/entities/user_profile.dart';
import 'package:eala/features/settings/presentation/bloc/account_bloc.dart';
import 'package:eala/features/settings/presentation/bloc/account_event.dart';
import 'package:eala/features/settings/presentation/bloc/account_state.dart';
import 'package:eala/features/settings/presentation/pages/profile_page.dart';
import 'package:eala/core/di/injection.dart';
import 'package:eala/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

const apple = AppUser(
  id: 'u',
  isAnonymous: false,
  provider: AuthProvider.apple,
  email: 'alex@icloud.com',
);
const google = AppUser(
  id: 'u',
  isAnonymous: false,
  provider: AuthProvider.google,
);
const otherAccount = AppUser(id: 'u', isAnonymous: false);
const anonymous = AppUser(id: 'u', isAnonymous: true);

UserProfile named(String name) =>
    UserProfile(id: 1, authUserId: 'u', name: name);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('AccountBloc', () {
    late FakeAuthRepository auth;
    late FakeUserProfileRepository profiles;
    late FakeReasonRepository reasons;
    late AccountBloc bloc;

    Future<void> start({AppUser user = anonymous, String? name}) async {
      auth = FakeAuthRepository(user: user);
      profiles = FakeUserProfileRepository();
      reasons = FakeReasonRepository();
      if (name != null) profiles.cached = named(name);
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        authRepository: auth,
        userProfileRepository: profiles,
        reasonRepository: reasons,
      );
      bloc = instance<AccountBloc>()..add(const AccountStartedEvent());
      await settle();
      await settle();
    }

    tearDown(() => bloc.close());

    test(
      'a person who has not signed in is "signed out", with no name',
      () async {
        await start();
        expect(bloc.state.status, AccountStatus.signedOut);
        expect(bloc.state.signedIn, isFalse);
        expect(bloc.state.name, '');
        expect(bloc.state.loaded, isTrue);
      },
    );

    test('signed in with Apple, Google, or some other account', () async {
      for (final (user, status) in [
        (apple, AccountStatus.apple),
        (google, AccountStatus.google),
        (otherAccount, AccountStatus.thisDevice),
      ]) {
        await start(user: user);
        expect(bloc.state.status, status);
        expect(bloc.state.signedIn, isTrue);
        await bloc.close();
      }
    });

    test('the saved name is read from the device', () async {
      await start(name: '  Alex ');
      expect(bloc.state.name, 'Alex');
    });

    test('starting twice does nothing the second time', () async {
      await start();
      bloc.add(const AccountStartedEvent());
      await settle();
      expect(bloc.state.loaded, isTrue);
    });

    test(
      'the provider shown is the one the profile says was used last',
      () async {
        auth = FakeAuthRepository(user: apple);
        profiles = FakeUserProfileRepository()
          ..cached = const UserProfile(
            id: 1,
            authUserId: 'u',
            primaryProvider: 'google',
          );
        reasons = FakeReasonRepository();
        await registerFakeAlarmDependencies(
          FakeAlarmRepository(),
          authRepository: auth,
          userProfileRepository: profiles,
          reasonRepository: reasons,
        );
        bloc = instance<AccountBloc>()..add(const AccountStartedEvent());
        await settle();
        await settle();
        expect(bloc.state.status, AccountStatus.google);
      },
    );

    test('a sign-in shows the provider just used, and saves it', () async {
      await start();
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.apple));
      await settle();
      await settle();
      expect(bloc.state.status, AccountStatus.apple);
      expect(profiles.cached?.primaryProvider, 'apple');

      bloc.add(const AccountSignOutRequestedEvent());
      await settle();
      await settle();
      expect(bloc.state.status, AccountStatus.signedOut);
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.google));
      await settle();
      await settle();
      expect(bloc.state.status, AccountStatus.google);
      expect(profiles.cached?.primaryProvider, 'google');
    });

    test('signing in follows the session: the card changes at once', () async {
      await start(name: 'Alex');
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.google));
      await settle();
      await settle();
      expect(auth.signIns, [AuthProvider.google]);
      expect(bloc.state.status, AccountStatus.google);
      expect(bloc.state.busy, isFalse);
      expect(bloc.state.notice, AccountNotice.none);
      expect(profiles.signInsRecorded.single.provider, AuthProvider.google);
    });

    test('linked: the same user, so nothing is read again', () async {
      await start();
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.google));
      await settle();
      await settle();
      expect(profiles.syncs, 0);
      expect(reasons.refreshes, 0);
    });

    test('an account that already existed: its profile and goals (the ones '
        'moved there included) are read again', () async {
      await start();
      auth.joins = true;
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.apple));
      await settle();
      await settle();
      expect(bloc.state.status, AccountStatus.apple);
      expect(profiles.syncs, 1);
      expect(reasons.refreshes, 1);
    });

    test(
      '...but while the move is unfinished the goals are left alone',
      () async {
        await start();
        auth
          ..joins = true
          ..mergePending = true;
        bloc.add(const AccountSignInRequestedEvent(AuthProvider.apple));
        await settle();
        await settle();
        expect(bloc.state.signedIn, isTrue);
        expect(reasons.refreshes, 0);
      },
    );

    test('...and takes the provider\'s name when none is set', () async {
      await start();
      auth.providerName = 'Alex Rivers';
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.apple));
      await settle();
      await settle();
      expect(bloc.state.name, 'Alex Rivers');
    });

    test('...but never over a name that is already set', () async {
      await start(name: 'Sam');
      auth.providerName = 'Alex Rivers';
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.apple));
      await settle();
      await settle();
      expect(bloc.state.name, 'Sam');
    });

    test('a sign-in waits for the one before it', () async {
      await start();
      auth.signInGate = Completer<void>();
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.google));
      await settle();
      expect(bloc.state.busy, isTrue);
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.apple));
      await settle();
      auth.signInGate!.complete();
      await settle();
      await settle();
      expect(auth.signIns, [AuthProvider.google]);
      expect(bloc.state.busy, isFalse);
    });

    test('closing the sheet says nothing', () async {
      await start();
      auth.signInFailure = const CancelledFailure('Cancelled');
      bloc.add(const AccountSignInRequestedEvent(AuthProvider.google));
      await settle();
      await settle();
      expect(bloc.state.notice, AccountNotice.none);
      expect(bloc.state.signedIn, isFalse);
      expect(bloc.state.busy, isFalse);
    });

    test('a sign-in that fails says so, every time', () async {
      await start();
      auth.signInFailure = const ServerFailure('offline');
      for (var i = 0; i < 2; i++) {
        bloc.add(const AccountSignInRequestedEvent(AuthProvider.google));
        await settle();
        await settle();
      }
      expect(bloc.state.notice, AccountNotice.signInFailed);
      expect(bloc.state.noticeCount, 2, reason: 'heard twice');
      expect(bloc.state.signedIn, isFalse);
    });

    test(
      'signing out is back to "not signed in", and the name stays',
      () async {
        await start(user: apple, name: 'Alex');
        bloc.add(const AccountSignOutRequestedEvent());
        await settle();
        await settle();
        expect(auth.signOuts, 1);
        expect(bloc.state.status, AccountStatus.signedOut);
        expect(bloc.state.name, 'Alex');
        expect(profiles.names, ['Alex'], reason: 'given to the new user too');
      },
    );

    test('a sign-out that fails stays signed in and says so', () async {
      await start(user: google);
      auth.signOutFails = true;
      bloc.add(const AccountSignOutRequestedEvent());
      await settle();
      await settle();
      expect(bloc.state.status, AccountStatus.google);
      expect(bloc.state.notice, AccountNotice.signOutFailed);
      expect(bloc.state.busy, isFalse);
    });

    test('a name is saved, and only a name that can be spoken', () async {
      await start(name: 'Alex');
      bloc.add(const AccountNameSavedEvent('Sam'));
      await settle();
      await settle();
      expect(bloc.state.name, 'Sam');
      expect(profiles.names, ['Sam']);

      for (final bad in ['', 'S', 'Sam7', 'Sam']) {
        bloc.add(AccountNameSavedEvent(bad));
      }
      await settle();
      expect(profiles.names, ['Sam'], reason: 'invalid or unchanged: not sent');
    });

    test('a name that fails to save keeps the old one and says so', () async {
      await start(name: 'Alex');
      profiles.nameFails = true;
      bloc.add(const AccountNameSavedEvent('Sam'));
      await settle();
      await settle();
      expect(bloc.state.name, 'Alex');
      expect(bloc.state.notice, AccountNotice.nameFailed);
    });
  });

  group('Profile page', () {
    setUp(() => appRouter.go(RouteNames.dashboardPath));

    Future<FakeAuthRepository> open(
      WidgetTester tester, {
      AppUser user = anonymous,
      String? name,
      FakeUserProfileRepository? profiles,
    }) async {
      final auth = FakeAuthRepository(user: user);
      final repo = profiles ?? FakeUserProfileRepository();
      if (name != null) repo.cached = named(name);
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        authRepository: auth,
        userProfileRepository: repo,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(name ?? 'Set your name'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      return auth;
    }

    final nameField = find.byType(TextField);

    testWidgets('not signed in: "Not signed in" and the way in', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Your name'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.text('Signed in with'), findsNothing);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.textContaining('Keep your goals, alarms'), findsOneWidget);
    });

    testWidgets('signing in on Profile shows the account and stays open', (
      tester,
    ) async {
      final auth = await open(tester, name: 'Alex');
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();
      expect(auth.signIns, [AuthProvider.google]);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Signed in with'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('a name given with a sign-in fills an empty field', (
      tester,
    ) async {
      final auth = FakeAuthRepository()..providerName = 'Alex';
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        authRepository: auth,
        userProfileRepository: FakeUserProfileRepository(),
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set your name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(nameField).controller!.text, 'Alex');
    });

    for (final (user, provider) in [
      (apple, 'Apple'),
      (google, 'Google'),
      (otherAccount, 'This device'),
    ]) {
      testWidgets('signed in: "Signed in with" and $provider', (tester) async {
        await open(tester, user: user, name: 'Alex');
        expect(find.text('Signed in with'), findsOneWidget);
        expect(find.text(provider), findsOneWidget);
        expect(find.text('Not signed in'), findsNothing);
        expect(find.text('Sign in with Google'), findsNothing);
      });
    }

    testWidgets('the saved name is in the field; Save waits for a change', (
      tester,
    ) async {
      await open(tester, name: 'Alex');
      expect(tester.widget<TextField>(nameField).controller!.text, 'Alex');
      final save = find.bySemanticsLabel('Save');
      expect(
        tester.getSemantics(save).flagsCollection.isEnabled.name,
        isNot('isTrue'),
      );
      await tester.enterText(nameField, 'Sam');
      await tester.pump();
      expect(
        tester.getSemantics(save).flagsCollection.isEnabled.name,
        'isTrue',
      );
    });

    testWidgets('only letters, spaces, hyphens and apostrophes get in', (
      tester,
    ) async {
      await open(tester, name: 'Alex');
      await tester.enterText(nameField, "Anne-Marie O'B7r!ien");
      await tester.pump();
      expect(
        tester.widget<TextField>(nameField).controller!.text,
        "Anne-Marie O'Brien",
      );
      await tester.enterText(nameField, 'A' * 40);
      await tester.pump();
      expect(tester.widget<TextField>(nameField).controller!.text.length, 24);
    });

    testWidgets(
      'Save keeps the name and goes back to Settings, now showing it',
      (tester) async {
        final profiles = FakeUserProfileRepository();
        await open(tester, name: 'Alex', profiles: profiles);
        await tester.enterText(nameField, 'Sam');
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Save'));
        await tester.pumpAndSettle();
        expect(profiles.names, ['Sam']);
        expect(find.byType(ProfilePage), findsNothing);
        expect(find.text('Sam'), findsOneWidget);
        expect(find.text('Alex'), findsNothing);
      },
    );

    testWidgets('a name that is too short is not saved', (tester) async {
      final profiles = FakeUserProfileRepository();
      await open(tester, name: 'Alex', profiles: profiles);
      await tester.enterText(nameField, 'S');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();
      expect(profiles.names, isEmpty);
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('a save that fails says so and stays', (tester) async {
      final profiles = FakeUserProfileRepository()..nameFails = true;
      await open(tester, name: 'Alex', profiles: profiles);
      await tester.enterText(nameField, 'Sam');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t save your name'), findsOneWidget);
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('back returns to Settings without saving', (tester) async {
      final profiles = FakeUserProfileRepository();
      await open(tester, name: 'Alex', profiles: profiles);
      await tester.enterText(nameField, 'Sam');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(profiles.names, isEmpty);
      expect(find.byType(ProfilePage), findsNothing);
      expect(find.text('Alex'), findsOneWidget);
    });
  });

  group('Settings: signed out and signed in', () {
    setUp(() => appRouter.go(RouteNames.dashboardPath));

    Future<FakeAuthRepository> open(
      WidgetTester tester, {
      AppUser user = anonymous,
      String? name,
      FakeUserProfileRepository? profiles,
    }) async {
      final auth = FakeAuthRepository(user: user);
      final repo = profiles ?? FakeUserProfileRepository();
      if (name != null) repo.cached = named(name);
      await registerFakeAlarmDependencies(
        FakeAlarmRepository(),
        authRepository: auth,
        userProfileRepository: repo,
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      return auth;
    }

    /// Back to the top of the page, where the card is.
    Future<void> toTop(WidgetTester tester) async {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 3000));
      await tester.pumpAndSettle();
    }

    /// Scrolls to the row and a little past it, clear of the floating tab bar.
    Future<void> toAccountGroup(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -160));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'signed out: the card says so; the row is "Sign In", with the note',
      (tester) async {
        await open(tester);
        expect(find.text('Set your name'), findsOneWidget);
        expect(find.text('Not signed in'), findsOneWidget);
        await toAccountGroup(tester, 'Sign In');
        expect(find.text('Sign Out'), findsNothing);
        expect(
          find.textContaining('Keep your goals, alarms and Premium'),
          findsOneWidget,
        );
      },
    );

    for (final (user, line) in [
      (apple, 'Signed in with Apple'),
      (google, 'Signed in with Google'),
      (otherAccount, 'Signed in on this device'),
    ]) {
      testWidgets('signed in: the card says "$line"; the row is "Sign Out"', (
        tester,
      ) async {
        await open(tester, user: user, name: 'Alex');
        expect(find.text('Alex'), findsOneWidget);
        expect(find.text(line), findsOneWidget);
        expect(find.text('Not signed in'), findsNothing);
        await toAccountGroup(tester, 'Sign Out');
        expect(find.text('Sign In'), findsNothing);
        expect(find.textContaining('Keep your goals, alarms'), findsNothing);
        expect(find.text('Delete account'), findsOneWidget);
      });
    }

    testWidgets('the sign-in sheet offers Google, and Apple on an iPhone', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await open(tester);
        await toAccountGroup(tester, 'Sign In');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        expect(find.text('Keep your goals safe'), findsOneWidget);
        expect(find.text('So they follow you to any phone.'), findsOneWidget);
        expect(find.text('Sign in with Apple'), findsOneWidget);
        expect(find.text('Sign in with Google'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('on Android there is no Apple button', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await open(tester);
        await toAccountGroup(tester, 'Sign In');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        expect(find.text('Sign in with Apple'), findsNothing);
        expect(find.text('Sign in with Google'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'Sign in with Google signs in, and the page turns to "Sign Out"',
      (tester) async {
        final auth = await open(tester, name: 'Alex');
        await toAccountGroup(tester, 'Sign In');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();

        expect(auth.signIns, [AuthProvider.google]);
        expect(find.text('Keep your goals safe'), findsNothing);
        await toTop(tester);
        expect(find.text('Signed in with Google'), findsOneWidget);
        await toAccountGroup(tester, 'Sign Out');
        expect(find.text('Sign In'), findsNothing);
      },
    );

    testWidgets('closing the sheet signs nobody in', (tester) async {
      final auth = await open(tester);
      await toAccountGroup(tester, 'Sign In');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 60)); // the scrim
      await tester.pumpAndSettle();
      expect(find.text('Keep your goals safe'), findsNothing);
      expect(auth.signIns, isEmpty);
      await toTop(tester);
      expect(find.text('Not signed in'), findsOneWidget);
    });

    testWidgets('a sign-in that fails says so and stays signed out', (
      tester,
    ) async {
      final auth = await open(tester);
      auth.signInFailure = const ServerFailure('offline');
      await toAccountGroup(tester, 'Sign In');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t sign in'), findsOneWidget);
      await toTop(tester);
      expect(find.text('Not signed in'), findsOneWidget);
    });

    testWidgets('Sign Out asks first; Cancel changes nothing', (tester) async {
      final auth = await open(tester, user: apple, name: 'Alex');
      await toAccountGroup(tester, 'Sign Out');
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out of Eala?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 0);
      await toTop(tester);
      expect(find.text('Signed in with Apple'), findsOneWidget);
    });

    testWidgets(
      'confirming signs out: "Not signed in", "Sign In", the name stays',
      (tester) async {
        final auth = await open(tester, user: apple, name: 'Alex');
        await toAccountGroup(tester, 'Sign Out');
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign Out').last);
        await tester.pumpAndSettle();

        expect(auth.signOuts, 1);
        await toTop(tester);
        expect(find.text('Not signed in'), findsOneWidget);
        expect(find.text('Alex'), findsOneWidget);
        await toAccountGroup(tester, 'Sign In');
        expect(find.text('Sign Out'), findsNothing);
      },
    );
  });
}
