import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/firestore_error_mapper.dart';
import '../domain/entities/user_settings.dart';

/// Preferências do usuário em `users/{uid}/settings/{alerts|consents}` —
/// sincronizadas entre aparelhos e disponíveis offline (cache do Firestore).
class SettingsFirestoreDataSource with FirestoreErrorHandler {
  SettingsFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _firestore.doc('users/${_auth.currentUser!.uid}/settings/$id');

  Future<AlertSettings> getAlerts() => guardFirestore(() async {
        final snap = await _doc('alerts').get();
        return AlertSettings.fromMap(snap.data());
      });

  Future<void> saveAlerts(AlertSettings settings) => guardFirestore(
        () => _doc('alerts').set({
          ...settings.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  Future<ConsentSettings> getConsents() => guardFirestore(() async {
        final snap = await _doc('consents').get();
        return ConsentSettings.fromMap(snap.data());
      });

  Future<void> saveConsents(ConsentSettings consents) => guardFirestore(
        () => _doc('consents').set({
          ...consents.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
}
