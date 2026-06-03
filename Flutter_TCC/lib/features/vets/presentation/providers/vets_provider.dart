import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/vet_in_memory_data_source.dart';
import '../../data/repositories/vet_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../domain/entities/vet_entity.dart';
import '../../domain/repositories/vet_repository.dart';
import '../../domain/usecases/calculate_distance_use_case.dart';
import '../../domain/usecases/get_vet_by_id_use_case.dart';
import '../../domain/usecases/get_vets_use_case.dart';

// --- DI ---

final _vetDataSourceProvider = Provider<VetInMemoryDataSource>(
  (_) => VetInMemoryDataSource(),
);

final vetRepositoryProvider = Provider<VetRepository>(
  (ref) => VetRepositoryImpl(ref.watch(_vetDataSourceProvider)),
);

final _locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);

// --- Localização do usuário ---

/// Retorna (lat, lng) — usa fallback Rio Claro, SP se permissão negada.
final userLocationProvider = FutureProvider<(double, double)>((ref) {
  return ref.read(_locationServiceProvider).getCurrentLocation();
});

// --- Filtros ---

/// Exibe somente vets disponíveis quando true.
final vetAvailableFilterProvider = StateProvider<bool>((_) => false);

/// Query de busca livre por nome ou especialidade.
final vetSearchProvider = StateProvider<String>((_) => '');

// --- Lista de vets com distância calculada ---

class VetsNotifier extends AsyncNotifier<List<VetEntity>> {
  static const _calcDistance = CalculateDistanceUseCase();

  @override
  Future<List<VetEntity>> build() async {
    final onlyAvailable = ref.watch(vetAvailableFilterProvider);
    final query         = ref.watch(vetSearchProvider);

    final (repo, location) = await (
      Future.value(ref.read(vetRepositoryProvider)),
      ref.read(userLocationProvider.future),
    ).wait;

    final all = await GetVetsUseCase(repo).call();

    final withDistance = all.map((v) {
      final km = _calcDistance(
        lat1: location.$1, lng1: location.$2,
        lat2: v.lat,       lng2: v.lng,
      );
      return v.copyWith(distanceKm: double.parse(km.toStringAsFixed(1)));
    }).toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    return _applyFilters(withDistance, onlyAvailable, query);
  }

  List<VetEntity> _applyFilters(
    List<VetEntity> list,
    bool onlyAvailable,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return list.where((v) {
      if (onlyAvailable && !v.isAvailable) return false;
      if (q.isEmpty) return true;
      return v.name.toLowerCase().contains(q) ||
          v.specialties.any((s) => s.toLowerCase().contains(q)) ||
          v.city.toLowerCase().contains(q);
    }).toList();
  }
}

final vetsProvider =
    AsyncNotifierProvider<VetsNotifier, List<VetEntity>>(VetsNotifier.new);

// --- Detalhe de um vet ---

final vetDetailProvider =
    FutureProvider.autoDispose.family<VetEntity?, String>((ref, id) {
  final repo = ref.read(vetRepositoryProvider);
  return GetVetByIdUseCase(repo).call(id);
});

// --- Opções de vets para seleção em formulários ---

/// Lista de vets formatada (`Nome — CRMV xxxxx`) para dropdowns, sempre com
/// "Não informado" como primeira opção. Não depende de localização/distância.
final vetOptionsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(vetRepositoryProvider);
  final vets = await GetVetsUseCase(repo).call();
  return [
    'Não informado',
    for (final v in vets) '${v.name} — CRMV ${v.crmv}',
  ];
});
