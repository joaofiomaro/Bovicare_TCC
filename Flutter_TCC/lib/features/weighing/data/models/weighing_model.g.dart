// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weighing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WeighingModelImpl _$$WeighingModelImplFromJson(Map<String, dynamic> json) =>
    _$WeighingModelImpl(
      id: json['id'] as String,
      animalId: json['animalId'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      dateIso: json['dateIso'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$WeighingModelImplToJson(_$WeighingModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'animalId': instance.animalId,
      'weightKg': instance.weightKg,
      'dateIso': instance.dateIso,
      'notes': instance.notes,
    };
