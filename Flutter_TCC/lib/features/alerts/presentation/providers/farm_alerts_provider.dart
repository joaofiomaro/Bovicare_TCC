import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/parallel.dart';
import '../../../health/presentation/providers/health_events_provider.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../vaccination/presentation/providers/vaccinations_provider.dart';
import '../../domain/farm_alerts.dart';

/// Alertas do rebanho conforme as preferências salvas.
final farmAlertsProvider = FutureProvider<List<FarmAlert>>((ref) async {
  final (animals, vaccinations, events, settings) = await (
    ref.watch(animalsProvider.future),
    ref.watch(allVaccinationsProvider.future),
    ref.watch(allHealthEventsProvider.future),
    ref.watch(alertSettingsProvider.future),
  ).waitFirstError;

  return buildFarmAlerts(
    animals:      animals,
    vaccinations: vaccinations,
    healthEvents: events,
    settings:     settings,
    now:          DateTime.now(),
  );
});
