import 'package:freezed_annotation/freezed_annotation.dart';

part 'vet_entity.freezed.dart';

@freezed
class VetEntity with _$VetEntity {
  const factory VetEntity({
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
    /// Raio de atendimento em km a partir da cidade base.
    required int          coverageRadiusKm,
    String? whatsapp,
    String? email,
    /// Calculado em runtime a partir da localização do usuário; não é persistido.
    double? distanceKm,
  }) = _VetEntity;
}
