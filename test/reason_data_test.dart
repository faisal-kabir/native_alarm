import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:eala/core/database/app_database.dart';
import 'package:eala/core/usecase/usecase.dart';
import 'package:eala/features/reasons/data/datasources/reason_local_data_source.dart';
import 'package:eala/features/reasons/data/repositories/reason_repository_impl.dart';
import 'package:eala/features/reasons/domain/entities/reason.dart';
import 'package:eala/features/reasons/domain/usecases/get_reasons_usecase.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_bloc.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_event.dart';
import 'package:eala/features/reasons/presentation/bloc/reasons_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late GetReasonsUseCase useCase;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    useCase = GetReasonsUseCase(
      ReasonRepositoryImpl(ReasonLocalDataSourceImpl(db)),
    );
  });

  tearDown(() => db.close());

  Future<void> insert(
    String id,
    String name,
    String area,
    int? color,
    String tone,
    int minute,
  ) {
    return db
        .into(db.reasonsTable)
        .insert(
          ReasonsTableCompanion.insert(
            reasonId: id,
            name: name,
            areaName: area,
            areaColor: Value(color),
            toneName: tone,
            createdAt: Value(DateTime(2026, 11, 5, 4, minute)),
          ),
        );
  }

  test("reasons load with the server's area and tone, oldest first", () async {
    await insert('b', 'Second', 'Area B', null, 'Tone B', 5);
    await insert('a', 'First', 'Area A', 0xFF112233, 'Tone A', 1);

    final result = await useCase(NoParams());

    expect(result.getOrElse(() => []), const [
      Reason(
        id: 'a',
        name: 'First',
        areaName: 'Area A',
        areaColor: 0xFF112233,
        toneName: 'Tone A',
      ),
      Reason(id: 'b', name: 'Second', areaName: 'Area B', toneName: 'Tone B'),
    ]);
  });

  test(
    'ReasonsBloc emits loading then the loaded list (empty is valid)',
    () async {
      final bloc = ReasonsBloc(useCase)..add(const LoadReasonsEvent());
      final states = await bloc.stream.take(2).toList();
      expect(states.first, isA<ReasonsLoading>());
      expect((states.last as ReasonsLoaded).reasons, isEmpty);
      await bloc.close();
    },
  );
}
