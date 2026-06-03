import 'package:cloud_firestore/cloud_firestore.dart';

import 'failures.dart';

/// Converte exceções do Firestore em [Failure] tipadas, com mensagens em PT-BR.
Failure mapFirestoreException(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' ||
      'deadline-exceeded' =>
        const NetworkFailure('Sem conexão. Verifique sua internet.'),
      'permission-denied' =>
        const AuthFailure('Você não tem permissão para acessar estes dados.'),
      'unauthenticated' =>
        const AuthFailure(),
      _ => ServerFailure(
          error.message ?? 'Erro ao comunicar com o servidor.',
        ),
    };
  }
  return const UnknownFailure();
}

/// Mixin para data sources do Firestore: encapsula chamadas mapeando
/// qualquer [FirebaseException] para uma [Failure] amigável.
mixin FirestoreErrorHandler {
  Future<T> guardFirestore<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
