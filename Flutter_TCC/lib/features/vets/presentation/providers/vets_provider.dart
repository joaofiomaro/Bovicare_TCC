import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/vet_firestore_data_source.dart';
import '../../data/datasources/vet_in_memory_data_source.dart';
import '../../data/repositories/vet_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../domain/entities/vet_entity.dart';
import '../../domain/repositories/vet_repository.dart';
import '../../domain/usecases/calculate_distance_use_case.dart';
import '../../domain/usecases/get_vet_by_id_use_case.dart';
import '../../domain/usecases/get_vets_use_case.dart';

export '../../data/services/location_service.dart'
    show LocationSource, UserLocation;

// --- DI ---

final vetRepositoryProvider = Provider<VetRepository>(
  (_) => VetRepositoryImpl(VetFirestoreDataSource(), VetInMemoryDataSource()),
);

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);

// --- Localização do usuário ---

/// Posição do usuário com origem (GPS, última conhecida ou fallback
/// Rio Claro, SP). Invalidar este provider força uma nova leitura do GPS e
/// recalcula as distâncias em [vetsProvider].
final userLocationProvider = FutureProvider<UserLocation>((ref) {
  // Consentimento revogado (LGPD): não lê o GPS nem pede permissão.
  if (!ref.watch(locationConsentProvider)) {
    return const UserLocation(
      lat:    LocationService.defaultLat,
      lng:    LocationService.defaultLng,
      source: LocationSource.disabledByUser,
    );
  }
  return ref.read(locationServiceProvider).getCurrentLocation();
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

    // `watch` (não `read`): quando a localização é atualizada, a lista e as
    // distâncias são recalculadas automaticamente.
    final location = await ref.watch(userLocationProvider.future);
    final repo     = ref.read(vetRepositoryProvider);

    final all = await GetVetsUseCase(repo).call();

    final withDistance = all.map((v) {
      final km = _calcDistance(
        lat1: location.lat, lng1: location.lng,
        lat2: v.lat,        lng2: v.lng,
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

// --- Perfil profissional do veterinário logado ---

/// Perfil público do vet logado (null = não publicado).
final myVetProfileProvider = FutureProvider.autoDispose<VetEntity?>((ref) {
  final uid = ref.watch(authProvider).valueOrNull?.id;
  if (uid == null) return Future.value();
  return ref.read(vetRepositoryProvider).getMyProfile(uid);
});

class VetProfileActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> publish(VetEntity profile) => _run(
        () => ref.read(vetRepositoryProvider).saveMyProfile(profile),
      );

  Future<bool> unpublish(String uid) => _run(
        () => ref.read(vetRepositoryProvider).deleteMyProfile(uid),
      );

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    if (state.hasError) return false;
    ref
      ..invalidate(myVetProfileProvider)
      ..invalidate(vetsProvider)
      ..invalidate(vetOptionsProvider);
    return true;
  }
}

final vetProfileActionsProvider =
    AsyncNotifierProvider<VetProfileActionsNotifier, void>(
  VetProfileActionsNotifier.new,
);
