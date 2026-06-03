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
        var snapshot = await _collection.orderBy('earTag').get();
        if (snapshot.docs.isEmpty) {
          await _seed();
          snapshot = await _collection.orderBy('earTag').get();
        }
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

  // ---------------------------------------------------------------------------

  /// Popula a coleção com animais demonstrativos na primeira execução do usuário.
  Future<void> _seed() async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    for (final model in _buildSeed(now)) {
      batch.set(_collection.doc(model.id), {
        ...model.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  List<AnimalModel> _buildSeed(DateTime now) => [
        AnimalModel(
          id: '1', earTag: '047', name: 'Mimosa', breed: 'Nelore',
          sex: 'female', status: 'pregnant', birthDateIso: '2022-03-12',
          weightKg: 384,
          pregnancyDateIso:
              DateTime(now.year - 1, 10, 10).toIso8601String(),
        ),
        const AnimalModel(
          id: '2', earTag: '031', name: 'Estrela', breed: 'Gir',
          sex: 'female', status: 'attention', birthDateIso: '2020-01-20',
          weightKg: 410,
        ),
        const AnimalModel(
          id: '3', earTag: '003', name: 'Touro 01', breed: 'Nelore',
          sex: 'male', status: 'healthy', birthDateIso: '2021-06-15',
          weightKg: 620,
        ),
        const AnimalModel(
          id: '4', earTag: '058', name: 'Bela', breed: 'Gir',
          sex: 'female', status: 'sick', birthDateIso: '2023-02-08',
          weightKg: 290,
        ),
        const AnimalModel(
          id: '5', earTag: '072', name: 'Pintada', breed: 'Nelore',
          sex: 'female', status: 'healthy', birthDateIso: '2021-09-30',
          weightKg: 360,
        ),
        AnimalModel(
          id: '6', earTag: '089', name: 'Aurora', breed: 'Girolando',
          sex: 'female', status: 'pregnant', birthDateIso: '2022-07-04',
          weightKg: 395,
          pregnancyDateIso:
              DateTime(now.year - 1, 8, 20).toIso8601String(),
        ),
        const AnimalModel(
          id: '7', earTag: '012', name: 'Bravo', breed: 'Brahman',
          sex: 'male', status: 'healthy', birthDateIso: '2019-04-18',
          weightKg: 710,
        ),
      ];
}
