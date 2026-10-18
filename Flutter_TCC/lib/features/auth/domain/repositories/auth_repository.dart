import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<UserEntity> login({required String email, required String password});

  /// Retorna null se o usuário cancelar o fluxo OAuth do Google.
  Future<UserEntity?> loginWithGoogle();

  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> updateProfile(UserEntity updated);
  Future<void> deleteAccount();

  /// Cria o perfil (papel) do usuário já autenticado — primeiro login com
  /// Google ou cadastro interrompido.
  Future<UserEntity> completeProfile({
    required String name,
    required UserRole role,
  });

  /// Envia o e-mail de redefinição de senha.
  Future<void> sendPasswordReset(String email);
}
