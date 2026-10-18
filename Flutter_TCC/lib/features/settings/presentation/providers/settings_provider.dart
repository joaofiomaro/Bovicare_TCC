import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/settings_firestore_data_source.dart';
import '../../domain/entities/user_settings.dart';

final settingsDataSourceProvider = Provider<SettingsFirestoreDataSource>(
  (_) => SettingsFirestoreDataSource(),
);

/// Preferências de alerta do usuário logado (padrão se nunca salvas).
class AlertSettingsNotifier extends AsyncNotifier<AlertSettings> {
  @override
  Future<AlertSettings> build() async {
    // Recarrega ao trocar de conta.
    final uid = ref.watch(authProvider).valueOrNull?.id;
    if (uid == null) return const AlertSettings();
    return ref.read(settingsDataSourceProvider).getAlerts();
  }

  Future<bool> save(AlertSettings settings) async {
    final previous = state;
    state = AsyncData(settings);
    try {
      await ref.read(settingsDataSourceProvider).saveAlerts(settings);
      return true;
    } on Exception catch (_) {
      state = previous;
      return false;
    }
  }
}

final alertSettingsProvider =
    AsyncNotifierProvider<AlertSettingsNotifier, AlertSettings>(
  AlertSettingsNotifier.new,
);

/// Consentimentos LGPD do usuário logado.
class ConsentSettingsNotifier extends AsyncNotifier<ConsentSettings> {
  @override
  Future<ConsentSettings> build() async {
    final uid = ref.watch(authProvider).valueOrNull?.id;
    if (uid == null) return const ConsentSettings();
    return ref.read(settingsDataSourceProvider).getConsents();
  }

  Future<bool> setDecision(ConsentPurpose purpose, {required bool granted}) async {
    final previous = state;
    final current  = state.valueOrNull ?? const ConsentSettings();
    final updated  = current.withDecision(purpose, granted: granted);
    state = AsyncData(updated);
    try {
      await ref.read(settingsDataSourceProvider).saveConsents(updated);
      return true;
    } on Exception catch (_) {
      state = previous;
      return false;
    }
  }
}

final consentSettingsProvider =
    AsyncNotifierProvider<ConsentSettingsNotifier, ConsentSettings>(
  ConsentSettingsNotifier.new,
);

/// Atalho: o usuário permite o uso da localização? (padrão: sim — a
/// permissão do sistema operacional continua sendo exigida).
final locationConsentProvider = Provider<bool>((ref) {
  final consents = ref.watch(consentSettingsProvider).valueOrNull;
  return consents?.isGranted(ConsentPurpose.location) ?? true;
});
