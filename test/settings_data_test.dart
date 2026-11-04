import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/usecase/usecase.dart';
import 'package:eala/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:eala/features/settings/domain/entities/user_settings.dart';
import 'package:eala/features/settings/presentation/bloc/settings_event.dart';
import 'package:eala/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_alarm_repository.dart';

void main() {
  test('settings default when nothing is saved, then survive a save', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final source = SettingsLocalDataSourceImpl(db);

    expect(await source.getSettings(), const UserSettings());

    await source.saveSettings(
      const UserSettings(
        notifyBilling: false,
        notifyAlarms: true,
        notifyQuotes: true,
      ),
    );
    await source.saveSettings(
      const UserSettings(
        notifyBilling: false,
        notifyAlarms: false,
        notifyQuotes: true,
      ),
    );

    final saved = await source.getSettings();
    expect(saved.notifyBilling, isFalse);
    expect(saved.notifyAlarms, isFalse);
    expect(saved.notifyQuotes, isTrue);
    // Still a single row after saving twice.
    expect((await db.select(db.settingsTable).get()).length, 1);
    await db.close();
  });

  test('SettingsBloc loads, flips a switch at once and saves it', () async {
    final repo = FakeSettingsRepository();
    final bloc = buildSettingsBloc(repo)..add(const LoadSettingsEvent());
    await bloc.stream.firstWhere((s) => s is SettingsLoaded);

    bloc.add(const NotificationToggledEvent(SettingsNotification.quotes, true));
    final toggled = await bloc.stream.firstWhere(
      (s) => s is SettingsLoaded && s.settings.notifyQuotes,
    ) as SettingsLoaded;
    expect(toggled.appInfo?.version, '1.0.0');
    await Future<void>.delayed(Duration.zero);
    expect(repo.saved?.notifyQuotes, isTrue);
    expect(repo.saved?.notifyBilling, isTrue); // untouched choices stay
    await bloc.close();
  });

  test('GetSettings use case needs no params', () async {
    final result = await buildSettingsBloc(FakeSettingsRepository())
        .getSettingsUseCase(NoParams());
    expect(result.isRight(), isTrue);
  });
}
