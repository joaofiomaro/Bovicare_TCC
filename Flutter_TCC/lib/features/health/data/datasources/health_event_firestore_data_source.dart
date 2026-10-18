import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../../../herd/data/models/animal_model.dart';
import '../../domain/entities/health_event.dart';
import '../models/health_event_model.dart';

class HealthEventFirestoreDataSource with FirestoreErrorHandler {
  HealthEventFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users/$_uid/healthEvents');

  CollectionReference<Map<String, dynamic>> get _animalsCol =>
      _firestore.collection('users/$_uid/animals');

  /// Filtra por igualdade (índice automático) e ordena em memória — evita
  /// depender de índice composto; a lista por animal é pequena.
  Future<List<HealthEvent>> getByAnimal(String animalId) =>
      guardFirestore(() async {
        final snap =
            await _collection.where('animalId', isEqualTo: animalId).get();
        return snap.docs.map(HealthEventModel.fromFirestore).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      });

  Future<List<HealthEvent>> getAll() => guardFirestore(() async {
        final snap =
            await _collection.orderBy('dateIso', descending: true).get();
        return snap.docs.map(HealthEventModel.fromFirestore).toList();
      });

  Future<void> add(HealthEvent event) => guardFirestore(
        () => _collection.doc(event.id).set(_withTimestamps(event)),
      );

  Future<void> registerPregnancy({
    required HealthEvent event,
    required DateTime coverageDate,
  }) =>
      guardFirestore(() async {
        final batch = _firestore.batch()
          ..set(_collection.doc(event.id), _withTimestamps(event))
          ..update(_animalsCol.doc(event.animalId), {
            'status':           'pregnant',
            'pregnancyDateIso': coverageDate.toIso8601String(),
            'updatedAt':        FieldValue.serverTimestamp(),
          });
        await batch.commit();
      });

  Future<void> registerBirth({
    required HealthEvent event,
    AnimalModel? calf,
  }) =>
      guardFirestore(() async {
        final batch = _firestore.batch()
          ..set(_collection.doc(event.id), _withTimestamps(event))
          ..update(_animalsCol.doc(event.animalId), _endPregnancy('healthy'));
        if (calf != null) {
          batch.set(_animalsCol.doc(calf.id), {
            ...calf.toFirestore(),
            'motherId':  event.animalId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      });

  /// Perda gestacional deixa o animal em "Alerta" para acompanhamento.
  Future<void> registerPregnancyLoss(HealthEvent event) =>
      guardFirestore(() async {
        final batch = _firestore.batch()
          ..set(_collection.doc(event.id), _withTimestamps(event))
          ..update(_animalsCol.doc(event.animalId), _endPregnancy('attention'));
        await batch.commit();
      });

  // ---------------------------------------------------------------------------

  Map<String, dynamic> _withTimestamps(HealthEvent event) => {
        ...HealthEventModel.toFirestore(event),
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Encerra a gestação: remove a data de cobertura (o `toFirestore` do
  /// animal omite nulos, então é preciso apagar o campo explicitamente).
  Map<String, dynamic> _endPregnancy(String status) => {
        'status':           status,
        'pregnancyDateIso': FieldValue.delete(),
        'updatedAt':        FieldValue.serverTimestamp(),
      };
}
