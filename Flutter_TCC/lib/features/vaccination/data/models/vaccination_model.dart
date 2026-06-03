import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/vaccination_record.dart';

part 'vaccination_model.freezed.dart';
part 'vaccination_model.g.dart';

@freezed
class VaccinationModel with _$VaccinationModel {
  const factory VaccinationModel({
    required String id,
    required String animalId,
    required String vaccineName,
    required String dose,
    required String dateIso,
    required int    quarantineDays,
    String? lot,
    String? veterinarianName,
    String? nextDoseDateIso,
  }) = _VaccinationModel;

  // Freezed exige o construtor privado para métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const VaccinationModel._();

  factory VaccinationModel.fromJson(Map<String, dynamic> json) =>
      _$VaccinationModelFromJson(json);

  factory VaccinationModel.fromEntity(VaccinationRecord r) => VaccinationModel(
        id:               r.id,
        animalId:         r.animalId,
        vaccineName:      r.vaccineName,
        dose:             r.dose,
        dateIso:          r.date.toIso8601String(),
        quarantineDays:   r.quarantineDays,
        lot:              r.lot,
        veterinarianName: r.veterinarianName,
        nextDoseDateIso:  r.nextDoseDate?.toIso8601String(),
      );

  VaccinationRecord toEntity() => VaccinationRecord(
        id:               id,
        animalId:         animalId,
        vaccineName:      vaccineName,
        dose:             dose,
        date:             DateTime.parse(dateIso),
        quarantineDays:   quarantineDays,
        lot:              lot,
        veterinarianName: veterinarianName,
        nextDoseDate:     nextDoseDateIso != null
            ? DateTime.parse(nextDoseDateIso!)
            : null,
      );
}
