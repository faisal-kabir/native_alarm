import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/matter_suggestion.dart';
import '../repositories/area_of_life_repository.dart';

class MatterSuggestionsParams extends Equatable {
  final int areaId;

  /// The picked (unchanged) purpose suggestion, or null when the user wrote their own
  /// purpose: then the area's suggestions without a purpose suggestion are loaded.
  final int? purposeSuggestionId;

  const MatterSuggestionsParams(this.areaId, this.purposeSuggestionId);

  @override
  List<Object?> get props => [areaId, purposeSuggestionId];
}

/// Loads the "why it matters" suggestions from the server. Fully dynamic: nothing is
/// saved on the device, every call asks the server.
@lazySingleton
class GetMatterSuggestionsUseCase
    implements UseCase<List<MatterSuggestion>, MatterSuggestionsParams> {
  final AreaOfLifeRepository repository;

  GetMatterSuggestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MatterSuggestion>>> call(
    MatterSuggestionsParams params,
  ) => repository.getMatterSuggestions(
    params.areaId,
    params.purposeSuggestionId,
  );
}
