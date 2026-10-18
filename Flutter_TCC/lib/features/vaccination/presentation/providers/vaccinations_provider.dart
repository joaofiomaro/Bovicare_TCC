import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/datasources/vaccination_firestore_data_source.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../domain/entities/vaccination_record.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../../domain/usecases/get_animal_vaccinations_use_case.dart';
import '../../domain/usecases/register_vaccination_use_case.dart';

// --- DI ---

final _vaccinationDataSourceProvider = Provider<VaccinationFirestoreDataSource>(
  (_) => VaccinationFirestoreDataSource(),
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

/// Todas as vacinações do usuário — base de alertas (dose/carência).
final allVaccinationsProvider = FutureProvider<List<VaccinationRecord>>((ref) {
  return ref.read(vaccinationRepositoryProvider).getAll();
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
      ref
        ..invalidate(vaccinationsProvider(record.animalId))
        ..invalidate(allVaccinationsProvider)
        ..invalidate(dashboardProvider);
    });
    return !state.hasError;
  }
}

final vaccinationFormProvider =
    AsyncNotifierProvider<VaccinationFormNotifier, void>(
  VaccinationFormNotifier.new,
);
