// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SaleModelImpl _$$SaleModelImplFromJson(Map<String, dynamic> json) =>
    _$SaleModelImpl(
      id: json['id'] as String,
      dateIso: json['dateIso'] as String,
      type: json['type'] as String,
      animalIds: (json['animalIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      headCount: (json['headCount'] as num).toInt(),
      totalValue: (json['totalValue'] as num).toDouble(),
      buyer: json['buyer'] as String?,
      totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble(),
      pricePerArroba: (json['pricePerArroba'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$SaleModelImplToJson(_$SaleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dateIso': instance.dateIso,
      'type': instance.type,
      'animalIds': instance.animalIds,
      'headCount': instance.headCount,
      'totalValue': instance.totalValue,
      'buyer': instance.buyer,
      'totalWeightKg': instance.totalWeightKg,
      'pricePerArroba': instance.pricePerArroba,
      'notes': instance.notes,
    };
