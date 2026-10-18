import 'package:equatable/equatable.dart';

/// Hierarquia de falhas tipadas — usada em repositórios/data sources no lugar
/// de exceptions cruas. Permite tratamento de erro sem try/catch espalhado
/// pela UI: os providers capturam a [Failure] e a UI exibe [message].
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  /// Garante que `error.toString()` na UI mostre a mensagem amigável,
  /// não o nome técnico da classe.
  @override
  String toString() => message;
}

/// Falha de comunicação com servidor/API (ex.: erro genérico do Firestore).
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro ao comunicar com o servidor.']);
}

/// Sem conexão com a internet ou serviço indisponível.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

/// Usuário não autenticado, sessão expirada ou sem permissão de acesso.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sessão expirada. Faça login novamente.']);
}

/// Usuário autenticado (ex.: primeiro login com Google) ainda sem perfil no
/// Firestore — precisa escolher o papel (produtor/veterinário).
final class ProfileSetupRequiredFailure extends Failure {
  const ProfileSetupRequiredFailure([
    super.message = 'Complete seu cadastro para continuar.',
  ]);
}

/// Falha inesperada — catchall para erros não mapeados.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado.']);
}
