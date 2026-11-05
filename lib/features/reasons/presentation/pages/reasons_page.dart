import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/add_card.dart';
import '../../../../main.dart';
import '../bloc/reasons_bloc.dart';
import '../bloc/reasons_event.dart';
import '../bloc/reasons_state.dart';
import '../widgets/reason_row.dart';

/// The "Reasons" tab of the Dashboard.
class ReasonsPage extends StatelessWidget {
  const ReasonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          instance<ReasonsBloc>()..add(const LoadReasonsEvent()),
      child: const _ReasonsView(),
    );
  }
}

class _ReasonsView extends StatefulWidget {
  const _ReasonsView();

  @override
  State<_ReasonsView> createState() => _ReasonsViewState();
}

class _ReasonsViewState extends State<_ReasonsView>
    with AutomaticKeepAliveClientMixin {
  // Keeps the page (and its BLoC) alive while another Dashboard tab is shown.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = appLanguage(context);
    return SafeArea(
      bottom: false,
      child: BlocBuilder<ReasonsBloc, ReasonsState>(
        builder: (context, state) {
          final loaded = state is ReasonsLoaded ? state : null;
          final reasons = loaded?.reasons ?? const [];
          return ListView(
            // Bottom padding lets the last row scroll clear of the tab bar.
            padding: REdgeInsets.fromLTRB(24, 14, 24, 100),
            children: [
              SizedBox(
                height: 40.8.h,
                child: Text(
                  strings.reasons_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appTheme(context).textTheme.headlineLarge,
                ),
              ),
              SizedBox(height: 24.h),
              for (final reason in reasons) ...[
                ReasonRow(reason: reason),
                SizedBox(height: 10.h),
              ],
              if (loaded != null)
                AddCard(
                  first: reasons.isEmpty,
                  title: strings.reasons_add_first_title,
                  subtitle: strings.reasons_add_first_subtitle,
                  label: strings.reasons_add_label,
                  onTap: () => context.push(RouteNames.createReasonPath),
                ),
            ],
          );
        },
      ),
    );
  }
}
