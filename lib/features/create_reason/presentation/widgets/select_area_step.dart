import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/animated_select_list.dart';
import '../../../../core/widgets/highlighted_title.dart';
import '../../../../core/widgets/select_list_skeleton.dart';
import '../../../../main.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import 'step_message.dart';

/// Step 1 of Create Reason: "What do you want to wake up for?" - the areas of life,
/// from the saved copy (so it opens at once, offline too) while the server update runs
/// behind it. The very first time, with nothing saved yet, a shimmer skeleton shows.
class SelectAreaStep extends StatelessWidget {
  const SelectAreaStep({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    return BlocBuilder<CreateReasonBloc, CreateReasonState>(
      buildWhen: (a, b) =>
          a.areas != b.areas ||
          a.areasStatus != b.areasStatus ||
          a.selectedAreaId != b.selectedAreaId,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: REdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HighlightedTitle(strings.create_reason_area_title),
              SizedBox(height: 18.h),
              if (state.areas.isNotEmpty)
                AnimatedSelectList(
                  items: [
                    for (final area in state.areas)
                      SelectItem(
                        id: area.id,
                        title: area.title,
                        subtitle: area.description,
                        tint: Color(area.color ?? AppColor.primary.toARGB32()),
                        iconPath: area.icon,
                      ),
                  ],
                  selectedId: state.selectedAreaId,
                  onSelected: (item) => context.read<CreateReasonBloc>().add(
                    AreaSelectedEvent(item.id as int),
                  ),
                )
              else
                switch (state.areasStatus) {
                  LoadStatus.loading => const SelectListSkeleton(),
                  LoadStatus.failed => StepMessage(
                    text: strings.create_reason_areas_error,
                    actionLabel: strings.common_try_again,
                    onAction: () => context.read<CreateReasonBloc>().add(
                      const RefreshAreasEvent(),
                    ),
                  ),
                  LoadStatus.loaded => StepMessage(
                    text: strings.create_reason_areas_empty,
                  ),
                },
            ],
          ),
        );
      },
    );
  }
}
