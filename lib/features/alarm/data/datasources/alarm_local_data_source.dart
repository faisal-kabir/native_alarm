import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';

import '../../../../core/error/exceptions.dart';
import '../models/alarm_isar_model.dart';

abstract class AlarmLocalDataSource {
  Future<List<AlarmIsarModel>> getAlarms();
  Future<void> saveAlarm(AlarmIsarModel alarm);
  Future<void> deleteAlarm(String alarmId);
}

@LazySingleton(as: AlarmLocalDataSource)
class AlarmLocalDataSourceImpl implements AlarmLocalDataSource {
  final Isar isar;

  AlarmLocalDataSourceImpl(this.isar);

  @override
  Future<List<AlarmIsarModel>> getAlarms() async {
    try {
      return await isar.alarmIsarModels.where().sortByTime().findAll();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> saveAlarm(AlarmIsarModel alarm) async {
    try {
      // Unique index on alarmId with replace: true turns this into an upsert.
      await isar.writeTxn(() => isar.alarmIsarModels.putByAlarmId(alarm));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteAlarm(String alarmId) async {
    try {
      await isar.writeTxn(() => isar.alarmIsarModels.deleteByAlarmId(alarmId));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
