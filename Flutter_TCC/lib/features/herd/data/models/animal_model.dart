import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/animal_entity.dart';

part 'animal_model.freezed.dart';
part 'animal_model.g.dart';

@freezed
class AnimalModel with _$AnimalModel {
  const factory AnimalModel({
    required String id,
    required String earTag,
    required String breed,
    required String sex,
    required String status,
    required String birthDateIso,
    String? name,
    double? weightKg,
    String? rfid,
    String? pregnancyDateIso,
  }) = _AnimalModel;

  // Freezed exige o construtor privado para permitir métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const AnimalModel._();

  factory AnimalModel.fromJson(Map<String, dynamic> json) =>
      _$AnimalModelFromJson(json);

  factory AnimalModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return AnimalModel(
      id:               doc.id,
      earTag:           d['earTag'] as String,
      breed:            d['breed'] as String,
      sex:              d['sex'] as String,
      status:           d['status'] as String,
      birthDateIso:     d['birthDateIso'] as String,
      name:             d['name'] as String?,
      weightKg:         (d['weightKg'] as num?)?.toDouble(),
      rfid:             d['rfid'] as String?,
      pregnancyDateIso: d['pregnancyDateIso'] as String?,
    );
  }

  factory AnimalModel.fromEntity(AnimalEntity e) => AnimalModel(
        id:               e.id,
        earTag:           e.earTag,
        breed:            e.breed,
        sex:              e.sex.name,
        status:           e.status.name,
        birthDateIso:     e.birthDate.toIso8601String(),
        name:             e.name,
        weightKg:         e.weightKg,
        rfid:             e.rfid,
        pregnancyDateIso: e.pregnancyDate?.toIso8601String(),
      );

  Map<String, dynamic> toFirestore() => {
        'earTag':       earTag,
        'breed':        breed,
        'sex':          sex,
        'status':       status,
        'birthDateIso': birthDateIso,
        if (name != null)             'name':             name,
        if (weightKg != null)         'weightKg':         weightKg,
        if (rfid != null)             'rfid':             rfid,
        if (pregnancyDateIso != null) 'pregnancyDateIso': pregnancyDateIso,
      };

  AnimalEntity toEntity() => AnimalEntity(
        id:             id,
        earTag:         earTag,
        breed:          breed,
        sex:            AnimalSex.values.byName(sex),
        status:         AnimalStatus.values.byName(status),
        birthDate:      DateTime.parse(birthDateIso),
        name:           name,
        weightKg:       weightKg,
        rfid:           rfid,
        pregnancyDate:  pregnancyDateIso != null
            ? DateTime.parse(pregnancyDateIso!)
            : null,
      );
}
