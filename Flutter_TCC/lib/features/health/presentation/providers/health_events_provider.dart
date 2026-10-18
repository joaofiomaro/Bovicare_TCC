import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../data/datasources/health_event_firestore_data_source.dart';
import '../../data/repositories/health_event_repository_impl.dart';
import '../../domain/entities/health_event.dart';
import '../../domain/repositories/health_event_repository.dart';
import '../../domain/usecases/health_event_use_cases.dart';

// --- DI ---

final _healthEventDataSourceProvider =
    Provider<HealthEventFirestoreDataSource>(
  (_) => HealthEventFirestoreDataSource(),
);

final healthEventRepositoryProvider = Provider<HealthEventRepository>(
  (ref) => HealthEventRepositoryImpl(ref.watch(_healthEventDataSourceProvider)),
);

// --- Consultas ---

/// Eventos de manejo de um animal (mais recente primeiro).
final animalHealthEventsProvider = FutureProvider.autoDispose
    .family<List<HealthEvent>, String>((ref, animalId) {
  return ref.read(healthEventRepositoryProvider).getByAnimal(animalId);
});

/// Todos os eventos de manejo do usuário — base de alertas e relatórios.
final allHealthEventsProvider = FutureProvider<List<HealthEvent>>((ref) {
  return ref.read(healthEventRepositoryProvider).getAll();
});

// --- Ações ---

class HealthEventActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  HealthEventRepository get _repo => ref.read(healthEventRepositoryProvider);

  /// Vermifugação, medicação ou observação.
  Future<bool> register(HealthEvent event) => _run(
        event.animalId,
        () => RegisterHealthEventUseCase(_repo).call(event),
      );

  Future<bool> registerPregnancy({
    required AnimalEntity animal,
    required HealthEvent event,
    required DateTime coverageDate,
  }) =>
      _run(
        animal.id,
        () => RegisterPregnancyUseCase(_repo).call(
          animal:       animal,
          event:        event,
          coverageDate: coverageDate,
        ),
        animalChanged: true,
      );

  Future<bool> registerBirth({
    required AnimalEntity mother,
    required HealthEvent event,
    AnimalEntity? calf,
  }) =>
      _run(
        mother.id,
        () => RegisterBirthUseCase(_repo).call(
          mother: mother,
          event:  event,
          calf:   calf,
        ),
        animalChanged: true,
      );

  Future<bool> registerLoss({
    required AnimalEntity mother,
    required HealthEvent event,
  }) =>
      _run(
        mother.id,
        () => RegisterPregnancyLossUseCase(_repo).call(
          mother: mother,
          event:  event,
        ),
        animalChanged: true,
      );

  /// Mensagem amigável do último erro (validação ou Firestore).
  String? get lastErrorMessage {
    final error = state.error;
    if (error == null) return null;
    if (error is ArgumentError) return error.message.toString();
    return error.toString();
  }

  Future<bool> _run(
    String animalId,
    Future<void> Function() action, {
    bool animalChanged = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    if (state.hasError) return false;

    ref
      ..invalidate(animalHealthEventsProvider(animalId))
      ..invalidate(allHealthEventsProvider)
      ..invalidate(dashboardProvider);
    if (animalChanged) {
      ref
        ..invalidate(animalDetailProvider(animalId))
        ..invalidate(animalsProvider);
    }
    return true;
  }
}

final healthEventActionsProvider =
    AsyncNotifierProvider<HealthEventActionsNotifier, void>(
  HealthEventActionsNotifier.new,
);
