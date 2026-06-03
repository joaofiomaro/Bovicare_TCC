import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vaccination_model.dart';

class VaccinationFirestoreDataSource {
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

  Future<List<VaccinationModel>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map(VaccinationModel.fromFirestore).toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
  }

  /// Ordenação client-side — evita índice composto até ETAPA 4 ser completada.
  Future<List<VaccinationModel>> getByAnimal(String animalId) async {
    final snapshot = await _collection
        .where('animalId', isEqualTo: animalId)
        .get();
    return snapshot.docs.map(VaccinationModel.fromFirestore).toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
  }

  Future<void> save(VaccinationModel model) async {
    final ref = _collection.doc(model.id);
    final exists = (await ref.get()).exists;
    final data = model.toFirestore();
    if (exists) {
      await ref.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await ref.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> delete(String id) => _collection.doc(id).delete();
}
