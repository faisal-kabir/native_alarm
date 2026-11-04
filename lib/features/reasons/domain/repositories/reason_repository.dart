import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/reason.dart';

abstract class ReasonRepository {
  Future<Either<Failure, List<Reason>>> getReasons();
}
