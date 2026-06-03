/// Use case puro — sem repositório. Calcula a data de fim de carência sanitária.
class CalculateQuarantineEndUseCase {
  const CalculateQuarantineEndUseCase();

  /// Retorna null quando não há período de carência (quarantineDays == 0).
  DateTime? call({required DateTime date, required int quarantineDays}) {
    if (quarantineDays <= 0) return null;
    return date.add(Duration(days: quarantineDays));
  }
}
