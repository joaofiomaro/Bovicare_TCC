/// Tipos de evento de manejo registrados na ficha do animal.
enum HealthEventType {
  /// Aplicação de vermífugo (antiparasitário).
  deworming,

  /// Medicação/tratamento (antibiótico, anti-inflamatório etc.).
  medication,

  /// Observação livre do produtor ou do veterinário.
  observation,

  /// Diagnóstico de prenhez (cobertura/inseminação confirmada).
  pregnancyDiagnosis,

  /// Parto concluído.
  birth,

  /// Perda gestacional (aborto/reabsorção).
  pregnancyLoss,
}

extension HealthEventTypeX on HealthEventType {
  String get label => switch (this) {
        HealthEventType.deworming          => 'Vermifugação',
        HealthEventType.medication         => 'Medicação',
        HealthEventType.observation        => 'Observação',
        HealthEventType.pregnancyDiagnosis => 'Prenhez confirmada',
        HealthEventType.birth              => 'Parto',
        HealthEventType.pregnancyLoss      => 'Perda gestacional',
      };

  /// Tratamentos com produto e possível período de carência.
  bool get isTreatment =>
      this == HealthEventType.deworming || this == HealthEventType.medication;

  /// Eventos do ciclo reprodutivo.
  bool get isReproductive =>
      this == HealthEventType.pregnancyDiagnosis ||
      this == HealthEventType.birth ||
      this == HealthEventType.pregnancyLoss;
}

/// Evento de manejo de um animal — coleção `users/{uid}/healthEvents`.
class HealthEvent {
  const HealthEvent({
    required this.id,
    required this.animalId,
    required this.type,
    required this.date,
    required this.title,
    this.dose,
    this.withdrawalDays = 0,
    this.notes,
    this.veterinarianName,
    this.calfId,
  });

  final String id;
  final String animalId;
  final HealthEventType type;
  final DateTime date;

  /// Produto aplicado (tratamentos) ou título curto (observação/reprodução).
  final String title;

  /// Dose/posologia informada (ex.: "10 mL", "1 mL/50 kg").
  final String? dose;

  /// Dias de carência para abate/leite após o tratamento (0 = sem carência).
  final int withdrawalDays;

  final String? notes;
  final String? veterinarianName;

  /// Bezerro cadastrado no parto (quando houver).
  final String? calfId;

  /// Último dia da carência; nulo quando não há carência.
  DateTime? get withdrawalEnd => withdrawalDays > 0
      ? date.add(Duration(days: withdrawalDays))
      : null;

  /// `true` se o animal ainda está em carência por este evento em [now].
  bool isInWithdrawal(DateTime now) {
    final end = withdrawalEnd;
    return end != null && !now.isAfter(end);
  }
}
