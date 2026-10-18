import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../herd/domain/entities/animal_entity.dart';
import '../../../herd/presentation/providers/animals_provider.dart';
import '../../domain/brete_gateway.dart';
import '../../domain/brete_models.dart';
import '../providers/brete_provider.dart';

/// Painel do brete eletrônico (ESP32): porteira, sensores e leitor RFID.
class BreteScreen extends ConsumerStatefulWidget {
  const BreteScreen({super.key});

  @override
  ConsumerState<BreteScreen> createState() => _BreteScreenState();
}

class _BreteScreenState extends ConsumerState<BreteScreen> {
  bool _reading = false;

  @override
  void initState() {
    super.initState();
    // Conecta ao abrir o painel (no-op se já conectado).
    unawaited(ref.read(breteGatewayProvider).connect());
  }

  Future<void> _send(BreteCommand command) async {
    try {
      await ref.read(breteGatewayProvider).send(command);
    } on BreteException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on Exception catch (_) {
      if (mounted) AppToast.error(context, 'Falha ao enviar o comando.');
    }
  }

  Future<void> _emergency() async {
    final ok = await AppBottomSheet.show(
      context,
      title:          'Parada de emergência',
      message:        'O mecanismo será travado imediatamente. Para voltar a '
          'operar será necessário o rearme.',
      confirmLabel:   'Parar agora',
      confirmVariant: AppButtonVariant.danger,
      icon:           Icons.report_rounded,
      iconColor:      AppColors.danger,
    );
    if (ok ?? false) await _send(BreteCommand.emergencyStop);
  }

  Future<void> _readRfid() async {
    setState(() => _reading = true);
    final tag = await ref.read(breteGatewayProvider).readNextRfid();
    if (!mounted) return;
    setState(() => _reading = false);
    if (tag == null) {
      AppToast.error(context, 'Nenhuma tag lida. Aproxime o animal do leitor.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateway = ref.watch(breteGatewayProvider);
    final status  = ref.watch(breteStatusProvider).valueOrNull ?? gateway.current;
    final animals = ref.watch(animalsProvider).valueOrNull ?? const <AnimalEntity>[];
    final online  = status.isOnline;
    final emergency = status.door == DoorState.emergency;

    AnimalEntity? matched;
    if (status.lastRfid != null) {
      for (final a in animals) {
        if (a.rfid == status.lastRfid) {
          matched = a;
          break;
        }
      }
    }

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title:    'Brete',
            subtitle: gateway.isSimulation
                ? 'Modo simulação — sem hardware conectado'
                : 'ESP32 via MQTT',
            actions: [_ConnectionPill(connection: status.connection)],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                if (status.connection == BreteConnection.error ||
                    status.connection == BreteConnection.disconnected)
                  _ErrorCard(
                    message: status.errorMessage ??
                        'Brete desconectado.',
                    onRetry: () => ref.read(breteGatewayProvider).connect(),
                  ),
                _DoorHero(door: status.door),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label:     'Abrir',
                        icon:      Icons.login_rounded,
                        onPressed: online && !emergency
                            ? () => _send(BreteCommand.open)
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label:     'Fechar',
                        icon:      Icons.logout_rounded,
                        variant:   AppButtonVariant.outline,
                        onPressed: online && !emergency
                            ? () => _send(BreteCommand.close)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (emergency)
                  AppButton(
                    label:     'Rearmar brete',
                    icon:      Icons.restart_alt_rounded,
                    variant:   AppButtonVariant.outline,
                    onPressed: online ? () => _send(BreteCommand.reset) : null,
                  )
                else
                  AppButton(
                    label:     'Parada de emergência',
                    icon:      Icons.report_rounded,
                    variant:   AppButtonVariant.danger,
                    onPressed: online ? _emergency : null,
                  ),
                const SizedBox(height: AppSpacing.xl),
                const _Label('Animal via RFID'),
                const SizedBox(height: AppSpacing.sm),
                _RfidCard(
                  status:  status,
                  animal:  matched,
                  reading: _reading,
                  onRead:  online ? _readRfid : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _Label('Sensores e pedais'),
                const SizedBox(height: AppSpacing.sm),
                _SensorsCard(sensors: status.sensors),
                if (status.lastUpdate != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Atualizado em ${status.lastUpdate!.toBrDateTime}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedGreen,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x2l),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.connection});
  final BreteConnection connection;

  @override
  Widget build(BuildContext context) {
    final (label, type) = switch (connection) {
      BreteConnection.connected    => ('Conectado', BadgeType.success),
      BreteConnection.simulated    => ('Simulação', BadgeType.info),
      BreteConnection.connecting   => ('Conectando…', BadgeType.warning),
      BreteConnection.disconnected => ('Offline', BadgeType.neutral),
      BreteConnection.error        => ('Erro', BadgeType.danger),
    };
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: AppBadge(label: label, type: type),
    );
  }
}

class _DoorHero extends StatelessWidget {
  const _DoorHero({required this.door});
  final DoorState door;

