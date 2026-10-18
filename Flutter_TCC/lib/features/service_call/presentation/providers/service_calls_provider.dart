import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/service_call_firestore_data_source.dart';
import '../../data/repositories/service_call_repository_impl.dart';
import '../../domain/entities/service_call.dart';
import '../../domain/repositories/service_call_repository.dart';
import '../../domain/usecases/accept_call_use_case.dart';
import '../../domain/usecases/advance_call_use_case.dart';
import '../../domain/usecases/cancel_call_use_case.dart';
import '../../domain/usecases/open_service_call_use_case.dart';

// --- DI ---

final _serviceCallDataSourceProvider =
    Provider<ServiceCallFirestoreDataSource>(
  (_) => ServiceCallFirestoreDataSource(),
);

final serviceCallRepositoryProvider = Provider<ServiceCallRepository>(
  (ref) =>
      ServiceCallRepositoryImpl(ref.watch(_serviceCallDataSourceProvider)),
);

// --- Listas ---

/// Pool de chamados abertos (visão do vet) — tempo real.
/// Só veterinários consultam o pool (as regras negam a produtores).
final openCallsProvider = StreamProvider<List<ServiceCall>>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null || user.role != UserRole.vet) return Stream.value(const []);
  return ref.read(serviceCallRepositoryProvider).watchOpen();
});

/// Chamados atribuídos ao vet logado — tempo real.
final vetCallsProvider = StreamProvider<List<ServiceCall>>((ref) {
  final uid = ref.watch(authProvider).valueOrNull?.id;
  if (uid == null) return Stream.value(const []);
  return ref.read(serviceCallRepositoryProvider).watchForVet(uid);
});

/// Chamados abertos pelo produtor logado — tempo real.
final producerCallsProvider = StreamProvider<List<ServiceCall>>((ref) {
  final uid = ref.watch(authProvider).valueOrNull?.id;
  if (uid == null) return Stream.value(const []);
  return ref.read(serviceCallRepositoryProvider).watchForProducer(uid);
});

// --- Ações (abrir / aceitar / evoluir / cancelar) ---

class ServiceCallActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ServiceCallRepository get _repo => ref.read(serviceCallRepositoryProvider);

  /// Produtor abre um chamado.
  Future<bool> open(ServiceCall call) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await OpenServiceCallUseCase(_repo).call(call);
      ref.invalidate(producerCallsProvider);
    });
    return !state.hasError;
  }

  /// Vet aceita um chamado do pool.
  Future<bool> accept(ServiceCall call) async {
    final vet = ref.read(authProvider).valueOrNull;
    if (vet == null) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AcceptCallUseCase(_repo).call(
        call,
        vetId: vet.id,
        vetName: vet.name,
      );
      _invalidateVetViews();
    });
    return !state.hasError;
  }

  /// Vet evolui o atendimento (inProgress / agenda / conclui com laudo).
  Future<bool> advance(
    ServiceCall call, {
    required ServiceStatus to,
    DateTime? scheduledDate,
    String? resolution,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AdvanceCallUseCase(_repo).call(
        call,
        to: to,
        scheduledDate: scheduledDate,
        resolution: resolution,
      );
      _invalidateVetViews();
    });
    return !state.hasError;
  }

  /// Produtor cancela o próprio chamado.
  Future<bool> cancel(ServiceCall call) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await CancelCallUseCase(_repo).call(call);
      ref.invalidate(producerCallsProvider);
    });
    return !state.hasError;
  }

  void _invalidateVetViews() {
    ref
      ..invalidate(openCallsProvider)
      ..invalidate(vetCallsProvider);
  }
}

final serviceCallActionsProvider =
    AsyncNotifierProvider<ServiceCallActionsNotifier, void>(
  ServiceCallActionsNotifier.new,
);
