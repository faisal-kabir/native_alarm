import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../alarm/domain/usecases/get_alarms_usecase.dart';
import 'my_alarms_event.dart';
import 'my_alarms_state.dart';

/// The "My Alarms" tab's data. Reuses the alarm feature's [GetAlarmsUseCase]; this
/// screen has no storage of its own.
@injectable
class MyAlarmsBloc extends Bloc<MyAlarmsEvent, MyAlarmsState> {
  final GetAlarmsUseCase getAlarmsUseCase;

  MyAlarmsBloc(this.getAlarmsUseCase) : super(const MyAlarmsInitial()) {
    on<LoadMyAlarmsEvent>(_onLoad);
  }

  Future<void> _onLoad(
    LoadMyAlarmsEvent event,
    Emitter<MyAlarmsState> emit,
  ) async {
    if (state is! MyAlarmsLoaded) emit(const MyAlarmsLoading());
    final result = await getAlarmsUseCase(NoParams());
    result.fold(
      (failure) => emit(MyAlarmsFailure(failure.message)),
      (alarms) => emit(
        MyAlarmsLoaded(
          alarmCount: alarms.length,
          alarmLimit: AppConstant.maxAlarmCount,
        ),
      ),
    );
  }
}
