import 'dart:io';

import 'package:flutter/material.dart';
import 'package:eala/features/alarm/presentation/pages/alarm_list_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey();

BuildContext get appContext => navigatorKey.currentContext!;
AppLocalizations appLanguage([BuildContext? context]) =>
    AppLocalizations.of(context ?? appContext)!;

ThemeData appTheme([BuildContext? context]) => Theme.of(context ?? appContext);

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // ..maxConnectionsPerHost = 2
      ..badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(428, 900),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Eala',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        );
      },
    );
  }
}
