// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_call_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceCallModelImpl _$$ServiceCallModelImplFromJson(
  Map<String, dynamic> json,
) => _$ServiceCallModelImpl(
  id: json['id'] as String,
  producerId: json['producerId'] as String,
  producerName: json['producerName'] as String,
  city: json['city'] as String,
  state: json['state'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  urgency: json['urgency'] as String,
  status: json['status'] as String,
  createdAtIso: json['createdAtIso'] as String,
  farmName: json['farmName'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  animalEarTag: json['animalEarTag'] as String?,
  vetId: json['vetId'] as String?,
  vetName: json['vetName'] as String?,
  scheduledDateIso: json['scheduledDateIso'] as String?,
  completedAtIso: json['completedAtIso'] as String?,
  resolution: json['resolution'] as String?,
);

Map<String, dynamic> _$$ServiceCallModelImplToJson(
  _$ServiceCallModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'producerId': instance.producerId,
  'producerName': instance.producerName,
  'city': instance.city,
  'state': instance.state,
  'title': instance.title,
  'description': instance.description,
  'urgency': instance.urgency,
  'status': instance.status,
  'createdAtIso': instance.createdAtIso,
  'farmName': instance.farmName,
  'lat': instance.lat,
  'lng': instance.lng,
  'animalEarTag': instance.animalEarTag,
  'vetId': instance.vetId,
  'vetName': instance.vetName,
  'scheduledDateIso': instance.scheduledDateIso,
  'completedAtIso': instance.completedAtIso,
  'resolution': instance.resolution,
};
