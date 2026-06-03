import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/datasources/sale_firestore_data_source.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/sale_record.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/usecases/get_sales_use_case.dart';
import '../../domain/usecases/record_animal_death_use_case.dart';
import '../../domain/usecases/record_animal_sale_use_case.dart';
import 'animals_provider.dart';

// --- DI ---

final _saleDataSourceProvider = Provider<SaleFirestoreDataSource>(
  (_) => SaleFirestoreDataSource(),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepositoryImpl(ref.watch(_saleDataSourceProvider)),
);

// --- Histórico de vendas ---

final salesProvider = FutureProvider<List<SaleRecord>>((ref) {
  final repo = ref.read(saleRepositoryProvider);
  return GetSalesUseCase(repo).call();
});

// --- Baixa de rebanho (venda / óbito, individual / lote) ---

class AnimalExitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Registra a venda e dá baixa nos animais. Retorna `false` em caso de falha.
  Future<bool> recordSale(SaleRecord sale) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await RecordAnimalSaleUseCase(ref.read(saleRepositoryProvider)).call(sale);
      _invalidate(sale.animalIds);
    });
    return !state.hasError;
  }

  /// Registra óbito dos animais. Retorna `false` em caso de falha.
  Future<bool> recordDeath({
    required List<String> animalIds,
    required DateTime date,
    String? cause,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await RecordAnimalDeathUseCase(ref.read(animalRepositoryProvider)).call(
        animalIds: animalIds,
        date: date,
        cause: cause,
        notes: notes,
      );
      _invalidate(animalIds);
    });
    return !state.hasError;
  }

  /// Recarrega tudo que depende do estado do rebanho após uma baixa.
  void _invalidate(List<String> animalIds) {
    ref
      ..invalidate(animalsProvider)
      ..invalidate(salesProvider)
      ..invalidate(dashboardProvider);
    for (final id in animalIds) {
      ref.invalidate(animalDetailProvider(id));
    }
  }
}

final animalExitProvider =
    AsyncNotifierProvider<AnimalExitNotifier, void>(AnimalExitNotifier.new);
