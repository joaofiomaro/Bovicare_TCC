import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../health/presentation/providers/health_events_provider.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../tutorial/presentation/guides.dart';
import '../../../tutorial/presentation/widgets/screen_tutorial.dart';
import '../../../tutorial/presentation/widgets/tutorial_target.dart';
import '../../../vaccination/presentation/providers/vaccinations_provider.dart';
import '../providers/farm_alerts_provider.dart';
import '../widgets/farm_alert_tile.dart';

/// Central de alertas do rebanho (vacinas, partos e carência).
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts   = ref.watch(farmAlertsProvider);
    final leadDays = ref.watch(alertSettingsProvider).valueOrNull?.leadDays ?? 30;

    Future<void> refresh() async {
      ref
        ..invalidate(animalsProvider)
        ..invalidate(allVaccinationsProvider)
        ..invalidate(allHealthEventsProvider);
    }

    return ScreenTutorial(
      guide: Guides.alerts,
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              title:    'Alertas',
              subtitle: 'Próximos $leadDays dias',
              showBack: true,
              actions: [
                const TutorialHelpButton(),
                TutorialTarget(
                  id:    TutorialIds.alertsSettings,
                  child: IconButton(
                    tooltip:   'Configurar alertas',
                    icon:      const Icon(Icons.tune_rounded, color: Colors.white),
                    onPressed: () => context.pushNamed(AppRoutes.alertSettings),
                  ),
                ),
              ],
            ),
            Expanded(
              child: TutorialTarget(
                id:    TutorialIds.alertsList,
                child: alerts.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: context.palette.brand),
                  ),
                  error: (e, _) => AppEmptyState(
                    icon:        Icons.error_outline_rounded,
                    title:       'Erro ao carregar',
                    subtitle:    friendlyError(e),
                    actionLabel: 'Tentar novamente',
                    onAction:    refresh,
                  ),
                  data: (list) => list.isEmpty
                      ? const AppEmptyState(
                          icon:     Icons.notifications_none_rounded,
                          title:    'Nenhum alerta',
                          subtitle: 'Vacinas, partos e carências em dia.',
                        )
                      : RefreshIndicator(
                          color:     AppColors.brandGreen,
                          onRefresh: refresh,
                          child: ListView.separated(
                            padding:   const EdgeInsets.symmetric(vertical: 8),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => FarmAlertTile(alert: list[i]),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
