import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/weighing.dart';

part 'weighing_model.freezed.dart';
part 'weighing_model.g.dart';

@freezed
class WeighingModel with _$WeighingModel {
  const factory WeighingModel({
    required String id,
    required String animalId,
    required double weightKg,
    required String dateIso,
    String? notes,
  }) = _WeighingModel;

  // Freezed exige o construtor privado para métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const WeighingModel._();

  factory WeighingModel.fromJson(Map<String, dynamic> json) =>
      _$WeighingModelFromJson(json);

  factory WeighingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return WeighingModel(
      id:       doc.id,
      animalId: d['animalId'] as String,
      weightKg: (d['weightKg'] as num).toDouble(),
      dateIso:  d['dateIso'] as String,
      notes:    d['notes'] as String?,
    );
  }

  factory WeighingModel.fromEntity(Weighing w) => WeighingModel(
        id:       w.id,
        animalId: w.animalId,
        weightKg: w.weightKg,
        dateIso:  w.date.toIso8601String(),
        notes:    w.notes,
      );

  Map<String, dynamic> toFirestore() => {
        'animalId': animalId,
        'weightKg': weightKg,
        'dateIso':  dateIso,
        if (notes != null) 'notes': notes,
      };

  Weighing toEntity() => Weighing(
        id:       id,
        animalId: animalId,
        weightKg: weightKg,
        date:     DateTime.parse(dateIso),
        notes:    notes,
      );
}
