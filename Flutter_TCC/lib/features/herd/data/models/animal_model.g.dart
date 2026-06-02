// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'animal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnimalModelImpl _$$AnimalModelImplFromJson(Map<String, dynamic> json) =>
    _$AnimalModelImpl(
      id: json['id'] as String,
      earTag: json['earTag'] as String,
      breed: json['breed'] as String,
      sex: json['sex'] as String,
      status: json['status'] as String,
      birthDateIso: json['birthDateIso'] as String,
      name: json['name'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      rfid: json['rfid'] as String?,
      pregnancyDateIso: json['pregnancyDateIso'] as String?,
    );

Map<String, dynamic> _$$AnimalModelImplToJson(_$AnimalModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'earTag': instance.earTag,
      'breed': instance.breed,
      'sex': instance.sex,
      'status': instance.status,
      'birthDateIso': instance.birthDateIso,
      'name': instance.name,
      'weightKg': instance.weightKg,
      'rfid': instance.rfid,
      'pregnancyDateIso': instance.pregnancyDateIso,
    };
