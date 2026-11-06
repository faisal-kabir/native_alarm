import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/add_card.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../main.dart';
import '../../domain/entities/reason.dart';
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

  /// Ids in the list as first loaded, plus every one shown since.
  Set<String>? _known;

  /// Reasons added after the first load (a just-created one) that have not risen in
  /// yet. They wait, invisible but holding their place, until this screen is on top
  /// again (the ready screen is popped), then rise in once.
  final Set<String> _fresh = {};

  void _track(List<Reason> reasons) {
    final known = _known;
    if (known == null) {
      _known = {for (final r in reasons) r.id};
      return;
    }
    for (final r in reasons) {
      if (known.add(r.id)) _fresh.add(r.id);
    }
  }

  Widget _row(Reason reason, bool onTop) {
    final row = ReasonRow(reason: reason);
    if (!_fresh.contains(reason.id)) {
      return RiseIn(key: ValueKey(reason.id), enabled: false, child: row);
    }
    if (!onTop) return Opacity(opacity: 0, child: row);
    // First build on top: start the rise; later builds keep the same element.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fresh.remove(reason.id),
    );
    return RiseIn(
      key: ValueKey(reason.id),
      delay: const Duration(milliseconds: 250),
      dy: 14,
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = appLanguage(context);
    // Rebuilds when another route covers or uncovers the dashboard.
    final onTop = ModalRoute.of(context)?.isCurrent ?? true;
    return SafeArea(
      bottom: false,
      child: BlocBuilder<ReasonsBloc, ReasonsState>(
        builder: (context, state) {
          final loaded = state is ReasonsLoaded ? state : null;
          final reasons = loaded?.reasons ?? const <Reason>[];
          if (loaded != null) _track(reasons);
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
                _row(reason, onTop),
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
