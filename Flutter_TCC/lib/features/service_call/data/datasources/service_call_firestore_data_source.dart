import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/firestore_error_mapper.dart';
import '../../domain/entities/service_call.dart';
import '../models/service_call_model.dart';

/// Acesso à coleção **compartilhada** `serviceCalls/{id}` (produtor ↔ vet).
/// O isolamento por papel é garantido pelas Security Rules (firestore.rules).
class ServiceCallFirestoreDataSource with FirestoreErrorHandler {
  ServiceCallFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('serviceCalls');

  Future<ServiceCallModel> create(ServiceCallModel model) =>
      guardFirestore(() async {
        final ref = _collection.doc(model.id);
        await ref.set(model.toFirestore());
        return model;
      });

  Future<List<ServiceCallModel>> getOpen() => guardFirestore(() async {
        final snap = await _collection
            .where('status', isEqualTo: ServiceStatus.open.name)
            .orderBy('createdAtIso', descending: true)
            .get();
        return snap.docs.map(ServiceCallModel.fromFirestore).toList();
      });

  Future<List<ServiceCallModel>> getForVet(String vetId) =>
      guardFirestore(() async {
        final snap = await _collection
            .where('vetId', isEqualTo: vetId)
            .orderBy('createdAtIso', descending: true)
            .get();
        return snap.docs.map(ServiceCallModel.fromFirestore).toList();
      });

  Future<List<ServiceCallModel>> getForProducer(String producerId) =>
      guardFirestore(() async {
        final snap = await _collection
            .where('producerId', isEqualTo: producerId)
            .orderBy('createdAtIso', descending: true)
            .get();
        return snap.docs.map(ServiceCallModel.fromFirestore).toList();
      });

  /// Aceita um chamado de forma atômica: a transação relê o doc e só aplica
  /// `open → accepted` se ainda estiver aberto (evita corrida entre dois vets).
  Future<void> accept({
    required String callId,
    required String vetId,
    required String vetName,
  }) =>
      guardFirestore(() async {
        final ref = _collection.doc(callId);
        await _firestore.runTransaction((tx) async {
          final snap = await tx.get(ref);
          final data = snap.data();
          if (data == null || data['status'] != ServiceStatus.open.name) {
            throw const ServerFailure(
              'Este chamado já foi aceito por outro veterinário.',
            );
          }
          tx.update(ref, {
            'status':  ServiceStatus.accepted.name,
            'vetId':   vetId,
            'vetName': vetName,
          });
        });
      });

  Future<void> updateStatus({
    required String callId,
    required ServiceStatus status,
    DateTime? scheduledDate,
    String? resolution,
  }) =>
      guardFirestore(() async {
        await _collection.doc(callId).update({
          'status': status.name,
          if (scheduledDate != null)
            'scheduledDateIso': scheduledDate.toIso8601String(),
          if (resolution != null) 'resolution': resolution,
          if (status == ServiceStatus.completed)
            'completedAtIso': DateTime.now().toIso8601String(),
        });
      });

  Future<void> cancel(String callId) => guardFirestore(() async {
        await _collection.doc(callId).update({
          'status': ServiceStatus.cancelled.name,
        });
      });
}
