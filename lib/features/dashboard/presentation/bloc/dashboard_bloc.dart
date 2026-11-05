import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/firebase/analytics_service.dart';
import '../../../../core/notification/fcm_token.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/device_info.dart';
import '../../../auth/domain/usecases/ensure_signed_in_usecase.dart';
import '../../../auth/domain/usecases/sync_user_profile_usecase.dart';
import '../../../auth/domain/usecases/update_device_info_usecase.dart';
import '../../../settings/domain/usecases/get_app_info_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// The mother screen's own work: which tab is showing (and logging it to Analytics),
/// and keeping the Supabase session and the user's server row alive while the app
/// runs. The tabs' data lives in their features (My Alarms, Reasons, Settings).
@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  /// Analytics screen names, in tab order.
  static const List<String> screenNames = ['my_alarms', 'reasons', 'settings'];

  final AnalyticsService analytics;
  final EnsureSignedInUseCase ensureSignedInUseCase;
  final SyncUserProfileUseCase syncUserProfileUseCase;
  final UpdateDeviceInfoUseCase updateDeviceInfoUseCase;
  final GetAppInfoUseCase getAppInfoUseCase;

  StreamSubscription<String>? _tokenSubscription;

  DashboardBloc(
    this.analytics,
    this.ensureSignedInUseCase,
    this.syncUserProfileUseCase,
    this.updateDeviceInfoUseCase,
    this.getAppInfoUseCase,
  ) : super(const DashboardState()) {
    on<DashboardTabChangedEvent>((event, emit) {
      analytics.logScreen(screenNames[event.index]);
      emit(DashboardState(selectedIndex: event.index));
    });
    on<EnsureSessionEvent>(_onEnsureSession);
    on<FcmTokenChangedEvent>((event, emit) => _updateDeviceInfo());

    // The token usually arrives after the session is ready, and Firebase refreshes it
    // from time to time: either way the server row has to follow.
    _tokenSubscription = fcmTokenChanges.listen(
      (_) => add(const FcmTokenChangedEvent()),
    );
  }

  Future<void> _onEnsureSession(
    EnsureSessionEvent event,
    Emitter<DashboardState> emit,
  ) async {
    final session = await ensureSignedInUseCase(NoParams());
    // Offline on first launch: nothing to do now, it is retried on the next resume.
    final user = session.fold((failure) {
      debugPrint('Supabase session not ready: ${failure.message}');
      return null;
    }, (user) => user);
    if (user == null) return;
    debugPrint('Supabase user ${user.id} (anonymous: ${user.isAnonymous})');

    // Keep a fresh copy of the user's row on the device; on failure the previous
    // copy (if any) stays available.
    final profile = await syncUserProfileUseCase(NoParams());
    profile.fold(
      (failure) => debugPrint('User profile not synced: ${failure.message}'),
      (profile) => debugPrint('User profile saved (id ${profile.id})'),
    );

    await _updateDeviceInfo();
  }

  /// Sends platform, app version and FCM token to the server when any of them differs
  /// from what the row holds (the repository skips the request otherwise).
  Future<void> _updateDeviceInfo() async {
    final appInfo = (await getAppInfoUseCase(NoParams()))
        .fold((_) => null, (info) => info);
    if (appInfo == null) return;

    final result = await updateDeviceInfoUseCase(
      DeviceInfo(
        platform: Platform.isIOS ? 'ios' : 'android',
        appVersion: '${appInfo.version}+${appInfo.build}',
        fcmToken: fcmToken,
      ),
    );
    result.fold(
      (failure) => debugPrint('Device info not saved: ${failure.message}'),
      (profile) => debugPrint(
        'Device info up to date (${profile.platform}, ${profile.appVersion}, '
        'token ${profile.fcmToken == null ? 'none' : 'saved'})',
      ),
    );
  }

  @override
  Future<void> close() {
    _tokenSubscription?.cancel();
    return super.close();
  }
}
