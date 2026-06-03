import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../models/weighing_model.dart';

class WeighingFirestoreDataSource with FirestoreErrorHandler {
  WeighingFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users/$_uid/weighings');

  CollectionReference<Map<String, dynamic>> get _animalsCol =>
      _firestore.collection('users/$_uid/animals');

  /// Pesagens de um animal, ordenadas da mais recente para a mais antiga.
  /// Filtra por igualdade (índice automático) e ordena em memória — a lista
  /// de pesagens por animal é pequena, evitando depender de índice composto.
  Future<List<WeighingModel>> getByAnimal(String animalId) =>
      guardFirestore(() async {
        final snapshot =
            await _collection.where('animalId', isEqualTo: animalId).get();
        return snapshot.docs.map(WeighingModel.fromFirestore).toList()
          ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
      });

  /// Grava a pesagem e atualiza o peso atual do animal no **mesmo batch**
  /// (atômico): ou ambos são aplicados, ou nada é.
  Future<void> add(WeighingModel model) => guardFirestore(() async {
        final batch = _firestore.batch()
          ..set(_collection.doc(model.id), {
            ...model.toFirestore(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..update(_animalsCol.doc(model.animalId), {
            'weightKg':  model.weightKg,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        await batch.commit();
      });
}
