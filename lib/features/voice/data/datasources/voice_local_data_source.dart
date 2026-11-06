import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../models/voice_model.dart';
import '../models/voices_table.dart';

abstract class VoiceLocalDataSource {
  /// The saved voices, by id; emits again after every change of the table.
  Stream<List<VoiceRecord>> watchVoices();

  /// Makes the saved voices exactly [voices]: rows are added or updated, and rows the
  /// server no longer has are removed, all in one transaction.
  Future<void> replaceAll(List<VoiceModel> voices);
}

@LazySingleton(as: VoiceLocalDataSource)
class VoiceLocalDataSourceImpl implements VoiceLocalDataSource {
  final AppDatabase db;

  VoiceLocalDataSourceImpl(this.db);

  @override
  Stream<List<VoiceRecord>> watchVoices() => (db.select(
    db.voicesTable,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  @override
  Future<void> replaceAll(List<VoiceModel> voices) async {
    try {
      await db.transaction(() async {
        final ids = voices.map((v) => v.id).toList();
        await (db.delete(db.voicesTable)..where((t) => t.id.isNotIn(ids))).go();
        await db.batch(
          (batch) => batch.insertAllOnConflictUpdate(
            db.voicesTable,
            voices.map((v) => v.toCompanion()).toList(),
          ),
        );
      });
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
