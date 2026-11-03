import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/alarm/data/models/alarm_isar_model.dart';

/// Opens the app's Isar database once at startup. Add every feature's schema here.
@module
abstract class DatabaseModule {
  @preResolve
  @singleton
  Future<Isar> get isar async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open([AlarmIsarModelSchema], directory: dir.path);
  }
}
