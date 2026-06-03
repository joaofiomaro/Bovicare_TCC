import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

class AuthLocalDataSource {
  static const _kUserKey    = 'auth_user';
  static const _kSessionKey = 'auth_session';

  Future<UserModel> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kUserKey);
    if (raw == null) {
      throw const AuthFailure('Nenhum cadastro encontrado. Crie uma conta primeiro.');
    }
    final user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (user.email.toLowerCase() != email.toLowerCase()) {
      throw const AuthFailure('E-mail ou senha incorretos.');
    }
    await prefs.setBool(_kSessionKey, true);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final user = UserModel(
      id:    DateTime.now().millisecondsSinceEpoch.toString(),
      name:  name,
      email: email,
      role:  role,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_kSessionKey, true);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSessionKey, false);
  }

  Future<void> updateProfile(UserModel updated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(updated.toJson()));
  }

  /// Remove todos os dados do usuário do SharedPreferences.
  /// A limpeza dos boxes Hive é responsabilidade do AuthRepositoryImpl.
  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs      = await SharedPreferences.getInstance();
    final hasSession = prefs.getBool(_kSessionKey) ?? false;
    if (!hasSession) return null;
    final raw = prefs.getString(_kUserKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
