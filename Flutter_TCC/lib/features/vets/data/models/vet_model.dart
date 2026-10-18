import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/vet_entity.dart';

part 'vet_model.freezed.dart';
part 'vet_model.g.dart';

@freezed
class VetModel with _$VetModel {
  const factory VetModel({
    required String       id,
    required String       name,
    required String       crmv,
    required List<String> specialties,
    required String       phone,
    required String       city,
    required String       state,
    required double       lat,
    required double       lng,
    required bool         isAvailable,
    required int          coverageRadiusKm,
    String? whatsapp,
    String? email,
  }) = _VetModel;

  // Freezed exige o construtor privado para permitir métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const VetModel._();

  factory VetModel.fromJson(Map<String, dynamic> json) =>
      _$VetModelFromJson(json);

  factory VetModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return VetModel(
      id:               doc.id,
      name:             d['name'] as String,
      crmv:             d['crmv'] as String,
      specialties:      ((d['specialties'] as List<dynamic>?) ?? const [])
          .cast<String>(),
      phone:            d['phone'] as String,
      city:             d['city'] as String,
      state:            d['state'] as String,
      lat:              (d['lat'] as num).toDouble(),
      lng:              (d['lng'] as num).toDouble(),
      isAvailable:      (d['isAvailable'] as bool?) ?? false,
      coverageRadiusKm: (d['coverageRadiusKm'] as num?)?.toInt() ?? 0,
      whatsapp:         d['whatsapp'] as String?,
      email:            d['email'] as String?,
    );
  }

  factory VetModel.fromEntity(VetEntity e) => VetModel(
        id:               e.id,
        name:             e.name,
        crmv:             e.crmv,
        specialties:      e.specialties,
        phone:            e.phone,
        city:             e.city,
        state:            e.state,
        lat:              e.lat,
        lng:              e.lng,
        isAvailable:      e.isAvailable,
        coverageRadiusKm: e.coverageRadiusKm,
        whatsapp:         e.whatsapp,
        email:            e.email,
      );

  Map<String, dynamic> toFirestore() => {
        'name':             name,
        'crmv':             crmv,
        'specialties':      specialties,
        'phone':            phone,
        'city':             city,
        'state':            state,
        'lat':              lat,
        'lng':              lng,
        'isAvailable':      isAvailable,
        'coverageRadiusKm': coverageRadiusKm,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (email != null)    'email':    email,
      };

  /// distanceKm não é persistido — calculado em runtime pelo provider.
  VetEntity toEntity({double? distanceKm}) => VetEntity(
        id:               id,
        name:             name,
        crmv:             crmv,
        specialties:      specialties,
        phone:            phone,
        city:             city,
        state:            state,
        lat:              lat,
        lng:              lng,
        isAvailable:      isAvailable,
        coverageRadiusKm: coverageRadiusKm,
        whatsapp:         whatsapp,
        email:            email,
        distanceKm:       distanceKm,
      );
}
