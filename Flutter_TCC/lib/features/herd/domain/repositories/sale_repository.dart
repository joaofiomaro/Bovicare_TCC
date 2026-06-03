import '../entities/sale_record.dart';

abstract interface class SaleRepository {
  /// Vendas registradas, da mais recente para a mais antiga.
  Future<List<SaleRecord>> getAll();

  /// Registra a venda e dá baixa nos animais (exitType=sold), atomicamente.
  Future<void> recordSale(SaleRecord sale);
}
