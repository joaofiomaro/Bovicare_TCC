import '../entities/sale_record.dart';
import '../repositories/sale_repository.dart';

class RecordAnimalSaleUseCase {
  const RecordAnimalSaleUseCase(this._repository);
  final SaleRepository _repository;

  /// Valida invariantes da venda antes de persistir.
  /// Lança [ArgumentError] em dados inconsistentes (defesa em profundidade —
  /// a UI já restringe a seleção).
  Future<void> call(SaleRecord sale) {
    if (sale.animalIds.isEmpty) {
      throw ArgumentError('A venda precisa de ao menos um animal.');
    }
    if (sale.animalIds.toSet().length != sale.animalIds.length) {
      throw ArgumentError('Lista de animais com duplicatas.');
    }
    if (sale.headCount != sale.animalIds.length) {
      throw ArgumentError('headCount diverge do número de animais.');
    }
    if (sale.totalValue < 0) {
      throw ArgumentError('Valor total não pode ser negativo.');
    }
    return _repository.recordSale(sale);
  }
}
