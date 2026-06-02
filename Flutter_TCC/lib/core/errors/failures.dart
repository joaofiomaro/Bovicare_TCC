import 'package:equatable/equatable.dart';

/// Hierarquia de falhas tipadas — usada em repositórios no lugar de exceptions.
/// Permite tratamento de erro sem try/catch espalhado pela UI.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Falha de comunicação com servidor/API.
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro ao comunicar com o servidor.']);
}

/// Dado não encontrado no cache/banco local.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Nenhum dado local encontrado.']);
}

/// Sem conexão com a internet.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

/// Usuário não autenticado ou token expirado.
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sessão expirada. Faça login novamente.']);
}

/// Entrada inválida pelo usuário.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Falha inesperada — catchall para erros não mapeados.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado.']);
}
