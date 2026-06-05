import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import 'vet_dashboard_screen.dart';

/// Dashboard inicial sensível ao papel: veterinário vê [VetDashboardScreen],
/// produtor (ou papel ainda não carregado) vê [DashboardScreen].
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.role;
    return role == UserRole.vet
        ? const VetDashboardScreen()
        : const DashboardScreen();
  }
}
