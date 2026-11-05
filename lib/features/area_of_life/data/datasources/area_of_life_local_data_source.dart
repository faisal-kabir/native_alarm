import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../models/area_of_life_model.dart';
import '../models/areas_of_life_table.dart';

abstract class AreaOfLifeLocalDataSource {
  /// The saved areas, by id; emits again after every change of the table.
  Stream<List<AreaOfLifeRecord>> watchAreas();

  /// Makes the saved areas exactly [areas]: rows are added or updated, and rows the
  /// server no longer has are removed, all in one transaction.
  Future<void> replaceAll(List<AreaOfLifeModel> areas);
}

@LazySingleton(as: AreaOfLifeLocalDataSource)
class AreaOfLifeLocalDataSourceImpl implements AreaOfLifeLocalDataSource {
  final AppDatabase db;

  AreaOfLifeLocalDataSourceImpl(this.db);

  @override
  Stream<List<AreaOfLifeRecord>> watchAreas() => (db.select(
    db.areasOfLifeTable,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  @override
  Future<void> replaceAll(List<AreaOfLifeModel> areas) async {
    try {
      await db.transaction(() async {
        final ids = areas.map((a) => a.id).toList();
        await (db.delete(
          db.areasOfLifeTable,
        )..where((t) => t.id.isNotIn(ids))).go();
        await db.batch(
          (batch) => batch.insertAllOnConflictUpdate(
            db.areasOfLifeTable,
            areas.map((a) => a.toCompanion()).toList(),
          ),
        );
      });
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
