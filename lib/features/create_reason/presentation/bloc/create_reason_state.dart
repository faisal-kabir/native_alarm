import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../area_of_life/domain/entities/area_of_life.dart';

/// Where the list of areas of life stands (only matters while there are no areas to
/// show).
enum AreasStatus {
  /// Waiting for the first answer from the server.
  loading,

  /// The server answered and the areas are up to date.
  loaded,

  /// The server could not be reached and nothing is saved on the device.
  failed,
}

/// Everything the Create Reason flow collects, step by step, in one place: the mother
/// page's BLoC keeps it all so the last step can save the reason in one go.
class CreateReasonState extends Equatable {
  /// 0-based index of the step showing now.
  final int stepIndex;

  /// Step 1 data: the areas of life (saved copy, live) and the user's choice.
  final List<AreaOfLife> areas;
  final AreasStatus areasStatus;
  final int? selectedAreaId;

  const CreateReasonState({
    this.stepIndex = 0,
    this.areas = const [],
    this.areasStatus = AreasStatus.loading,
    this.selectedAreaId,
  });

  AreaOfLife? get selectedArea {
    for (final area in areas) {
      if (area.id == selectedAreaId) return area;
    }
    return null;
  }

  /// Whether the current step is complete, so "Continue" is enabled.
  bool get canContinue => switch (stepIndex) {
    0 => selectedArea != null,
    _ => false,
  };

  /// How far through the flow the current step is, 0..1 (for the top progress bar).
  double get progress => (stepIndex + 1) / AppConstant.createReasonStepCount;

  CreateReasonState copyWith({
    int? stepIndex,
    List<AreaOfLife>? areas,
    AreasStatus? areasStatus,
    int? Function()? selectedAreaId,
  }) => CreateReasonState(
    stepIndex: stepIndex ?? this.stepIndex,
    areas: areas ?? this.areas,
    areasStatus: areasStatus ?? this.areasStatus,
    selectedAreaId: selectedAreaId == null
        ? this.selectedAreaId
        : selectedAreaId(),
  );

  @override
  List<Object?> get props => [stepIndex, areas, areasStatus, selectedAreaId];
}
