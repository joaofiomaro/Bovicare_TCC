import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_routes.dart';

/// Shell com bottom navigation bar — envolve todas as rotas principais.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,         label: 'Início',  route: AppPaths.dashboard),
    _TabItem(icon: Icons.pets_outlined,       activeIcon: Icons.pets,                 label: 'Rebanho', route: AppPaths.herd),
    _TabItem(icon: Icons.sensor_door_outlined,activeIcon: Icons.sensor_door_rounded,  label: 'Brete',   route: AppPaths.brete),
    _TabItem(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services_rounded, label: 'Vets', route: AppPaths.vets),
    _TabItem(icon: Icons.person_outline,      activeIcon: Icons.person_rounded,       label: 'Perfil',  route: AppPaths.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].route),
        destinations: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          return NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.activeIcon, color: AppColors.brandGreen),
            label: tab.label,
          );
        }),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppPaths.herd))    return 1;
    if (location.startsWith(AppPaths.brete))   return 2;
    if (location.startsWith(AppPaths.vets))    return 3;
    if (location.startsWith(AppPaths.profile)) return 4;
    return 0;
  }
}

class _TabItem {
  const _TabItem({
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
