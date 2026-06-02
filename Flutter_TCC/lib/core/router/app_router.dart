import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/herd/presentation/screens/herd_list_screen.dart';
import '../../features/animal/presentation/screens/animal_profile_screen.dart';
import '../../features/animal/presentation/screens/new_animal_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_screen.dart';
import '../../features/brete/presentation/screens/brete_screen.dart';
import '../../features/vets/presentation/screens/vets_list_screen.dart';
import '../../features/vets/presentation/screens/vet_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'app_routes.dart';

/// Provider do GoRouter — acessível via ref.watch(appRouterProvider).
final appRouterProvider = Provider<GoRouter>((ref) => _router);

final GoRouter _router = GoRouter(
  initialLocation: AppPaths.splash,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppPaths.splash,
      name: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppPaths.login,
      name: AppRoutes.login,
      pageBuilder: (_, state) => _fadeTransition(state, const LoginScreen()),
    ),
    GoRoute(
      path: AppPaths.register,
      name: AppRoutes.register,
      pageBuilder: (_, state) => _slideTransition(state, const RegisterScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppPaths.dashboard,
          name: AppRoutes.dashboard,
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppPaths.herd,
          name: AppRoutes.herd,
          builder: (_, __) => const HerdListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: AppRoutes.newAnimal,
              pageBuilder: (_, state) => _slideTransition(state, const NewAnimalScreen()),
            ),
            GoRoute(
              path: ':id',
              name: AppRoutes.animal,
              pageBuilder: (_, state) => _slideTransition(
                state,
                AnimalProfileScreen(animalId: state.pathParameters['id']!),
              ),
              routes: [
                GoRoute(
                  path: 'vaccine',
                  name: AppRoutes.vaccination,
                  pageBuilder: (_, state) => _slideTransition(
                    state,
                    VaccinationScreen(animalId: state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(path: AppPaths.brete,   name: AppRoutes.brete,   builder: (_, __) => const BreteScreen()),
        GoRoute(
          path: AppPaths.vets,
          name: AppRoutes.vets,
          builder: (_, __) => const VetsListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: AppRoutes.vetDetail,
              pageBuilder: (_, state) => _slideTransition(
                state,
                VetDetailScreen(vetId: state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(path: AppPaths.reports, name: AppRoutes.reports, builder: (_, __) => const ReportsScreen()),
        GoRoute(path: AppPaths.profile, name: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
