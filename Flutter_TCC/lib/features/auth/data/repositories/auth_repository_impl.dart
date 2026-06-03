import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_firebase_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);
  final AuthFirebaseDataSource _dataSource;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final model = await _dataSource.loginWithEmail(email, password);
    return model.toEntity();
  }

  @override
  Future<UserEntity?> loginWithGoogle() async {
    final model = await _dataSource.loginWithGoogle();
    return model?.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final model = await _dataSource.register(
      name:     name,
      email:    email,
      password: password,
      role:     role.name,
    );
    return model.toEntity();
  }

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final model = await _dataSource.getCurrentUser();
    return model?.toEntity();
  }

  @override
  Future<void> updateProfile(UserEntity updated) =>
      _dataSource.updateProfile(UserModel.fromEntity(updated));

  @override
  Future<void> deleteAccount() => _dataSource.deleteAccount();
}
