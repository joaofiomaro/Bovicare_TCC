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
}
