import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'app_database.dart';

/// Provides the one [AppDatabase] instance. The SQLite file (`eala.sqlite`) lives in
/// the app's documents directory and is opened lazily on the first query.
@module
abstract class DatabaseModule {
  @lazySingleton
  AppDatabase get database => AppDatabase(driftDatabase(name: 'eala'));
}
