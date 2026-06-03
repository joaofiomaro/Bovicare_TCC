import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/vaccination_local_data_source.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../../domain/usecases/get_animal_vaccinations_use_case.dart';
import '../../domain/usecases/register_vaccination_use_case.dart';

// --- DI ---

final _vaccinationDataSourceProvider = Provider<VaccinationLocalDataSource>(
  (_) => VaccinationLocalDataSource(),
);

final vaccinationRepositoryProvider = Provider<VaccinationRepository>(
  (ref) => VaccinationRepositoryImpl(ref.watch(_vaccinationDataSourceProvider)),
);

// --- Lista de vacinações por animal ---

/// Provider por animalId — autoDispose para não manter cache de animais não visitados.
final vaccinationsProvider = FutureProvider.autoDispose
    .family<List<VaccinationRecord>, String>((ref, animalId) {
  final repo = ref.read(vaccinationRepositoryProvider);
  return GetAnimalVaccinationsUseCase(repo).call(animalId);
});

// --- Notifier para submissão do formulário ---

class VaccinationFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> register(VaccinationRecord record) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(vaccinationRepositoryProvider);
      await RegisterVaccinationUseCase(repo).call(record);
      // Invalida o cache para que a tab Sanitário recarregue.
      ref.invalidate(vaccinationsProvider(record.animalId));
    });
    return !state.hasError;
  }
}

final vaccinationFormProvider =
    AsyncNotifierProvider<VaccinationFormNotifier, void>(
  VaccinationFormNotifier.new,
);
