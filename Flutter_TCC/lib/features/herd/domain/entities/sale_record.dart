import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_record.freezed.dart';

/// Venda individual (1 animal) ou em lote (vários animais).
enum SaleType { individual, lote }

/// Evento de venda de um ou mais animais — base para o relatório de vendas (M5).
@freezed
class SaleRecord with _$SaleRecord {
  const factory SaleRecord({
    required String       id,
    required DateTime     date,
    required SaleType     type,
    required List<String> animalIds,
    required int          headCount,
    required double       totalValue,
    String? buyer,
    /// Peso total do lote na venda (kg) — usado para preço por arroba.
    double? totalWeightKg,
    /// Preço por arroba informado (R$/@; arroba = 15 kg).
    double? pricePerArroba,
    String? notes,
  }) = _SaleRecord;
}

extension SaleRecordX on SaleRecord {
  /// Valor médio por cabeça (R$). 0 se não houver cabeças (evita divisão por zero).
  double get valuePerHead => headCount == 0 ? 0 : totalValue / headCount;
}
