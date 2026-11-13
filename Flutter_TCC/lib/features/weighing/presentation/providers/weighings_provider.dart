import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../herd/presentation/providers/animals_provider.dart';

import '../../data/datasources/weighing_firestore_data_source.dart';
import '../../data/repositories/weighing_repository_impl.dart';
import '../../domain/entities/weighing.dart';
import '../../domain/repositories/weighing_repository.dart';
import '../../domain/usecases/get_animal_weighings_use_case.dart';
import '../../domain/usecases/register_weighing_use_case.dart';

// --- DI ---

final _weighingDataSourceProvider = Provider<WeighingFirestoreDataSource>(
  (_) => WeighingFirestoreDataSource(),
);

final weighingRepositoryProvider = Provider<WeighingRepository>(
  (ref) => WeighingRepositoryImpl(ref.watch(_weighingDataSourceProvider)),
);

// --- Pesagens de um animal ---

/// Histórico de pesagens por animal — autoDispose para não reter cache
/// de animais não visitados.
final animalWeighingsProvider = FutureProvider.autoDispose
    .family<List<Weighing>, String>((ref, animalId) {
  final repo = ref.read(weighingRepositoryProvider);
  return GetAnimalWeighingsUseCase(repo).call(animalId);
});

// --- Submissão do formulário de pesagem ---

class WeighingFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Registra a pesagem. Retorna `false` em caso de falha.
  Future<bool> register(Weighing weighing) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(weighingRepositoryProvider);
      await RegisterWeighingUseCase(repo).call(weighing);
      // A pesagem também atualiza o peso atual do animal (mesmo batch no
      // Firestore): recarrega histórico, ficha, lista do rebanho e dashboard
      // para que o novo peso apareça em todas as telas.
      ref
        ..invalidate(animalWeighingsProvider(weighing.animalId))
        ..invalidate(animalDetailProvider(weighing.animalId))
        ..invalidate(animalsProvider)
        ..invalidate(dashboardProvider);
    });
    return !state.hasError;
  }
}

final weighingFormProvider =
    AsyncNotifierProvider<WeighingFormNotifier, void>(
  WeighingFormNotifier.new,
);
