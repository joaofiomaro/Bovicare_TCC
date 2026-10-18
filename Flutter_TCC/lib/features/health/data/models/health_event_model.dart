import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/health_event.dart';

/// Conversão [HealthEvent] ↔ documento Firestore. Datas em ISO (ordenáveis).
abstract final class HealthEventModel {
  static Map<String, dynamic> toFirestore(HealthEvent e) => {
        'animalId':       e.animalId,
        'type':           e.type.name,
        'dateIso':        e.date.toIso8601String(),
        'title':          e.title,
        'withdrawalDays': e.withdrawalDays,
        if (e.dose != null)             'dose':             e.dose,
        if (e.notes != null)            'notes':            e.notes,
        if (e.veterinarianName != null) 'veterinarianName': e.veterinarianName,
        if (e.calfId != null)           'calfId':           e.calfId,
      };

  static HealthEvent fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return HealthEvent(
      id:       doc.id,
      animalId: d['animalId'] as String,
      type:     HealthEventType.values.asNameMap()[d['type']] ??
          HealthEventType.observation,
      date:             DateTime.parse(d['dateIso'] as String),
      title:            (d['title'] as String?) ?? '',
      dose:             d['dose'] as String?,
      withdrawalDays:   (d['withdrawalDays'] as num?)?.toInt() ?? 0,
      notes:            d['notes'] as String?,
      veterinarianName: d['veterinarianName'] as String?,
      calfId:           d['calfId'] as String?,
    );
  }
}
