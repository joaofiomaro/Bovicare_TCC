import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../models/vet_model.dart';

/// Diretório público de veterinários — `vets/{uid}`.
/// Leitura: qualquer usuário logado. Escrita: só o próprio veterinário
/// (garantido pelas Security Rules).
class VetFirestoreDataSource with FirestoreErrorHandler {
  VetFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('vets');

  Future<List<VetModel>> getAll() => guardFirestore(() async {
        final snap = await _collection.get();
        return snap.docs.map(VetModel.fromFirestore).toList();
      });

  Future<VetModel?> getById(String id) => guardFirestore(() async {
        final doc = await _collection.doc(id).get();
        return doc.exists ? VetModel.fromFirestore(doc) : null;
      });

  Future<void> save(VetModel model) => guardFirestore(
        () => _collection.doc(model.id).set({
          ...model.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  Future<void> delete(String id) =>
      guardFirestore(() => _collection.doc(id).delete());
}
