import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_firebase_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/delete_account_use_case.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/login_with_google_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/register_use_case.dart';
import '../../domain/usecases/update_profile_use_case.dart';

// --- DI ---

final _authDataSourceProvider = Provider<AuthFirebaseDataSource>(
  (_) => AuthFirebaseDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(_authDataSourceProvider)),
);

final _loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final _loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>(
  (ref) => LoginWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final _registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final _logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final _getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>(
  (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)),
);

// --- Estado global de autenticação ---

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() =>
      ref.read(_getCurrentUserUseCaseProvider).call();

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(_loginUseCaseProvider).call(
            email:    email,
            password: password,
          ),
    );
    return state.hasValue && state.value != null;
  }

  /// Retorna false tanto em erro quanto em cancelamento.
  /// Só mostra toast de erro se `state.hasError` for true.
  Future<bool> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(_loginWithGoogleUseCaseProvider).call();
      state = AsyncData(user);
      return user != null;
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(_registerUseCaseProvider).call(
            name:     name,
            email:    email,
            password: password,
            role:     role,
          ),
    );
    return state.hasValue && state.value != null;
  }

  Future<void> logout() async {
    await ref.read(_logoutUseCaseProvider).call();
    state = const AsyncData(null);
  }

  Future<void> updateProfile(UserEntity updated) async {
    await UpdateProfileUseCase(ref.read(authRepositoryProvider)).call(updated);
    state = AsyncData(updated);
  }

  Future<void> deleteAccount() async {
    await DeleteAccountUseCase(ref.read(authRepositoryProvider)).call();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(
  AuthNotifier.new,
);
