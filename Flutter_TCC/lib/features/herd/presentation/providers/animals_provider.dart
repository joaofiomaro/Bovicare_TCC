import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/animal_local_data_source.dart';
import '../../data/repositories/animal_repository_impl.dart';
import '../../domain/entities/animal_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../../domain/usecases/delete_animal_use_case.dart';
import '../../domain/usecases/get_animal_by_id_use_case.dart';
import '../../domain/usecases/get_animals_use_case.dart';
import '../../domain/usecases/save_animal_use_case.dart';

// --- Filtros ---

enum HerdFilter { all, females, males, pregnant, alerts }

/// Filtro de status selecionado na HerdListScreen.
final herdFilterProvider = StateProvider<HerdFilter>((_) => HerdFilter.all);

/// Query de busca livre (brinco, nome).
final herdSearchProvider = StateProvider<String>((_) => '');

// --- DI ---

final _animalDataSourceProvider = Provider<AnimalLocalDataSource>(
  (_) => AnimalLocalDataSource(),
);

final animalRepositoryProvider = Provider<AnimalRepository>(
  (ref) => AnimalRepositoryImpl(ref.watch(_animalDataSourceProvider)),
);

// --- Providers de lista (com filtro reativo) ---

class AnimalsNotifier extends AsyncNotifier<List<AnimalEntity>> {
  @override
  Future<List<AnimalEntity>> build() async {
    // Rebuilds automaticamente quando filtro ou busca mudam.
    final filter = ref.watch(herdFilterProvider);
    final query  = ref.watch(herdSearchProvider);
    final repo   = ref.read(animalRepositoryProvider);
    final all    = await GetAnimalsUseCase(repo).call();
    return _apply(all, filter, query);
  }

  List<AnimalEntity> _apply(
    List<AnimalEntity> list,
    HerdFilter filter,
    String query,
  ) {
    final q = query.trim().toLowerCase();

    final filtered = switch (filter) {
      HerdFilter.all      => list,
      HerdFilter.females  => list.where((a) => a.sex == AnimalSex.female).toList(),
      HerdFilter.males    => list.where((a) => a.sex == AnimalSex.male).toList(),
      HerdFilter.pregnant => list.where((a) => a.status == AnimalStatus.pregnant).toList(),
      HerdFilter.alerts   => list
          .where((a) => a.status == AnimalStatus.sick || a.status == AnimalStatus.attention)
          .toList(),
    };

    if (q.isEmpty) return filtered;
    return filtered
        .where((a) =>
            a.earTag.toLowerCase().contains(q) ||
            (a.name?.toLowerCase().contains(q) ?? false) ||
            a.breed.toLowerCase().contains(q) ||
            (a.rfid?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> save(AnimalEntity animal) async {
    final repo = ref.read(animalRepositoryProvider);
    await SaveAnimalUseCase(repo).call(animal);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repo = ref.read(animalRepositoryProvider);
    await DeleteAnimalUseCase(repo).call(id);
    ref.invalidateSelf();
  }
}

final animalsProvider =
    AsyncNotifierProvider<AnimalsNotifier, List<AnimalEntity>>(
  AnimalsNotifier.new,
);

// --- Provider de detalhe (família por id) ---

final animalDetailProvider = FutureProvider.autoDispose
    .family<AnimalEntity?, String>((ref, id) {
  final repo = ref.read(animalRepositoryProvider);
  return GetAnimalByIdUseCase(repo).call(id);
});
