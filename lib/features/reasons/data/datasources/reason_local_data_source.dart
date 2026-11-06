import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/reason.dart';
import '../models/reasons_table.dart';

abstract class ReasonLocalDataSource {
  /// The saved reasons, oldest first; emits again after every change.
  Stream<List<ReasonRecord>> watchReasons();

  /// Adds (or replaces) [reason] in the device's copy.
  Future<void> saveReason(Reason reason);

  Future<void> renameReason(String id, String name);
}

@LazySingleton(as: ReasonLocalDataSource)
class ReasonLocalDataSourceImpl implements ReasonLocalDataSource {
  final AppDatabase db;

  ReasonLocalDataSourceImpl(this.db);

  @override
  Stream<List<ReasonRecord>> watchReasons() => (db.select(
    db.reasonsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();

  @override
  Future<void> saveReason(Reason reason) async {
    try {
      await db
          .into(db.reasonsTable)
          .insertOnConflictUpdate(reason.toCompanion());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> renameReason(String id, String name) async {
    try {
      await (db.update(db.reasonsTable)..where((t) => t.reasonId.equals(id)))
          .write(ReasonsTableCompanion(name: Value(name)));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
