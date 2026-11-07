import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/reason.dart';
import '../models/reason_model.dart';
import '../models/reasons_table.dart';

abstract class ReasonLocalDataSource {
  /// The saved reasons, oldest first; emits again after every change.
  Stream<List<ReasonRecord>> watchReasons();

  /// Adds (or replaces) [reason] in the device's copy.
  Future<void> saveReason(Reason reason);

  Future<void> renameReason(String id, String name);

  /// Makes the device's copy match the server's list: adds and updates [reasons],
  /// removes the rest, in one transaction.
  Future<void> replaceAll(List<ReasonModel> reasons);
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

  @override
  Future<void> replaceAll(List<ReasonModel> reasons) async {
    try {
      await db.transaction(() async {
        final ids = reasons.map((r) => r.id).toList();
        await (db.delete(
          db.reasonsTable,
        )..where((t) => t.reasonId.isNotIn(ids))).go();
        await db.batch(
          (batch) => batch.insertAllOnConflictUpdate(
            db.reasonsTable,
            reasons.map((r) => r.toCompanion()).toList(),
          ),
        );
      });
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
