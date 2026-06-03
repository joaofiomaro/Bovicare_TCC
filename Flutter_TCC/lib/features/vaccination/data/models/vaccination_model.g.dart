// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vaccination_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VaccinationModelImpl _$$VaccinationModelImplFromJson(
  Map<String, dynamic> json,
) => _$VaccinationModelImpl(
  id: json['id'] as String,
  animalId: json['animalId'] as String,
  vaccineName: json['vaccineName'] as String,
  dose: json['dose'] as String,
  dateIso: json['dateIso'] as String,
  quarantineDays: (json['quarantineDays'] as num).toInt(),
  lot: json['lot'] as String?,
  veterinarianName: json['veterinarianName'] as String?,
  nextDoseDateIso: json['nextDoseDateIso'] as String?,
);

Map<String, dynamic> _$$VaccinationModelImplToJson(
  _$VaccinationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'animalId': instance.animalId,
  'vaccineName': instance.vaccineName,
  'dose': instance.dose,
  'dateIso': instance.dateIso,
  'quarantineDays': instance.quarantineDays,
  'lot': instance.lot,
  'veterinarianName': instance.veterinarianName,
  'nextDoseDateIso': instance.nextDoseDateIso,
};
