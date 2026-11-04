import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';

abstract class ReasonLocalDataSource {
  Future<List<ReasonRecord>> getReasons();
}

@LazySingleton(as: ReasonLocalDataSource)
class ReasonLocalDataSourceImpl implements ReasonLocalDataSource {
  final AppDatabase db;

  ReasonLocalDataSourceImpl(this.db);

  @override
  Future<List<ReasonRecord>> getReasons() async {
    try {
      return await (db.select(
        db.reasonsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
