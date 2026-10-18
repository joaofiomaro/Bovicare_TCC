import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/firestore_error_mapper.dart';

/// Portabilidade de dados (LGPD, art. 18, V): reúne tudo o que o app guarda
/// sobre o usuário logado num único JSON legível.
class UserDataExportService with FirestoreErrorHandler {
  UserDataExportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Subcoleções privadas exportadas (mesma lista das Security Rules).
  static const List<String> privateCollections = [
    'animals',
    'vaccinations',
    'healthEvents',
    'weighings',
    'sales',
    'settings',
  ];

  Future<Map<String, dynamic>> collect() => guardFirestore(() async {
        final user = _auth.currentUser!;
        final userDoc = _firestore.doc('users/${user.uid}');

        final profile = (await userDoc.get()).data();
        final collections = <String, dynamic>{};
        for (final name in privateCollections) {
          final snap = await userDoc.collection(name).get();
          collections[name] = [
            for (final d in snap.docs) {'id': d.id, ..._plain(d.data())},
          ];
        }

        final calls = _firestore.collection('serviceCalls');
        final asProducer =
            await calls.where('producerId', isEqualTo: user.uid).get();
        final asVet = await calls.where('vetId', isEqualTo: user.uid).get();
        final vetProfile = await _firestore.doc('vets/${user.uid}').get();

        return {
          'exportadoEm': DateTime.now().toIso8601String(),
          'aplicativo':  'BoviCare',
          'conta': {
            'uid':      user.uid,
            'email':    user.email,
            'provedores': [for (final p in user.providerData) p.providerId],
            'criadaEm': user.metadata.creationTime?.toIso8601String(),
          },
          'perfil': profile == null ? null : _plain(profile),
          'perfilProfissionalPublico':
              vetProfile.exists ? _plain(vetProfile.data()!) : null,
          ...collections,
          'chamadosComoProdutor': [
            for (final d in asProducer.docs) {'id': d.id, ..._plain(d.data())},
          ],
          'chamadosComoVeterinario': [
            for (final d in asVet.docs) {'id': d.id, ..._plain(d.data())},
          ],
        };
      });

  Future<Uint8List> exportJsonBytes() async {
    final data = await collect();
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(utf8.encode(encoder.convert(data)));
  }

  /// Converte tipos do Firestore (Timestamp, GeoPoint, referências) em JSON.
  static Map<String, dynamic> _plain(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, _value(v)));

  static Object? _value(Object? v) => switch (v) {
        final Timestamp t         => t.toDate().toIso8601String(),
        final GeoPoint g          => {'lat': g.latitude, 'lng': g.longitude},
        final DocumentReference r => r.path,
        final Map<String, dynamic> m => _plain(m),
        final List<dynamic> l     => l.map(_value).toList(),
        _                   => v,
      };
}
