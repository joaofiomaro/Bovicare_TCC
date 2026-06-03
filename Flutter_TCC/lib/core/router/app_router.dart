import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/animal/presentation/screens/animal_profile_screen.dart';
import '../../features/animal/presentation/screens/new_animal_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/brete/presentation/screens/brete_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/herd/presentation/screens/herd_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_screen.dart';
import '../../features/vets/presentation/screens/vet_detail_screen.dart';
import '../../features/vets/presentation/screens/vets_list_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'app_routes.dart';

/// Listenable que notifica o GoRouter sempre que o estado de auth muda.
class _AuthChangeListenable extends ChangeNotifier {
  _AuthChangeListenable() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Redirect global — chamado em cada navegação e ao mudar estado de auth.
String? _authRedirect(BuildContext context, GoRouterState state) {
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;
  final location   = state.matchedLocation;

  // Splash gerencia seu próprio redirect — não interferir.
  if (location == AppPaths.splash) return null;

  final isAuthRoute = location == AppPaths.login ||
      location == AppPaths.register;

  // Não autenticado tentando acessar rota protegida → login.
  if (!isLoggedIn && !isAuthRoute) return AppPaths.login;

  // Autenticado tentando acessar login/cadastro → dashboard.
  if (isLoggedIn && isAuthRoute) return AppPaths.dashboard;

  return null;
}

/// Provider do GoRouter — criado uma única vez via Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthChangeListenable();
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation:    AppPaths.splash,
    debugLogDiagnostics: true,
    refreshListenable:  listenable,
    redirect:           _authRedirect,
    routes: [
      GoRoute(
        path:    AppPaths.splash,
        name:    AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path:        AppPaths.login,
        name:        AppRoutes.login,
        pageBuilder: (_, state) => _fadeTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path:        AppPaths.register,
        name:        AppRoutes.register,
        pageBuilder: (_, state) =>
            _slideTransition(state, const RegisterScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path:    AppPaths.dashboard,
            name:    AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path:    AppPaths.herd,
            name:    AppRoutes.herd,
            builder: (_, __) => const HerdListScreen(),
            routes: [
              GoRoute(
                path:        'new',
                name:        AppRoutes.newAnimal,
                pageBuilder: (_, state) =>
                    _slideTransition(state, const NewAnimalScreen()),
              ),
              GoRoute(
                path: ':id',
                name: AppRoutes.animal,
                pageBuilder: (_, state) => _slideTransition(
                  state,
                  AnimalProfileScreen(
                    animalId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'vaccine',
                    name: AppRoutes.vaccination,
                    pageBuilder: (_, state) => _slideTransition(
                      state,
                      VaccinationScreen(
                        animalId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path:    AppPaths.brete,
            name:    AppRoutes.brete,
            builder: (_, __) => const BreteScreen(),
          ),
          GoRoute(
            path:    AppPaths.vets,
            name:    AppRoutes.vets,
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
          GoRoute(
            path:    AppPaths.reports,
            name:    AppRoutes.reports,
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path:    AppPaths.profile,
            name:    AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) =>
    CustomTransitionPage<void>(
      key:                state.pageKey,
      child:              child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) =>
    CustomTransitionPage<void>(
      key:                state.pageKey,
      child:              child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1, 0),
          end:   Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child:    child,
        );
      },
    );
