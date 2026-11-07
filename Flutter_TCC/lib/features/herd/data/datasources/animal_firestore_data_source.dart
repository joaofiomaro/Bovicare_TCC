import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../models/animal_model.dart';

class AnimalFirestoreDataSource with FirestoreErrorHandler {
  AnimalFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users/$_uid/animals');

  Future<List<AnimalModel>> getAll() => guardFirestore(() async {
        final snapshot = await _collection.orderBy('earTag').get();
        return snapshot.docs.map(AnimalModel.fromFirestore).toList();
      });

  Future<AnimalModel?> getById(String id) => guardFirestore(() async {
        final doc = await _collection.doc(id).get();
        if (!doc.exists) return null;
        return AnimalModel.fromFirestore(doc);
      });

  Future<void> save(AnimalModel model) => guardFirestore(() async {
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

  /// Registra óbito de [animalIds] num único batch (atômico).
  Future<void> recordDeath({
    required List<String> animalIds,
    required DateTime date,
    String? cause,
    String? notes,
  }) =>
      guardFirestore(() async {
        final batch = _firestore.batch();
        for (final id in animalIds) {
          batch.update(_collection.doc(id), {
            'exitType':    'deceased',
            'exitDateIso': date.toIso8601String(),
            if (cause != null) 'deathCause': cause,
            if (notes != null) 'exitNotes':  notes,
            'updatedAt':   FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      });

}
