import 'package:freezed_annotation/freezed_annotation.dart';

part 'vaccination_record.freezed.dart';

@freezed
class VaccinationRecord with _$VaccinationRecord {
  const factory VaccinationRecord({
    required String   id,
    required String   animalId,
    required String   vaccineName,
    required String   dose,
    required DateTime date,
    /// Dias de carência sanitária após a aplicação (varia por vacina).
    required int      quarantineDays,
    String?   lot,
    String?   veterinarianName,
    /// Data calculada para a próxima dose (null se dose única sem reforço).
    DateTime? nextDoseDate,
  }) = _VaccinationRecord;
}
