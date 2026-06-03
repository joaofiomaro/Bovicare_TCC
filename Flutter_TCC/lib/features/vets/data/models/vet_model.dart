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
