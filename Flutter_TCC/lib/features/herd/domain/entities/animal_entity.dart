import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/extensions/datetime_ext.dart';

part 'animal_entity.freezed.dart';

enum AnimalStatus { healthy, pregnant, attention, sick }
enum AnimalSex    { female, male }

/// Situação do animal no ciclo de vida do rebanho (dimensão separada do
/// status sanitário): ativo, vendido ou óbito ("baixa" do rebanho).
enum AnimalExitType { active, sold, deceased }

/// Rótulos de exibição de [AnimalStatus] — fonte única de verdade.
/// Centralizado aqui (domínio) para evitar divergência de textos entre telas.
extension AnimalStatusX on AnimalStatus {
  String get label => switch (this) {
        AnimalStatus.healthy   => 'Saudável',
        AnimalStatus.pregnant  => 'Prenha',
        AnimalStatus.attention => 'Alerta',
        AnimalStatus.sick      => 'Medicação',
      };
}

/// Rótulos de exibição de [AnimalExitType].
extension AnimalExitTypeX on AnimalExitType {
  String get label => switch (this) {
        AnimalExitType.active   => 'Ativo',
        AnimalExitType.sold     => 'Vendido',
        AnimalExitType.deceased => 'Óbito',
      };
}

@freezed
class AnimalEntity with _$AnimalEntity {
  const factory AnimalEntity({
    required String      id,
    required String      earTag,
    required String      breed,
    required AnimalSex   sex,
    required DateTime    birthDate,
    required AnimalStatus status,
    String?  name,
    double?  weightKg,
    String?  rfid,
    /// Data de cobertura/inseminação — usada para calcular progresso da prenhez.
    DateTime? pregnancyDate,
    // --- Baixa do rebanho (M2) ---
    @Default(AnimalExitType.active) AnimalExitType exitType,
    DateTime? exitDate,
    String?   exitNotes,
    /// Referência ao documento de venda (quando [exitType] == sold).
    String?   saleId,
    /// Causa do óbito (quando [exitType] == deceased).
    String?   deathCause,
  }) = _AnimalEntity;
}

/// Computed properties para AnimalEntity (fora da classe freezed).
extension AnimalEntityX on AnimalEntity {
  int get ageInYears  => birthDate.ageInYears;
  int get ageInMonths => birthDate.ageInMonths;

  /// `true` se o animal recebeu baixa (venda ou óbito) e saiu do rebanho ativo.
  bool get isArchived => exitType != AnimalExitType.active;

  /// Nome formatado: "Mimosa — #047" ou "#047" se sem nome.
  String get displayName =>
      name != null && name!.isNotEmpty ? '$name — #$earTag' : '#$earTag';

  String get sexLabel => sex == AnimalSex.female ? 'F' : 'M';

  /// Progresso da gestação (0.0–1.0). Período bovino padrão: 283 dias.
  double get pregnancyProgress {
    if (pregnancyDate == null) return 0;
    final days = DateTime.now().difference(pregnancyDate!).inDays;
    return (days / 283).clamp(0.0, 1.0);
  }

  int get pregnancyDays =>
      pregnancyDate == null ? 0 : DateTime.now().difference(pregnancyDate!).inDays;

  DateTime? get expectedBirthDate =>
      pregnancyDate?.add(const Duration(days: 283));
}
