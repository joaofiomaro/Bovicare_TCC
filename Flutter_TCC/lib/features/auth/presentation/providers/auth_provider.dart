import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
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

  /// Retorna false em erro ou quando o perfil ainda precisa ser completado
  /// (nesse caso o estado fica `AsyncData(null)` sem erro e o router leva à
  /// tela "Complete seu cadastro").
  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(_loginUseCaseProvider).call(
            email:    email,
            password: password,
          );
      state = AsyncData(user);
      return true;
    } on ProfileSetupRequiredFailure {
      state = const AsyncData(null);
      return false;
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Retorna false tanto em erro quanto em cancelamento ou perfil pendente.
  /// Só mostra toast de erro se `state.hasError` for true.
  Future<bool> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(_loginWithGoogleUseCaseProvider).call();
      state = AsyncData(user);
      return user != null;
    } on ProfileSetupRequiredFailure {
      state = const AsyncData(null);
      return false;
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Cria o perfil com o papel escolhido. Retorna a mensagem de erro, ou
  /// `null` em sucesso.
  Future<String?> completeProfile({
    required String name,
    required UserRole role,
  }) async {
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .completeProfile(name: name, role: role);
      state = AsyncData(user);
      return null;
    } on Failure catch (e) {
      return e.message;
    } on Exception catch (_) {
      return 'Não foi possível concluir o cadastro.';
    }
  }

  /// Envia o e-mail de redefinição. Retorna a mensagem de erro ou `null`.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      return null;
    } on Failure catch (e) {
      return e.message;
    } on Exception catch (_) {
      return 'Não foi possível enviar o e-mail. Tente novamente.';
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

  /// Retorna `false` em caso de falha (o estado atual é preservado).
  Future<bool> updateProfile(UserEntity updated) async {
    try {
      await UpdateProfileUseCase(ref.read(authRepositoryProvider))
          .call(updated);
      state = AsyncData(updated);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Exclui a conta e os dados. Retorna `null` em sucesso ou a mensagem de
  /// erro amigável (ex.: exige login recente).
  Future<String?> deleteAccount() async {
    try {
      await DeleteAccountUseCase(ref.read(authRepositoryProvider)).call();
      state = const AsyncData(null);
      return null;
    } on Failure catch (e) {
      return e.message;
    } on Exception catch (_) {
      return 'Não foi possível excluir a conta. Tente novamente.';
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(
  AuthNotifier.new,
);
