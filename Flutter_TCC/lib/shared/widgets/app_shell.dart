import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_routes.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Item de uma aba do shell — rota, rótulo e ícones.
class ShellTab {
  const ShellTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

/// Abas da bottom bar conforme o papel do usuário (função pura, testável).
/// Veterinário não acessa Rebanho/Brete; produtor (ou papel nulo) usa o
/// conjunto padrão.
List<ShellTab> tabsForRole(UserRole? role) => switch (role) {
      UserRole.vet => const [
          ShellTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Início', route: AppPaths.dashboard),
          ShellTab(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Chamados', route: AppPaths.vetCalls),
          ShellTab(icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Agenda', route: AppPaths.vetAgenda),
          ShellTab(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Perfil', route: AppPaths.profile),
        ],
      _ => const [
          ShellTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Início', route: AppPaths.dashboard),
          ShellTab(icon: Icons.pets_outlined, activeIcon: Icons.pets, label: 'Rebanho', route: AppPaths.herd),
          ShellTab(icon: Icons.sensor_door_outlined, activeIcon: Icons.sensor_door_rounded, label: 'Brete', route: AppPaths.brete),
          ShellTab(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services_rounded, label: 'Vets', route: AppPaths.vets),
          ShellTab(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Perfil', route: AppPaths.profile),
        ],
    };

/// Índice da aba ativa a partir do path atual (maior prefixo casado).
/// Telas empilhadas fora das abas caem no índice 0 (Início).
int indexFromTabs(List<ShellTab> tabs, String location) {
  var index = 0;
  var bestLen = -1;
  for (var i = 0; i < tabs.length; i++) {
    final route = tabs[i].route;
    if (location.startsWith(route) && route.length > bestLen) {
      index = i;
      bestLen = route.length;
    }
  }
  return index;
}

/// Shell com bottom navigation bar — envolve todas as rotas principais.
/// Observa o papel do usuário e monta as abas correspondentes.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.role;
    final tabs = tabsForRole(role);
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = indexFromTabs(tabs, location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(tabs[i].route),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.activeIcon, color: AppColors.brandGreen),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
