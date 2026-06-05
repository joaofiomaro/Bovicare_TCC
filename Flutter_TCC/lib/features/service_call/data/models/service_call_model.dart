import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/service_call.dart';

part 'service_call_model.freezed.dart';
part 'service_call_model.g.dart';

/// Modelo Firestore do chamado. Enums persistidos por `.name`; datas em ISO
/// (createdAtIso ordena cronologicamente por ordenação lexicográfica).
@freezed
class ServiceCallModel with _$ServiceCallModel {
  const factory ServiceCallModel({
    required String id,
    required String producerId,
    required String producerName,
    required String city,
    required String state,
    required String title,
    required String description,
    required String urgency,
    required String status,
    required String createdAtIso,
    String? farmName,
    double? lat,
    double? lng,
    String? animalEarTag,
    String? vetId,
    String? vetName,
    String? scheduledDateIso,
    String? completedAtIso,
    String? resolution,
  }) = _ServiceCallModel;

  // Freezed exige o construtor privado para métodos customizados.
  // ignore: sort_unnamed_constructors_first
  const ServiceCallModel._();

  factory ServiceCallModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceCallModelFromJson(json);

  factory ServiceCallModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ServiceCallModel(
      id:               doc.id,
      producerId:       d['producerId'] as String,
      producerName:     d['producerName'] as String,
      city:             d['city'] as String,
      state:            d['state'] as String,
      title:            d['title'] as String,
      description:      d['description'] as String,
      urgency:          d['urgency'] as String,
      status:           d['status'] as String,
      createdAtIso:     d['createdAtIso'] as String,
      farmName:         d['farmName'] as String?,
      lat:              (d['lat'] as num?)?.toDouble(),
      lng:              (d['lng'] as num?)?.toDouble(),
      animalEarTag:     d['animalEarTag'] as String?,
      vetId:            d['vetId'] as String?,
      vetName:          d['vetName'] as String?,
      scheduledDateIso: d['scheduledDateIso'] as String?,
      completedAtIso:   d['completedAtIso'] as String?,
      resolution:       d['resolution'] as String?,
    );
  }

  factory ServiceCallModel.fromEntity(ServiceCall c) => ServiceCallModel(
        id:               c.id,
        producerId:       c.producerId,
        producerName:     c.producerName,
        city:             c.city,
        state:            c.state,
        title:            c.title,
        description:      c.description,
        urgency:          c.urgency.name,
        status:           c.status.name,
        createdAtIso:     c.createdAt.toIso8601String(),
        farmName:         c.farmName,
        lat:              c.lat,
        lng:              c.lng,
        animalEarTag:     c.animalEarTag,
        vetId:            c.vetId,
        vetName:          c.vetName,
        scheduledDateIso: c.scheduledDate?.toIso8601String(),
        completedAtIso:   c.completedAt?.toIso8601String(),
        resolution:       c.resolution,
      );

  Map<String, dynamic> toFirestore() => {
        'producerId':   producerId,
        'producerName': producerName,
        'city':         city,
        'state':        state,
        'title':        title,
        'description':  description,
        'urgency':      urgency,
        'status':       status,
        'createdAtIso': createdAtIso,
        if (farmName != null)         'farmName':         farmName,
        if (lat != null)              'lat':              lat,
        if (lng != null)              'lng':              lng,
        if (animalEarTag != null)     'animalEarTag':     animalEarTag,
        if (vetId != null)            'vetId':            vetId,
        if (vetName != null)          'vetName':          vetName,
        if (scheduledDateIso != null) 'scheduledDateIso': scheduledDateIso,
        if (completedAtIso != null)   'completedAtIso':   completedAtIso,
        if (resolution != null)       'resolution':       resolution,
      };

  ServiceCall toEntity() => ServiceCall(
        id:            id,
        producerId:    producerId,
        producerName:  producerName,
        city:          city,
        state:         state,
        title:         title,
        description:   description,
        urgency:       ServiceUrgency.values.byName(urgency),
        status:        ServiceStatus.values.byName(status),
        createdAt:     DateTime.parse(createdAtIso),
        farmName:      farmName,
        lat:           lat,
        lng:           lng,
        animalEarTag:  animalEarTag,
        vetId:         vetId,
        vetName:       vetName,
        scheduledDate: scheduledDateIso != null
            ? DateTime.parse(scheduledDateIso!)
            : null,
        completedAt: completedAtIso != null
            ? DateTime.parse(completedAtIso!)
            : null,
        resolution: resolution,
      );
}
