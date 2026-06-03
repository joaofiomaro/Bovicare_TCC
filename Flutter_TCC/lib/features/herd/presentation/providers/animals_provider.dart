import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/animal_firestore_data_source.dart';
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

final _animalDataSourceProvider = Provider<AnimalFirestoreDataSource>(
  (_) => AnimalFirestoreDataSource(),
);

final animalRepositoryProvider = Provider<AnimalRepository>(
  (ref) => AnimalRepositoryImpl(ref.watch(_animalDataSourceProvider)),
);

// --- Provider de lista (fetch único, sem refetch por filtro/busca) ---

class AnimalsNotifier extends AsyncNotifier<List<AnimalEntity>> {
  /// Busca a lista no Firestore uma única vez. Filtro e busca são aplicados
  /// em memória por [filteredAnimalsProvider] — sem refetch por tecla digitada.
  @override
  Future<List<AnimalEntity>> build() {
    final repo = ref.read(animalRepositoryProvider);
    return GetAnimalsUseCase(repo).call();
  }

  /// Salva o animal e recarrega a lista. Retorna `false` em caso de falha.
  Future<bool> save(AnimalEntity animal) async {
    try {
      final repo = ref.read(animalRepositoryProvider);
      await SaveAnimalUseCase(repo).call(animal);
      ref.invalidateSelf();
      return true;
    } on Exception {
      return false;
    }
  }

  /// Remove o animal e recarrega a lista. Retorna `false` em caso de falha.
  Future<bool> delete(String id) async {
    try {
      final repo = ref.read(animalRepositoryProvider);
      await DeleteAnimalUseCase(repo).call(id);
      ref.invalidateSelf();
      return true;
    } on Exception {
      return false;
    }
  }
}

final animalsProvider =
    AsyncNotifierProvider<AnimalsNotifier, List<AnimalEntity>>(
  AnimalsNotifier.new,
);

// --- Lista derivada: filtro + busca aplicados em memória ---

/// Aplica [filter] e [query] sobre a lista carregada, sem tocar no Firestore.
List<AnimalEntity> _applyHerdFilters(
  List<AnimalEntity> list,
  HerdFilter filter,
  String query,
) {
  final filtered = switch (filter) {
    HerdFilter.all      => list,
    HerdFilter.females  => list.where((a) => a.sex == AnimalSex.female).toList(),
    HerdFilter.males    => list.where((a) => a.sex == AnimalSex.male).toList(),
    HerdFilter.pregnant =>
      list.where((a) => a.status == AnimalStatus.pregnant).toList(),
    HerdFilter.alerts => list
        .where((a) =>
            a.status == AnimalStatus.sick ||
            a.status == AnimalStatus.attention)
        .toList(),
  };

  final q = query.trim().toLowerCase();
  if (q.isEmpty) return filtered;
  return filtered
      .where((a) =>
          a.earTag.toLowerCase().contains(q) ||
          (a.name?.toLowerCase().contains(q) ?? false) ||
          a.breed.toLowerCase().contains(q) ||
          (a.rfid?.toLowerCase().contains(q) ?? false))
      .toList();
}

/// Lista exibida na UI: reage a filtro/busca sem refetch (apenas reprocessa
/// em memória a lista já carregada por [animalsProvider]).
final filteredAnimalsProvider =
    Provider<AsyncValue<List<AnimalEntity>>>((ref) {
  final animals = ref.watch(animalsProvider);
  final filter  = ref.watch(herdFilterProvider);
  final query   = ref.watch(herdSearchProvider);
  return animals.whenData((list) => _applyHerdFilters(list, filter, query));
});

// --- Provider de detalhe (família por id) ---

final animalDetailProvider = FutureProvider.autoDispose
    .family<AnimalEntity?, String>((ref, id) {
  final repo = ref.read(animalRepositoryProvider);
  return GetAnimalByIdUseCase(repo).call(id);
});
