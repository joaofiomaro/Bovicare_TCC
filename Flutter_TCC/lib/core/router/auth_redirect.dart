import '../../features/auth/domain/entities/user_entity.dart';
import 'app_routes.dart';

/// Rotas exclusivas do produtor (rebanho, brete, vets, relatórios, chamados
/// do produtor). Um veterinário que chegue aqui volta ao dashboard.
const List<String> _producerOnlyPaths = [
  AppPaths.herd,
  AppPaths.brete,
  AppPaths.vets,
  AppPaths.reports,
  AppPaths.myServiceCalls,
  AppPaths.newServiceCall,
];

/// Rotas exclusivas do veterinário (pool de chamados e agenda).
const List<String> _vetOnlyPaths = [
  AppPaths.vetCalls,
  AppPaths.vetAgenda,
];

bool _isUnder(String location, List<String> paths) =>
    paths.any((p) => location == p || location.startsWith('$p/'));

/// Lógica pura de redirect de autenticação — extraída do GoRouter para ser
/// testável sem depender de Firebase ou BuildContext.
///
/// [role] é o papel do usuário logado quando já conhecido; `null` enquanto o
/// perfil carrega (nesse caso não há restrição por papel).
///
/// Retorna o path de destino para o qual redirecionar, ou `null` quando a
/// navegação para [location] é permitida.
String? authRedirect({
  required bool isLoggedIn,
  required String location,
  UserRole? role,
}) {
  // Splash gerencia seu próprio redirect — não interferir.
  if (location == AppPaths.splash) return null;

  final isAuthRoute =
      location == AppPaths.login || location == AppPaths.register;

  // Não autenticado tentando acessar rota protegida → login.
  if (!isLoggedIn && !isAuthRoute) return AppPaths.login;

  // Autenticado tentando acessar login/cadastro → dashboard.
  if (isLoggedIn && isAuthRoute) return AppPaths.dashboard;

  // Guarda por papel — defesa em profundidade: as Security Rules já isolam
  // os dados, mas a UI não deve nem abrir telas do outro papel.
  if (role == UserRole.vet && _isUnder(location, _producerOnlyPaths)) {
    return AppPaths.dashboard;
  }
  if (role == UserRole.producer && _isUnder(location, _vetOnlyPaths)) {
    return AppPaths.dashboard;
  }

  return null;
}
