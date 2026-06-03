import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/sale_record.dart';

part 'sale_model.freezed.dart';
part 'sale_model.g.dart';

@freezed
class SaleModel with _$SaleModel {
  const factory SaleModel({
    required String       id,
    required String       dateIso,
    required String       type,
    required List<String> animalIds,
    required int          headCount,
    required double       totalValue,
    String? buyer,
    double? totalWeightKg,
    double? pricePerArroba,
    String? notes,
  }) = _SaleModel;

  // Freezed exige o construtor privado para métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const SaleModel._();

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);

  factory SaleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return SaleModel(
      id:             doc.id,
      dateIso:        d['dateIso'] as String,
      type:           d['type'] as String,
      animalIds:      (d['animalIds'] as List<dynamic>).cast<String>(),
      headCount:      (d['headCount'] as num).toInt(),
      totalValue:     (d['totalValue'] as num).toDouble(),
      buyer:          d['buyer'] as String?,
      totalWeightKg:  (d['totalWeightKg'] as num?)?.toDouble(),
      pricePerArroba: (d['pricePerArroba'] as num?)?.toDouble(),
      notes:          d['notes'] as String?,
    );
  }

  factory SaleModel.fromEntity(SaleRecord s) => SaleModel(
        id:             s.id,
        dateIso:        s.date.toIso8601String(),
        type:           s.type.name,
        animalIds:      s.animalIds,
        headCount:      s.headCount,
        totalValue:     s.totalValue,
        buyer:          s.buyer,
        totalWeightKg:  s.totalWeightKg,
        pricePerArroba: s.pricePerArroba,
        notes:          s.notes,
      );

  Map<String, dynamic> toFirestore() => {
        'dateIso':    dateIso,
        'type':       type,
        'animalIds':  animalIds,
        'headCount':  headCount,
        'totalValue': totalValue,
        if (buyer != null)          'buyer':          buyer,
        if (totalWeightKg != null)  'totalWeightKg':  totalWeightKg,
        if (pricePerArroba != null) 'pricePerArroba': pricePerArroba,
        if (notes != null)          'notes':          notes,
      };

  SaleRecord toEntity() => SaleRecord(
        id:             id,
        date:           DateTime.parse(dateIso),
        type:           SaleType.values.byName(type),
        animalIds:      animalIds,
        headCount:      headCount,
        totalValue:     totalValue,
        buyer:          buyer,
        totalWeightKg:  totalWeightKg,
        pricePerArroba: pricePerArroba,
        notes:          notes,
      );
}
