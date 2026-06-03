import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

class AuthFirebaseDataSource {
  AuthFirebaseDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fetchOrCreateUserDoc(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    }
  }

  /// Retorna null se o usuário cancelar o fluxo OAuth.
  Future<UserModel?> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return _fetchOrCreateUserDoc(result.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    } on Exception catch (_) {
      throw const AuthFailure(
        'Falha ao conectar com Google. Verifique sua internet.',
      );
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = result.user!.uid;
      final model = UserModel(id: uid, name: name, email: email, role: role);
      await _userDoc(uid).set({
        ...model.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _userDoc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> logout() => Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

  Future<void> updateProfile(UserModel updated) async {
    await _userDoc(updated.id).update({
      ...updated.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _deleteCollection(_userDoc(user.uid).collection('animals'));
    await _deleteCollection(_userDoc(user.uid).collection('vaccinations'));
    await _userDoc(user.uid).delete();
    await user.delete();
  }

  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Primeiro login via Google: cria o documento do usuário se não existir.
  Future<UserModel> _fetchOrCreateUserDoc(User user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);

    final model = UserModel(
      id: user.uid,
      name: user.displayName ?? user.email!.split('@').first,
      email: user.email!,
      role: 'producer',
    );
    await _userDoc(user.uid).set({
      ...model.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return model;
  }

  Future<void> _deleteCollection(CollectionReference<Object?> collection) async {
    QuerySnapshot snapshot;
    do {
      snapshot = await collection.limit(100).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length >= 100);
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'Nenhuma conta encontrada com este e-mail.',
        'wrong-password' => 'Senha incorreta.',
        'invalid-credential' => 'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password' => 'Senha muito fraca. Use ao menos 6 caracteres.',
        'user-disabled' => 'Esta conta foi desativada.',
        'network-request-failed' => 'Sem conexão. Verifique sua internet.',
        'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
        'requires-recent-login' => 'Faça login novamente para continuar.',
        _ => 'Ocorreu um erro. Tente novamente.',
      };
}
