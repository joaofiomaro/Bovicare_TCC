import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory VaccinationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return VaccinationModel(
      id:               doc.id,
      animalId:         d['animalId'] as String,
      vaccineName:      d['vaccineName'] as String,
      dose:             d['dose'] as String,
      dateIso:          d['dateIso'] as String,
      quarantineDays:   (d['quarantineDays'] as num).toInt(),
      lot:              d['lot'] as String?,
      veterinarianName: d['veterinarianName'] as String?,
      nextDoseDateIso:  d['nextDoseDateIso'] as String?,
    );
  }

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

  Map<String, dynamic> toFirestore() => {
        'animalId':       animalId,
        'vaccineName':    vaccineName,
        'dose':           dose,
        'dateIso':        dateIso,
        'quarantineDays': quarantineDays,
        if (lot != null)              'lot':              lot,
        if (veterinarianName != null) 'veterinarianName': veterinarianName,
        if (nextDoseDateIso != null)  'nextDoseDateIso':  nextDoseDateIso,
      };

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
