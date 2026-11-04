import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_info.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/usecases/get_app_info_usecase.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase getSettingsUseCase;
  final SaveSettingsUseCase saveSettingsUseCase;
  final GetAppInfoUseCase getAppInfoUseCase;

  SettingsBloc(
    this.getSettingsUseCase,
    this.saveSettingsUseCase,
    this.getAppInfoUseCase,
  ) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoad);
    on<NotificationToggledEvent>(_onToggled);
  }

  Future<void> _onLoad(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    final settingsResult = await getSettingsUseCase(NoParams());
    final appInfoResult = await getAppInfoUseCase(NoParams());
    final AppInfo? appInfo = appInfoResult.fold((_) => null, (info) => info);
    settingsResult.fold(
      (failure) => emit(SettingsFailure(failure.message)),
      (settings) => emit(SettingsLoaded(settings, appInfo)),
    );
  }

  Future<void> _onToggled(
    NotificationToggledEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final UserSettings updated = switch (event.notification) {
      SettingsNotification.billing => current.settings.copyWith(
        notifyBilling: event.enabled,
      ),
      SettingsNotification.alarms => current.settings.copyWith(
        notifyAlarms: event.enabled,
      ),
      SettingsNotification.quotes => current.settings.copyWith(
        notifyQuotes: event.enabled,
      ),
    };
    // Show the switch moving right away, then save it.
    emit(SettingsLoaded(updated, current.appInfo));
    final result = await saveSettingsUseCase(updated);
    // If saving failed, put the switch back so the screen shows what is stored.
    result.fold((_) => emit(current), (_) {});
  }
}
