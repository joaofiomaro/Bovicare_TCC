// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VetModelImpl _$$VetModelImplFromJson(Map<String, dynamic> json) =>
    _$VetModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      crmv: json['crmv'] as String,
      specialties: (json['specialties'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      phone: json['phone'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool,
      coverageRadiusKm: (json['coverageRadiusKm'] as num).toInt(),
      whatsapp: json['whatsapp'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$$VetModelImplToJson(_$VetModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'crmv': instance.crmv,
      'specialties': instance.specialties,
      'phone': instance.phone,
      'city': instance.city,
      'state': instance.state,
      'lat': instance.lat,
      'lng': instance.lng,
      'isAvailable': instance.isAvailable,
      'coverageRadiusKm': instance.coverageRadiusKm,
      'whatsapp': instance.whatsapp,
      'email': instance.email,
    };
