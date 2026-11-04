import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/reason.dart';
import '../../domain/repositories/reason_repository.dart';
import '../datasources/reason_local_data_source.dart';
import '../models/reasons_table.dart';

@LazySingleton(as: ReasonRepository)
class ReasonRepositoryImpl implements ReasonRepository {
  final ReasonLocalDataSource localDataSource;

  ReasonRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Reason>>> getReasons() async {
    try {
      final records = await localDataSource.getReasons();
      return Right(records.map((r) => r.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
