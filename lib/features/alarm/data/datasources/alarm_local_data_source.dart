import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/alarm.dart';
import '../models/alarms_table.dart';

abstract class AlarmLocalDataSource {
  Future<List<AlarmRecord>> getAlarms();

  /// The saved alarms now and after every change.
  Stream<List<AlarmRecord>> watchAlarms();
  Future<void> saveAlarm(Alarm alarm);
  Future<void> deleteAlarm(String alarmId);
}

@LazySingleton(as: AlarmLocalDataSource)
class AlarmLocalDataSourceImpl implements AlarmLocalDataSource {
  final AppDatabase db;

  AlarmLocalDataSourceImpl(this.db);

  @override
  Future<List<AlarmRecord>> getAlarms() async {
    try {
      return await (db.select(
        db.alarmsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.time)])).get();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Stream<List<AlarmRecord>> watchAlarms() => (db.select(
    db.alarmsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.time)])).watch();

  @override
  Future<void> saveAlarm(Alarm alarm) async {
    try {
      // Primary key is alarmId, so saving the same alarm again updates its row.
      await db.into(db.alarmsTable).insertOnConflictUpdate(alarm.toCompanion());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteAlarm(String alarmId) async {
    try {
      await (db.delete(
        db.alarmsTable,
      )..where((t) => t.alarmId.equals(alarmId))).go();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
