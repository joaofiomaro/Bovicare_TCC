import 'app_routes.dart';

/// Lógica pura de redirect de autenticação — extraída do GoRouter para ser
/// testável sem depender de Firebase ou BuildContext.
///
/// Retorna o path de destino para o qual redirecionar, ou `null` quando a
/// navegação para [location] é permitida.
String? authRedirect({required bool isLoggedIn, required String location}) {
  // Splash gerencia seu próprio redirect — não interferir.
  if (location == AppPaths.splash) return null;

  final isAuthRoute =
      location == AppPaths.login || location == AppPaths.register;

  // Não autenticado tentando acessar rota protegida → login.
  if (!isLoggedIn && !isAuthRoute) return AppPaths.login;

  // Autenticado tentando acessar login/cadastro → dashboard.
  if (isLoggedIn && isAuthRoute) return AppPaths.dashboard;

  return null;
}
