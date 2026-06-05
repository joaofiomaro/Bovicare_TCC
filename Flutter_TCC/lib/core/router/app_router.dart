import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/brete/presentation/screens/brete_screen.dart';
import '../../features/herd/domain/entities/animal_entity.dart';
import '../../features/herd/presentation/screens/animal_form_screen.dart';
import '../../features/herd/presentation/screens/animal_profile_screen.dart';
import '../../features/herd/presentation/screens/archived_animals_screen.dart';
import '../../features/herd/presentation/screens/herd_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/service_call/presentation/screens/home_dashboard_screen.dart';
import '../../features/service_call/presentation/screens/open_service_call_screen.dart';
import '../../features/service_call/presentation/screens/producer_calls_screen.dart';
import '../../features/service_call/presentation/screens/vet_agenda_screen.dart';
import '../../features/service_call/presentation/screens/vet_calls_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_screen.dart';
import '../../features/vets/presentation/screens/vet_detail_screen.dart';
import '../../features/vets/presentation/screens/vets_list_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

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
/// Delega à função pura [authRedirect] (testável isoladamente).
String? _authRedirect(BuildContext context, GoRouterState state) => authRedirect(
      isLoggedIn: FirebaseAuth.instance.currentUser != null,
      location: state.matchedLocation,
    );

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
            builder: (_, __) => const HomeDashboardScreen(),
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
                    _slideTransition(state, const AnimalFormScreen()),
              ),
              GoRoute(
                path:        'archived',
                name:        AppRoutes.archivedAnimals,
                pageBuilder: (_, state) =>
                    _slideTransition(state, const ArchivedAnimalsScreen()),
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
                    path: 'edit',
                    name: AppRoutes.editAnimal,
                    pageBuilder: (_, state) {
                      final extra = state.extra;
                      final id    = state.pathParameters['id']!;
                      // Reusa o animal vindo por `extra` (sem refetch);
                      // cai no loader por id em deep links sem `extra`.
                      return _slideTransition(
                        state,
                        extra is AnimalEntity
                            ? AnimalFormScreen(initial: extra)
                            : AnimalEditLoader(animalId: id),
                      );
                    },
                  ),
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
          // Chamados — veterinário
          GoRoute(
            path:    AppPaths.vetCalls,
            name:    AppRoutes.vetCalls,
            builder: (_, __) => const VetCallsScreen(),
          ),
          GoRoute(
            path:    AppPaths.vetAgenda,
            name:    AppRoutes.vetAgenda,
            builder: (_, __) => const VetAgendaScreen(),
          ),
          // Chamados — produtor
          GoRoute(
            path:    AppPaths.myServiceCalls,
            name:    AppRoutes.myServiceCalls,
            builder: (_, __) => const ProducerCallsScreen(),
          ),
          GoRoute(
            path:        AppPaths.newServiceCall,
            name:        AppRoutes.newServiceCall,
            pageBuilder: (_, state) =>
                _slideTransition(state, const OpenServiceCallScreen()),
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
