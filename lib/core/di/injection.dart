import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// The app-wide service locator. Every BLoC, UseCase, Repository and DataSource is
/// resolved through it (see README §1).
final GetIt instance = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  instance.init();
}
