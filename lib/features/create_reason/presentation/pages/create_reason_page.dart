import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/step_top_bar.dart';
import '../../../../main.dart';
import '../bloc/create_reason_bloc.dart';
import '../bloc/create_reason_event.dart';
import '../bloc/create_reason_state.dart';
import '../widgets/matter_step.dart';
import '../widgets/purpose_step.dart';
import '../widgets/select_area_step.dart';
import '../widgets/select_sound_step.dart';
import '../widgets/select_voice_step.dart';

/// The mother page of the Create Reason flow. It owns the top progress bar, the
/// "Continue" button and a PageView whose pages are the steps, in order; every step's
/// data lives in [CreateReasonBloc], which saves the reason after the last step.
///
/// To add a step: build its page widget, append it to [_steps], raise
/// `AppConstant.createReasonStepCount`, name its index in `CreateReasonState` and give
/// `CreateReasonState.canContinue` a case.
class CreateReasonPage extends StatelessWidget {
  const CreateReasonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => instance<CreateReasonBloc>()
        ..add(const LoadAreasEvent())
        ..add(const LoadVoicesEvent())
        ..add(const LoadSoundTypesEvent()),
      child: const _CreateReasonView(),
    );
  }
}

class _CreateReasonView extends StatefulWidget {
  const _CreateReasonView();

  @override
  State<_CreateReasonView> createState() => _CreateReasonViewState();
}

class _CreateReasonViewState extends State<_CreateReasonView> {
  /// The step pages, in order.
  static const List<Widget> _steps = [
    SelectAreaStep(),
    PurposeStep(),
    SelectVoiceStep(),
    MatterStep(),
    SelectSoundStep(),
  ];

  final PageController _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// The reason is saved: the ready screen takes this page's place, so back from it
  /// lands on the reasons list, not on a finished form.
  void _openReady(BuildContext context, CreateReasonState state) {
    final reason = state.createdReason;
    if (reason == null) return;
    context.pushReplacement(RouteNames.reasonReadyPath, extra: reason);
  }

  @override
  Widget build(BuildContext context) {
    final strings = appLanguage(context);
    final bloc = context.read<CreateReasonBloc>();
    return BlocConsumer<CreateReasonBloc, CreateReasonState>(
      listenWhen: (a, b) =>
          a.stepIndex != b.stepIndex || a.saveStatus != b.saveStatus,
      listener: (context, state) {
        switch (state.saveStatus) {
          case SaveStatus.saved:
            _openReady(context, state);
          case SaveStatus.failed:
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(strings.reason_save_failed)));
          case SaveStatus.idle || SaveStatus.saving:
            _pages.animateToPage(
              state.stepIndex,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
        }
      },
      buildWhen: (a, b) =>
          a.stepIndex != b.stepIndex ||
          a.canContinue != b.canContinue ||
          a.continueSkips != b.continueSkips ||
          a.isLastStep != b.isLastStep ||
          a.saveStatus != b.saveStatus,
      builder: (context, state) {
        final first = state.stepIndex == CreateReasonState.areaStep;
        return PopScope(
          // The system back gesture goes one step back; only the first step closes.
          canPop: first,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) bloc.add(const PreviousStepEvent());
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  StepTopBar(
                    progress: state.progress,
                    onBack: () => first
                        ? context.pop()
                        : bloc.add(const PreviousStepEvent()),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _steps,
                    ),
                  ),
                  Padding(
                    padding: REdgeInsets.fromLTRB(24, 10, 24, 8),
                    child: PillButton(
                      label: state.continueSkips
                          ? strings.common_skip_for_now
                          : !state.isLastStep
                          ? strings.common_continue
                          : state.saveStatus == SaveStatus.saving
                          ? strings.common_saving
                          : strings.create_reason_create,
                      quiet: state.continueSkips,
                      enabled: state.canContinue,
                      onPressed: () => bloc.add(
                        state.isLastStep
                            ? const CreateReasonSubmittedEvent()
                            : const NextStepEvent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
