import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/purpose_suggestion.dart';
import '../repositories/area_of_life_repository.dart';

class PurposeSuggestionsParams extends Equatable {
  final int areaId;

  const PurposeSuggestionsParams(this.areaId);

  @override
  List<Object?> get props => [areaId];
}

/// Loads the purpose suggestions of one area of life from the server. They are fully dynamic, so
/// nothing is saved on the device: every call asks the server.
@lazySingleton
class GetPurposeSuggestionsUseCase
    implements UseCase<List<PurposeSuggestion>, PurposeSuggestionsParams> {
  final AreaOfLifeRepository repository;

  GetPurposeSuggestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PurposeSuggestion>>> call(
    PurposeSuggestionsParams params,
  ) => repository.getPurposeSuggestions(params.areaId);
}
