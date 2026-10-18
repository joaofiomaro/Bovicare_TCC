import 'package:bovicare/core/router/app_routes.dart';
import 'package:bovicare/core/router/auth_redirect.dart';
import 'package:bovicare/features/auth/domain/entities/user_entity.dart';
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

  group('authRedirect — guarda por papel', () {
    test('veterinário NÃO acessa rotas do produtor → dashboard', () {
      for (final path in [
        AppPaths.herd,
        AppPaths.newAnimal,
        AppPaths.animal('123'),
        AppPaths.brete,
        AppPaths.vets,
        AppPaths.vetDetail('1'),
        AppPaths.reports,
        AppPaths.myServiceCalls,
        AppPaths.newServiceCall,
      ]) {
        expect(
          authRedirect(isLoggedIn: true, location: path, role: UserRole.vet),
          AppPaths.dashboard,
          reason: 'vet em $path',
        );
      }
    });

    test('veterinário acessa as próprias rotas e as compartilhadas', () {
      for (final path in [
        AppPaths.dashboard,
        AppPaths.profile,
        AppPaths.vetCalls,
        AppPaths.vetAgenda,
      ]) {
        expect(
          authRedirect(isLoggedIn: true, location: path, role: UserRole.vet),
          isNull,
          reason: 'vet em $path',
        );
      }
    });

    test('produtor NÃO acessa rotas do veterinário → dashboard', () {
      for (final path in [AppPaths.vetCalls, AppPaths.vetAgenda]) {
        expect(
          authRedirect(
            isLoggedIn: true,
            location:   path,
            role:       UserRole.producer,
          ),
          AppPaths.dashboard,
          reason: 'produtor em $path',
        );
      }
    });

    test('produtor acessa as próprias rotas', () {
      for (final path in [
        AppPaths.herd,
        AppPaths.editAnimal('1'),
        AppPaths.vets,
        AppPaths.reports,
        AppPaths.myServiceCalls,
      ]) {
        expect(
          authRedirect(
            isLoggedIn: true,
            location:   path,
            role:       UserRole.producer,
          ),
          isNull,
          reason: 'produtor em $path',
        );
      }
    });

    test('papel desconhecido (perfil carregando) não restringe', () {
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.vetCalls),
        isNull,
      );
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.herd),
        isNull,
      );
    });

    test('perfil pendente leva à tela "Complete seu cadastro"', () {
      expect(
        authRedirect(
          isLoggedIn:   true,
          location:     AppPaths.dashboard,
          needsProfile: true,
        ),
        AppPaths.completeProfile,
      );
      expect(
        authRedirect(
          isLoggedIn:   true,
          location:     AppPaths.completeProfile,
          needsProfile: true,
        ),
        isNull,
      );
    });

    test('perfil completo não fica preso na tela de completar cadastro', () {
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.completeProfile),
        AppPaths.dashboard,
      );
      expect(
        authRedirect(isLoggedIn: false, location: AppPaths.completeProfile),
        AppPaths.login,
      );
    });

    test('alertas são do produtor e perfil profissional é do vet', () {
      expect(
        authRedirect(isLoggedIn: true, location: AppPaths.alerts, role: UserRole.vet),
        AppPaths.dashboard,
      );
      expect(
        authRedirect(
          isLoggedIn: true,
          location:   AppPaths.vetProfessionalProfile,
          role:       UserRole.producer,
        ),
        AppPaths.dashboard,
      );
      expect(
        authRedirect(
          isLoggedIn: true,
          location:   AppPaths.vetProfessionalProfile,
          role:       UserRole.vet,
        ),
        isNull,
      );
    });

    test('guarda por papel não se aplica a quem não está logado', () {
      expect(
        authRedirect(
          isLoggedIn: false,
          location:   AppPaths.herd,
          role:       UserRole.vet,
        ),
        AppPaths.login,
      );
    });
  });
}
