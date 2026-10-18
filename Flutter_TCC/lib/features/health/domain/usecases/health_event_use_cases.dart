import '../../../herd/domain/entities/animal_entity.dart';
import '../entities/health_event.dart';
import '../repositories/health_event_repository.dart';

/// Gestação bovina padrão (dias) — mesma referência de `AnimalEntityX`.
const int kGestationDays = 283;

/// Limite de sanidade para carência informada manualmente (dias).
const int kMaxWithdrawalDays = 365;

bool _isFuture(DateTime date, DateTime now) =>
    date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));

/// Registra vermifugação, medicação ou observação, validando os campos.
class RegisterHealthEventUseCase {
  const RegisterHealthEventUseCase(this._repository);
  final HealthEventRepository _repository;

  Future<void> call(HealthEvent event, {DateTime? now}) {
    final today = now ?? DateTime.now();
    if (event.type.isReproductive) {
      throw ArgumentError('Use o registro de reprodução para este evento.');
    }
    if (event.title.trim().isEmpty) {
      throw ArgumentError(
        event.type.isTreatment
            ? 'Informe o produto aplicado.'
            : 'Informe o assunto da observação.',
      );
    }
    if (event.withdrawalDays < 0 || event.withdrawalDays > kMaxWithdrawalDays) {
      throw ArgumentError('Carência deve ficar entre 0 e $kMaxWithdrawalDays dias.');
    }
    if (_isFuture(event.date, today)) {
      throw ArgumentError('A data não pode estar no futuro.');
    }
    return _repository.add(event);
  }
}

/// Registra prenhez confirmada: o animal precisa ser fêmea, ativa e não
/// prenhe, e a cobertura deve caber numa gestação (≤ 283 dias atrás).
class RegisterPregnancyUseCase {
  const RegisterPregnancyUseCase(this._repository);
  final HealthEventRepository _repository;

  Future<void> call({
    required AnimalEntity animal,
    required HealthEvent event,
    required DateTime coverageDate,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    if (animal.sex != AnimalSex.female) {
      throw ArgumentError('Apenas fêmeas podem ter prenhez registrada.');
    }
    if (animal.isArchived) {
      throw ArgumentError('Animal fora do rebanho ativo.');
    }
    if (animal.status == AnimalStatus.pregnant) {
      throw ArgumentError('O animal já está prenhe.');
    }
    if (_isFuture(coverageDate, today)) {
      throw ArgumentError('A data de cobertura não pode estar no futuro.');
    }
    if (today.difference(coverageDate).inDays > kGestationDays) {
      throw ArgumentError(
        'Cobertura há mais de $kGestationDays dias — registre o parto.',
      );
    }
    return _repository.registerPregnancy(
      event: event,
      coverageDate: coverageDate,
    );
  }
}

/// Registra o parto de uma fêmea prenhe, com bezerro opcional.
class RegisterBirthUseCase {
  const RegisterBirthUseCase(this._repository);
  final HealthEventRepository _repository;

  Future<void> call({
    required AnimalEntity mother,
    required HealthEvent event,
    AnimalEntity? calf,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    if (mother.status != AnimalStatus.pregnant) {
      throw ArgumentError('O animal não está prenhe.');
    }
    if (_isFuture(event.date, today)) {
      throw ArgumentError('A data do parto não pode estar no futuro.');
    }
    if (calf != null && calf.earTag.trim().isEmpty) {
      throw ArgumentError('Informe o brinco do bezerro.');
    }
    return _repository.registerBirth(event: event, calf: calf);
  }
}

/// Registra perda gestacional de uma fêmea prenhe.
class RegisterPregnancyLossUseCase {
  const RegisterPregnancyLossUseCase(this._repository);
  final HealthEventRepository _repository;

  Future<void> call({
    required AnimalEntity mother,
    required HealthEvent event,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    if (mother.status != AnimalStatus.pregnant) {
      throw ArgumentError('O animal não está prenhe.');
    }
    if (_isFuture(event.date, today)) {
      throw ArgumentError('A data não pode estar no futuro.');
    }
    return _repository.registerPregnancyLoss(event);
  }
}
