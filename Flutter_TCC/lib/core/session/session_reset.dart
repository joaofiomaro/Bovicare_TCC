import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/alerts/presentation/providers/farm_alerts_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/health/presentation/providers/health_events_provider.dart';
import '../../features/herd/presentation/providers/animals_provider.dart';
import '../../features/herd/presentation/providers/sales_provider.dart';
import '../../features/reports/presentation/providers/report_provider.dart';
import '../../features/vaccination/presentation/providers/vaccinations_provider.dart';
import '../../features/vets/presentation/providers/vets_provider.dart';

/// Providers globais (não `autoDispose`) que guardam dados **do usuário
/// logado**. Ficam em cache durante toda a vida do app; por isso precisam ser
/// descartados quando a conta muda.
final List<ProviderOrFamily> userScopedProviders = [
  animalsProvider,
  salesProvider,
  dashboardProvider,
  allHealthEventsProvider,
  allVaccinationsProvider,
  farmAlertsProvider,
  reportProvider,
  vetsProvider,
  // Filtros/buscas da sessão anterior não devem "vazar" para a próxima conta.
  herdFilterProvider,
  herdSearchProvider,
  reportFilterProvider,
  vetSearchProvider,
  vetAvailableFilterProvider,
];

/// Observa o uid da sessão e, quando ele muda (logout, troca de conta ou
/// exclusão), invalida [userScopedProviders]. Sem isso, quem saísse e
/// entrasse com outra conta sem fechar o app veria o rebanho, as vendas e o
/// dashboard da conta anterior.
///
/// Mantido vivo por `ref.watch(sessionResetProvider)` na raiz do app.
final sessionResetProvider = Provider<void>((ref) {
  ref.listen<String?>(
    authProvider.select((auth) => auth.valueOrNull?.id),
    (previous, next) {
      if (previous == next) return;
      for (final provider in userScopedProviders) {
        ref.invalidate(provider);
      }
    },
  );
});
