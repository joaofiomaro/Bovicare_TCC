import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../models/sale_model.dart';

class SaleFirestoreDataSource with FirestoreErrorHandler {
  SaleFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users/$_uid/sales');

  CollectionReference<Map<String, dynamic>> get _animalsCol =>
      _firestore.collection('users/$_uid/animals');

  Future<List<SaleModel>> getAll() => guardFirestore(() async {
        final snapshot =
            await _collection.orderBy('dateIso', descending: true).get();
        return snapshot.docs.map(SaleModel.fromFirestore).toList();
      });

  /// Grava a venda e dá baixa em todos os animais no **mesmo batch** (atômico):
  /// ou a venda e todas as baixas são aplicadas, ou nada é.
  Future<void> recordSale(SaleModel model) => guardFirestore(() async {
        final batch = _firestore.batch()
          ..set(_collection.doc(model.id), {
            ...model.toFirestore(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        for (final animalId in model.animalIds) {
          batch.update(_animalsCol.doc(animalId), {
            'exitType':    'sold',
            'exitDateIso': model.dateIso,
            'saleId':      model.id,
            'updatedAt':   FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      });
}
