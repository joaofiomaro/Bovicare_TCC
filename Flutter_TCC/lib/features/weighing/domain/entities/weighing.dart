import 'package:freezed_annotation/freezed_annotation.dart';

part 'weighing.freezed.dart';

/// Uma pesagem individual de um animal, em um dado momento.
@freezed
class Weighing with _$Weighing {
  const factory Weighing({
    required String   id,
    required String   animalId,
    required double   weightKg,
    required DateTime date,
    String? notes,
  }) = _Weighing;
}

/// Métricas de ganho de peso calculadas sobre uma lista de pesagens.
/// Funções puras — base para a ficha do animal e os relatórios (M5).
extension WeighingsX on List<Weighing> {
  Weighing? get _earliest =>
      isEmpty ? null : reduce((a, b) => a.date.isBefore(b.date) ? a : b);

  Weighing? get _latest =>
      isEmpty ? null : reduce((a, b) => a.date.isAfter(b.date) ? a : b);

  /// Peso da pesagem mais recente (null se não houver pesagens).
  double? get lastWeight => _latest?.weightKg;

  /// Ganho total (kg) entre a primeira e a última pesagem.
  double get totalGain {
    if (length < 2) return 0;
    return _latest!.weightKg - _earliest!.weightKg;
  }

  /// Período coberto pelas pesagens, em dias.
  int get periodDays {
    if (length < 2) return 0;
    return _latest!.date.difference(_earliest!.date).inDays;
  }

  /// Ganho médio diário (kg/dia). Null se houver < 2 pesagens
  /// ou se o período for <= 0 (evita divisão por zero).
  double? get gmd {
    final days = periodDays;
    if (length < 2 || days <= 0) return null;
    return totalGain / days;
  }
}
