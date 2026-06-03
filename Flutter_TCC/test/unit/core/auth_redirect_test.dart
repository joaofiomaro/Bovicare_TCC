import 'package:bovicare/core/router/app_routes.dart';
import 'package:bovicare/core/router/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authRedirect', () {
    test('splash nunca é redirecionada (gerencia o próprio fluxo)', () {
      expect(
        authRedirect(isLoggedIn: false, location: AppPaths.splash),
        isNull,
      );
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.splash),
        isNull,
      );
    });

    test('não autenticado em rota protegida → login', () {
      expect(
        authRedirect(isLoggedIn: false, location: AppPaths.dashboard),
        AppPaths.login,
      );
      expect(
        authRedirect(isLoggedIn: false, location: AppPaths.herd),
        AppPaths.login,
      );
    });

    test('não autenticado em rota de auth → permite (sem redirect)', () {
      expect(
        authRedirect(isLoggedIn: false, location: AppPaths.login),
        isNull,
      );
      expect(
        authRedirect(isLoggedIn: false, location: AppPaths.register),
        isNull,
      );
    });

    test('autenticado em login/cadastro → dashboard', () {
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.login),
        AppPaths.dashboard,
      );
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.register),
        AppPaths.dashboard,
      );
    });

    test('autenticado em rota protegida → permite (sem redirect)', () {
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.dashboard),
        isNull,
      );
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.profile),
        isNull,
      );
    });
  });
}
