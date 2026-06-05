import 'package:bovicare/core/router/app_routes.dart';
import 'package:bovicare/features/auth/domain/entities/user_entity.dart';
import 'package:bovicare/shared/widgets/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tabsForRole', () {
    test('veterinário não vê Rebanho nem Brete', () {
      final tabs = tabsForRole(UserRole.vet);
      final routes = tabs.map((t) => t.route).toList();
      expect(routes, isNot(contains(AppPaths.herd)));
      expect(routes, isNot(contains(AppPaths.brete)));
      expect(routes, contains(AppPaths.vetCalls));
      expect(routes, contains(AppPaths.vetAgenda));
    });

    test('produtor vê o conjunto padrão', () {
      final routes = tabsForRole(UserRole.producer).map((t) => t.route).toList();
      expect(routes, contains(AppPaths.herd));
      expect(routes, contains(AppPaths.brete));
      expect(routes, contains(AppPaths.vets));
    });

    test('papel nulo cai no conjunto do produtor (fallback)', () {
      expect(tabsForRole(null).map((t) => t.route),
          tabsForRole(UserRole.producer).map((t) => t.route));
    });
  });

  group('indexFromTabs', () {
    test('seleciona a aba pelo maior prefixo casado', () {
      final tabs = tabsForRole(UserRole.producer);
      expect(indexFromTabs(tabs, AppPaths.herd), 1);
      expect(indexFromTabs(tabs, '${AppPaths.herd}/123'), 1);
      expect(indexFromTabs(tabs, AppPaths.profile), 4);
    });

    test('rota fora das abas cai em Início (0)', () {
      final tabs = tabsForRole(UserRole.producer);
      expect(indexFromTabs(tabs, AppPaths.newServiceCall), 0);
    });
  });
}
