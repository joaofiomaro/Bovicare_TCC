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

  /// Únicos documentos aceitos em `settings` pelas Security Rules. As regras
  /// validam o ID do documento, então a coleção NÃO pode ser listada
  /// (`collection.get()` é negado): quem precisa de todos lê/apaga por ID.
  static const List<String> docIds = ['alerts', 'consents'];

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
