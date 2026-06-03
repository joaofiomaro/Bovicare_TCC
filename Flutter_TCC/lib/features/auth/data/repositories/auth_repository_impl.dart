import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);
  final AuthLocalDataSource _dataSource;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final model = await _dataSource.login(email, password);
    return model.toEntity();
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
  Future<void> deleteAccount() async {
    // Limpa todos os boxes Hive da aplicação antes de apagar as credenciais.
    for (final name in ['animals', 'vaccinations', 'vets']) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<String>(name).clear();
      }
    }
    await _dataSource.deleteAccount();
  }
}
