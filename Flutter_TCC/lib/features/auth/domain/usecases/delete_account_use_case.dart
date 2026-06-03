import '../repositories/auth_repository.dart';

/// Apaga permanentemente os dados do usuário (LGPD — direito ao esquecimento).
class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.deleteAccount();
}
