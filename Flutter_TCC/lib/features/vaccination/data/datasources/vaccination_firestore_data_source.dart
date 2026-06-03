import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../models/vaccination_model.dart';

class VaccinationFirestoreDataSource with FirestoreErrorHandler {
  VaccinationFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users/$_uid/vaccinations');

  Future<List<VaccinationModel>> getAll() => guardFirestore(() async {
        final snapshot =
            await _collection.orderBy('dateIso', descending: true).get();
        return snapshot.docs.map(VaccinationModel.fromFirestore).toList();
      });

  /// Usa índice composto: vaccinations → animalId ASC, dateIso DESC.
  Future<List<VaccinationModel>> getByAnimal(String animalId) =>
      guardFirestore(() async {
        final snapshot = await _collection
            .where('animalId', isEqualTo: animalId)
            .orderBy('dateIso', descending: true)
            .get();
        return snapshot.docs.map(VaccinationModel.fromFirestore).toList();
      });

  Future<void> save(VaccinationModel model) => guardFirestore(() async {
        final ref = _collection.doc(model.id);
        final exists = (await ref.get()).exists;
        final data = model.toFirestore();
        if (exists) {
          await ref
              .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
        } else {
          await ref.set({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

  Future<void> delete(String id) =>
      guardFirestore(() => _collection.doc(id).delete());
}
