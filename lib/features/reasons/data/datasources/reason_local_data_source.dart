import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../models/reasons_table.dart';

abstract class ReasonLocalDataSource {
  /// The saved reasons, oldest first; emits again after every change.
  Stream<List<ReasonRecord>> watchReasons();

  /// One saved reason (null when there is none with [id]); emits on every change.
  Stream<ReasonRecord?> watchReason(int id);

  /// Adds or replaces one server row (with its joins).
  Future<void> saveRow(Map<String, dynamic> row);

  /// Makes the device's copy match the server's [rows]: adds and updates them,
  /// removes the rest, in one transaction.
  Future<void> replaceAll(List<Map<String, dynamic>> rows);

  Future<void> deleteRow(int id);
}

@LazySingleton(as: ReasonLocalDataSource)
class ReasonLocalDataSourceImpl implements ReasonLocalDataSource {
  final AppDatabase db;

  ReasonLocalDataSourceImpl(this.db);

  @override
  Stream<List<ReasonRecord>> watchReasons() =>
      (db.select(db.reasonsTable)..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .watch();

  @override
  Stream<ReasonRecord?> watchReason(int id) => (db.select(
    db.reasonsTable,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  @override
  Future<void> saveRow(Map<String, dynamic> row) async {
    try {
      await db
          .into(db.reasonsTable)
          .insertOnConflictUpdate(reasonRowCompanion(row));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> replaceAll(List<Map<String, dynamic>> rows) async {
    try {
      await db.transaction(() async {
        final companions = rows.map(reasonRowCompanion).toList();
        final ids = [for (final c in companions) c.id.value];
        await (db.delete(
          db.reasonsTable,
        )..where((t) => t.id.isNotIn(ids))).go();
        await db.batch(
          (batch) =>
              batch.insertAllOnConflictUpdate(db.reasonsTable, companions),
        );
      });
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteRow(int id) async {
    try {
      await (db.delete(db.reasonsTable)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