  @override
  Widget build(BuildContext context) {
    final (label, sub, color, icon) = switch (door) {
      DoorState.open      => ('Porta aberta', 'Animal pode entrar ou sair',
          AppColors.brandGreen, Icons.door_front_door_outlined),
      DoorState.closed    => ('Porta fechada', 'Travamento mecânico ativo',
          AppColors.info, Icons.door_front_door_rounded),
      DoorState.moving    => ('Em movimento…', 'Aguarde o fim do curso',
          AppColors.amber, Icons.sync_rounded),
      DoorState.emergency => ('Parada de emergência', 'Motor travado — rearme para operar',
          AppColors.danger, Icons.report_rounded),
      DoorState.unknown   => ('Estado desconhecido', 'Aguardando o dispositivo',
          AppColors.mutedGreen, Icons.help_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border:       Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      color,
                ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RfidCard extends StatelessWidget {
  const _RfidCard({
    required this.status,
    required this.animal,
    required this.reading,
    required this.onRead,
  });

  final BreteStatus status;
  final AnimalEntity? animal;
  final bool reading;
  final VoidCallback? onRead;

  @override
  Widget build(BuildContext context) {
    final tag = status.lastRfid;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rss_feed_rounded, color: AppColors.brandGreen),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tag == null
                        ? 'Nenhuma leitura ainda'
                        : 'RFID $tag'
                            '${status.lastRfidAt != null ? ' · ${status.lastRfidAt!.toTimelineLabel}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (tag != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                animal != null
                    ? '${animal!.displayName} · ${animal!.breed}'
                    : 'Tag não cadastrada no rebanho.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: animal != null ? AppColors.brandGreen : AppColors.amber,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label:     'Ler tag',
                    icon:      Icons.qr_code_scanner_rounded,
                    variant:   AppButtonVariant.outline,
                    isLoading: reading,
                    onPressed: onRead,
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: animal != null ? 'Ver ficha' : 'Cadastrar',
                      icon:  animal != null
                          ? Icons.pets_rounded
                          : Icons.add_rounded,
                      onPressed: () => animal != null
                          ? context.pushNamed(
                              AppRoutes.animal,
                              pathParameters: {'id': animal!.id},
                            )
                          : context.pushNamed(
                              AppRoutes.newAnimal,
                              extra: tag,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorsCard extends StatelessWidget {
  const _SensorsCard({required this.sensors});
  final BreteSensors sensors;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, {required bool active, required String on, required String off}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.amber : AppColors.brandGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('$label — ${active ? on : off}')),
            ],
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        child: Column(
          children: [
            row('Sensor IR superior', active: sensors.irTop, on: 'obstruído', off: 'livre'),
            row('Sensor IR inferior', active: sensors.irBottom, on: 'obstruído', off: 'livre'),
            row('Pedal 1 (abrir)', active: sensors.pedalOpen, on: 'acionado', off: 'pronto'),
            row('Pedal 2 (fechar)', active: sensors.pedalClose, on: 'acionado', off: 'pronto'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color:        AppColors.dangerLight,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(message, style: const TextStyle(color: AppColors.danger)),
              ),
              TextButton(onPressed: onRetry, child: const Text('Reconectar')),
            ],
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );
}
