import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/supabase/own_user_id.dart';
import '../../../alarm/domain/entities/alarm.dart';
import '../../../reasons/data/models/reason_model.dart';
import '../models/alarm_server_model.dart';

abstract class AlarmRemoteDataSource {
  /// Puts [alarm] on the server for the signed-in user: its first schedule as an
  /// `alarm` row, the others as `sub_alarm` rows pointing at it, and its Reason's
  /// `alarm_id` set to it. Answers the new row with everything it points at
  /// ([alarmSelect]). When any step fails, what was already written is removed, so no
  /// half-made alarm stays; throws [ServerException].
  Future<Map<String, dynamic>> insertAlarm(Alarm alarm, DateTime now);

  /// Removes alarm [id] from the server: its `sub_alarm` rows (every row with this
  /// `alarm_id`), its Reason's link and the row itself, each checked to have really
  /// gone. Answers the Reasons it freed, as rows ([reasonSelect]). Throws
  /// [ServerException] when the server keeps any of them; the alarm and its Reason's
  /// link then stay as they were.
  Future<List<Map<String, dynamic>>> deleteAlarm(int id);

  /// Writes the edited [alarm] over its server copy (it had [old]'s values): the
  /// `alarm` row (its first schedule and every choice), its `sub_alarm` rows replaced
  /// by its other schedules, and, when the Reason changed, the old Reason's
  /// `alarm_id` cleared and the new one's set. Answers the row with everything it
  /// points at ([alarmSelect]) and the Reason it freed (rows, [reasonSelect]). When a
  /// step fails, [old] is written back as well as the server allows; throws
  /// [ServerException].
  Future<({Map<String, dynamic> alarm, List<Map<String, dynamic>> freed})>
  updateAlarm(Alarm old, Alarm alarm, DateTime now);
}

@LazySingleton(as: AlarmRemoteDataSource)
class AlarmRemoteDataSourceImpl implements AlarmRemoteDataSource {
  final SupabaseClient client;
  final OwnUserId ownUserId;

  AlarmRemoteDataSourceImpl(this.client, this.ownUserId);

  @override
  Future<Map<String, dynamic>> insertAlarm(Alarm alarm, DateTime now) async {
    final userId = await ownUserId();
    final schedules = serverSchedules(alarm, now);
    int? id;
    try {
      final row = await client
          .from('alarm')
          .insert(alarmColumns(alarm, userId, schedules.first))
          .select('id')
          .single();
      id = (row['id'] as num).toInt();
      if (schedules.length > 1) {
        await client.from('sub_alarm').insert([
          for (final s in schedules.skip(1))
            {'alarm_id': id, ...scheduleColumns(s)},
        ]);
      }
      final reasonId = alarm.reasonId;
      if (reasonId != null) {
        // `select` returns the rows really changed: row-level security that does not
        // allow it changes nothing and reports no error.
        final linked = await client
            .from('reason')
            .update({'alarm_id': id})
            .eq('id', reasonId)
            .select('id');
        if (linked.isEmpty) throw const ServerException('Reason not linked');
      }
      return await client
          .from('alarm')
          .select(alarmSelect)
          .eq('id', id)
          .single();
    } catch (e) {
      if (id != null) await _deleteQuietly(id);
      throw e is ServerException ? e : ServerException(e.toString());
    }
  }

  @override
  Future<({Map<String, dynamic> alarm, List<Map<String, dynamic>> freed})>
  updateAlarm(Alarm old, Alarm alarm, DateTime now) async {
    final id = alarm.remoteId;
    if (id == null) throw const ServerException('Alarm not on the server');
    try {
      final freed = await _write(id, old, alarm, now);
      final json = await client
          .from('alarm')
          .select(alarmSelect)
          .eq('id', id)
          .single();
      return (alarm: json, freed: freed);
    } catch (e) {
      // Put the server's copy back as it was (a failure here leaves what it could).
      try {
        await _write(id, alarm, old, now);
      } catch (_) {}
      throw e is ServerException ? e : ServerException(e.toString());
    }
  }

  /// Writes [to] over alarm [id], which held [from]; answers the Reasons it freed.
  /// Every write asks for the rows it really changed: row-level security that does
  /// not allow it changes nothing and reports no error.
  Future<List<Map<String, dynamic>>> _write(
    int id,
    Alarm from,
    Alarm to,
    DateTime now,
  ) async {
    final schedules = serverSchedules(to, now);
    final updated = await client
        .from('alarm')
        .update({
          ...alarmUpdateColumns(to, schedules.first),
          'updated_at': now.toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('id');
    if (updated.isEmpty) throw const ServerException('Alarm not updated');

    // Its other schedules: the old rows go, the new ones are written.
    await _deleteSubAlarms(id);
    if (schedules.length > 1) {
      await client.from('sub_alarm').insert([
        for (final s in schedules.skip(1))
          {'alarm_id': id, ...scheduleColumns(s)},
      ]);
    }

    if (from.reasonId == to.reasonId) return const [];
    final oldReason = from.reasonId;
    final freed = oldReason == null
        ? const <Map<String, dynamic>>[]
        : await client
              .from('reason')
              .update({'alarm_id': null})
              .eq('id', oldReason)
              .eq('alarm_id', id)
              .select(reasonSelect);
    final newReason = to.reasonId;
    if (newReason != null) {
      final linked = await client
          .from('reason')
          .update({'alarm_id': id})
          .eq('id', newReason)
          .select('id');
      if (linked.isEmpty) throw const ServerException('Reason not linked');
    }
    return freed;
  }

  /// Removes every `sub_alarm` row of alarm [id], checking they really went (a delete
  /// row-level security refuses removes nothing and reports no error).
  Future<void> _deleteSubAlarms(int id) async {
    final subs = await client.from('sub_alarm').select('id').eq('alarm_id', id);
    if (subs.isEmpty) return;
    final gone = await client
        .from('sub_alarm')
        .delete()
        .eq('alarm_id', id)
        .select('id');
    if (gone.length < subs.length) {
      throw const ServerException('Sub alarms not deleted');
    }
  }

  // Every delete asks for the rows it really removed (`select`): row-level security
  // that does not allow a delete removes nothing and reports no error, which would
  // leave rows behind unseen.
  @override
  Future<List<Map<String, dynamic>>> deleteAlarm(int id) async {
    try {
      // Its other schedules first: if they can not go, nothing has changed yet.
      await _deleteSubAlarms(id);

      // `reason.alarm_id` points at the alarm, so the link goes before the row.
      final freed = await client
          .from('reason')
          .update({'alarm_id': null})
          .eq('alarm_id', id)
          .select(reasonSelect);
      try {
        final deleted = await client
            .from('alarm')
            .delete()
            .eq('id', id)
            .select('id');
        if (deleted.isEmpty && await _exists(id)) {
          throw const ServerException('Alarm not deleted');
        }
      } catch (_) {
        // The alarm stays: its Reasons stay linked to it.
        for (final row in freed) {
          await client
              .from('reason')
              .update({'alarm_id': id})
              .eq('id', row['id'] as Object);
        }
        rethrow;
      }
      return freed;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<bool> _exists(int id) async =>
      (await client.from('alarm').select('id').eq('id', id)).isNotEmpty;

  /// Undoing a failed insert: a failure here leaves nothing more to do.
  Future<void> _deleteQuietly(int id) async {
    try {
      await deleteAlarm(id);
    } on ServerException {
      // The row stays on the server; the device keeps no reference to it.
    }
  }
}
