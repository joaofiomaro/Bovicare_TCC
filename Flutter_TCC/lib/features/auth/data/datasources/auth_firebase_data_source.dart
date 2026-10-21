import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/failures.dart';
import '../../../settings/data/settings_firestore_data_source.dart';
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

  /// Subcoleções privadas do usuário — apagadas junto com a conta (LGPD).
  /// Deve refletir a lista aceita em `firestore.rules`. `settings` não pode
  /// ser listada pelas regras: seus documentos são apagados por ID.
  static const List<String> _privateCollections = [
    'animals',
    'vaccinations',
    'sales',
    'weighings',
    'healthEvents',
  ];

  /// Janela em que o Firebase aceita operações sensíveis (`user.delete()`)
  /// sem exigir reautenticação.
  static const Duration _recentLoginWindow = Duration(minutes: 5);

  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fetchUserDoc(result.user!);
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
      return await _fetchUserDoc(result.user!);
    } on Failure {
      rethrow;
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
    final UserCredential result;
    try {
      result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    }

    final user  = result.user!;
    final model = UserModel(id: user.uid, name: name, email: email, role: role);
    try {
      await _userDoc(user.uid).set({
        ...model.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return model;
    } on FirebaseException {
      // Sem o perfil (role) o app não funciona: desfaz o cadastro para não
      // deixar uma conta órfã no Auth e permitir tentar novamente.
      try {
        await user.delete();
      } on FirebaseAuthException catch (_) {
        // Melhor esforço — a conta poderá ser limpa no próximo login.
      }
      throw const ServerFailure(
        'Não foi possível concluir o cadastro. Tente novamente.',
      );
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _userDoc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Encerra a sessão. O signOut do Google é melhor esforço (a conta pode
  /// ter entrado por e-mail/senha ou a plataforma não ter o SDK) — nunca
  /// impede o signOut do Firebase.
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } on Exception catch (_) {
      // Ignorado propositalmente.
    }
    await _auth.signOut();
  }

  /// Atualiza apenas os campos editáveis do perfil. `email` e `role` são
  /// imutáveis (regras do Firestore); `farmName` nulo remove o campo em vez
  /// de manter o valor antigo.
  Future<void> updateProfile(UserModel updated) async {
    try {
      await _userDoc(updated.id).update({
        'name':      updated.name,
        'farmName':  updated.farmName ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const ServerFailure('Não foi possível salvar o perfil.');
    }
  }

  /// Apaga permanentemente a conta e todos os dados privados do usuário
  /// (LGPD — direito ao esquecimento).
  ///
  /// Os chamados (`serviceCalls`) são preservados por auditoria — as regras
  /// do Firestore proíbem exclusão — mas ficam sem vínculo com o perfil.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // O Firebase exige login recente para `user.delete()`. Verificar ANTES
    // de apagar os dados: se falhasse depois, o perfil já teria sido removido
    // e a conta ficaria num estado inconsistente (Auth vivo, dados apagados).
    final lastSignIn = user.metadata.lastSignInTime;
    final isRecent = lastSignIn != null &&
        DateTime.now().difference(lastSignIn) <= _recentLoginWindow;
    if (!isRecent) {
      throw const AuthFailure(
        'Por segurança, saia e faça login novamente antes de excluir a conta.',
      );
    }

    try {
      final userDoc = _userDoc(user.uid);
      for (final name in _privateCollections) {
        await _deleteCollection(userDoc.collection(name));
      }
      // Apagar doc inexistente é permitido e não falha.
      for (final id in SettingsFirestoreDataSource.docIds) {
        await userDoc.collection('settings').doc(id).delete();
      }
      // Perfil público de veterinário (se publicado). Apagar doc
      // inexistente é permitido e não falha.
      await _firestore.doc('vets/${user.uid}').delete();
      await userDoc.delete();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapFirebaseError(e.code));
    } on FirebaseException {
      throw const ServerFailure(
        'Não foi possível excluir todos os dados. Tente novamente.',
      );
    }

    try {
      await _googleSignIn.signOut();
    } on Exception catch (_) {
      // Ignorado propositalmente.
    }
  }

  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Perfil do usuário autenticado. Se ainda não existir (primeiro login com
  /// Google ou cadastro interrompido), exige que ele escolha o papel antes de
  /// entrar — o papel é imutável depois (regras do Firestore).
  Future<UserModel> _fetchUserDoc(User user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    throw const ProfileSetupRequiredFailure();
  }

  /// Cria o perfil do usuário já autenticado com o papel escolhido.
  /// Idempotente: se o perfil já existir, apenas o devolve (nunca sobrescreve
  /// o papel).
  Future<UserModel> completeProfile({
    required String name,
    required String role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure();
    final ref = _userDoc(user.uid);
    final existing = await ref.get();
    if (existing.exists) return UserModel.fromFirestore(existing);

    final model = UserModel(
      id:    user.uid,
      name:  name.trim().isEmpty
          ? (user.displayName ?? user.email!.split('@').first)
          : name.trim(),
      email: user.email!,
      role:  role,
    );
    try {
      await ref.set({
        ...model.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return model;
    } on FirebaseException {
      throw const ServerFailure('Não foi possível concluir o cadastro.');
    }
  }

  /// Envia o e-mail de redefinição de senha do Firebase Auth.
  /// Por segurança, o resultado não revela se o e-mail tem conta.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // user-not-found é tratado como sucesso para não permitir descobrir
      // quais e-mails estão cadastrados (enumeração de contas).
      if (e.code == 'user-not-found') return;
      throw AuthFailure(_mapFirebaseError(e.code));
    }
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
        'invalid-email' => 'E-mail inválido.',
        'email-already-in-use' => 'Este e-mail já está cadastrado.',
        'weak-password' => 'Senha muito fraca. Use ao menos 8 caracteres.',
        'user-disabled' => 'Esta conta foi desativada.',
        'network-request-failed' => 'Sem conexão. Verifique sua internet.',
        'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
        'requires-recent-login' =>
          'Por segurança, saia e faça login novamente antes de continuar.',
        _ => 'Ocorreu um erro. Tente novamente.',
      };
}
