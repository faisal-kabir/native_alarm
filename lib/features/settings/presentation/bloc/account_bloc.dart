import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../auth/domain/entities/auth_provider.dart';
import '../../../auth/domain/usecases/get_cached_user_profile_usecase.dart';
import '../../../auth/domain/usecases/sign_in_with_provider_usecase.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import '../../../auth/domain/usecases/update_user_name_usecase.dart';
import '../../../auth/domain/usecases/watch_auth_user_usecase.dart';
import 'account_event.dart';
import 'account_state.dart';

/// Who the person is, for every screen that says it: the Settings card, its Account rows
/// and the Profile screen. One shared instance, so a name saved on Profile shows on
/// Settings at once and a sign-in anywhere is seen everywhere.
@lazySingleton
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final WatchAuthUserUseCase watchAuthUserUseCase;
  final GetCachedUserProfileUseCase getCachedUserProfileUseCase;
  final UpdateUserNameUseCase updateUserNameUseCase;
  final SignInWithProviderUseCase signInWithProviderUseCase;
  final SignOutUseCase signOutUseCase;

  bool _started = false;

  AccountBloc(
    this.watchAuthUserUseCase,
    this.getCachedUserProfileUseCase,
    this.updateUserNameUseCase,
    this.signInWithProviderUseCase,
    this.signOutUseCase,
  ) : super(const AccountState()) {
    on<AccountStartedEvent>(_onStarted);
    on<AccountNameSavedEvent>(_onNameSaved);
    on<AccountSignInRequestedEvent>(_onSignIn);
    on<AccountSignOutRequestedEvent>(_onSignOut);
  }

  Future<void> _onStarted(
    AccountStartedEvent event,
    Emitter<AccountState> emit,
  ) async {
    if (_started) return;
    _started = true;
    // The saved name first (it is on the device), then follow the session.
    final cached = await getCachedUserProfileUseCase(NoParams());
    final profile = cached.fold((_) => null, (profile) => profile);
    emit(
      state.copyWith(
        name: (profile?.name ?? '').trim(),
        lastProvider: () => AuthProvider.fromValue(profile?.primaryProvider),
        loaded: true,
      ),
    );
    await emit.forEach(
      watchAuthUserUseCase(),
      onData: (user) => state.copyWith(user: () => user),
      onError: (_, _) => state,
    );
  }

  Future<void> _onNameSaved(
    AccountNameSavedEvent event,
    Emitter<AccountState> emit,
  ) async {
    final name = event.name.trim();
    if (!isValidName(name) || name == state.name || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await updateUserNameUseCase(name);
    emit(
      result.fold(
        (_) => state.copyWith(busy: false, notice: AccountNotice.nameFailed),
        (profile) =>
            state.copyWith(busy: false, name: (profile.name ?? name).trim()),
      ),
    );
  }

  Future<void> _onSignIn(
    AccountSignInRequestedEvent event,
    Emitter<AccountState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await signInWithProviderUseCase(event.provider);
    result.fold((failure) {
      if (failure is! CancelledFailure) {
        debugPrint('Sign-in failed: ${failure.message}');
      }
    }, (_) {});
    final profile = (await getCachedUserProfileUseCase(NoParams()))
        .fold((_) => null, (p) => p);
    emit(
      result.fold(
        (failure) => state.copyWith(
          busy: false,
          // Closing the sheet is a choice, not an error.
          notice: switch (failure) {
            CancelledFailure() => AccountNotice.none,
            _ => AccountNotice.signInFailed,
          },
        ),
        (user) => state.copyWith(
          user: () => user,
          busy: false,
          name: (profile?.name ?? state.name).trim(),
          // The provider just used; the profile has it too unless saving it failed.
          lastProvider: () => user.provider,
        ),
      ),
    );
  }

  Future<void> _onSignOut(
    AccountSignOutRequestedEvent event,
    Emitter<AccountState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await signOutUseCase(NoParams());
    emit(
      result.fold(
        (_) => state.copyWith(busy: false, notice: AccountNotice.signOutFailed),
        (user) => state.copyWith(
          user: () => user,
          busy: false,
          lastProvider: () => null,
        ),
      ),
    );
  }
}
