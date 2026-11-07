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
import '../../../tutorial/presentation/guides.dart';
import '../../../tutorial/presentation/widgets/screen_tutorial.dart';
import '../../../tutorial/presentation/widgets/tutorial_target.dart';
import '../../domain/brete_ble_protocol.dart';
import '../../domain/brete_gateway.dart';
import '../../domain/brete_models.dart';
import '../providers/brete_provider.dart';

/// Painel do brete eletrônico (ESP32): portas, sensores e leitor RFID.
class BreteScreen extends ConsumerStatefulWidget {
  const BreteScreen({super.key});

  @override
  ConsumerState<BreteScreen> createState() => _BreteScreenState();
}

class _BreteScreenState extends ConsumerState<BreteScreen> {
  bool _reading = false;
  bool _restarting = false;
  StreamSubscription<String>? _alerts;

  @override
  void initState() {
    super.initState();
    final gateway = ref.read(breteGatewayProvider);
    _alerts = gateway.alerts.listen((message) {
      if (mounted) AppToast.error(context, message);
    });
    // Conecta ao abrir o painel (no-op se já conectado).
    unawaited(gateway.connect());
  }

  @override
  void dispose() {
    unawaited(_alerts?.cancel());
    super.dispose();
  }

  Future<void> _send(BreteCommand command, [BreteDoor door = BreteDoor.entry]) async {
    try {
      await ref.read(breteGatewayProvider).send(command, door: door);
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

  Future<void> _restart() async {
    final ok = await AppBottomSheet.show(
      context,
      title:        'Reiniciar sistema',
      message:      'As portas param, a emergência é rearmada e a conexão com '
          'o brete é refeita. Use quando algo travar ou não responder.',
      confirmLabel: 'Reiniciar',
      icon:         Icons.power_settings_new_rounded,
      iconColor:    AppColors.brandGreen,
    );
    if (!(ok ?? false) || !mounted) return;
    setState(() => _restarting = true);
    final gateway = ref.read(breteGatewayProvider);
    try {
      await gateway.restart();
      if (!mounted) return;
      if (gateway.current.isOnline) {
        AppToast.success(context, 'Sistema do brete reiniciado.');
      } else {
        AppToast.error(context, gateway.current.errorMessage ?? 'Não foi possível reconectar ao brete.');
      }
    } on BreteException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on Exception catch (_) {
      if (mounted) AppToast.error(context, 'Falha ao reiniciar o brete.');
    } finally {
      if (mounted) setState(() => _restarting = false);
    }
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
    final emergency = status.emergency;
    final firmware  = status.firmwareVersion;

    AnimalEntity? matched;
    if (status.lastRfid != null) {
      for (final a in animals) {
        if (a.rfid == status.lastRfid) {
          matched = a;
          break;
        }
      }
    }

    return ScreenTutorial(
      guide: Guides.brete,
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              title:    'Brete',
              subtitle: switch (gateway.transport) {
                BreteTransport.simulation => 'Modo simulação — sem hardware conectado',
                BreteTransport.ble =>
                  'ESP32 via Bluetooth${firmware != null ? ' · firmware $firmware' : ''}',
                BreteTransport.mqtt => 'ESP32 via MQTT',
              },
              actions: [
                const TutorialHelpButton(),
                TutorialTarget(
                  id:    TutorialIds.breteConnection,
                  child: _ConnectionPill(connection: status.connection),
                ),
              ],
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
                  if (emergency) ...[
                    _EmergencyBanner(stopPressed: status.sensors.stopButton),
                    const SizedBox(height: AppSpacing.base),
                  ],
                  if (status.hasExitDoor)
                    TutorialTarget(
                      id:    TutorialIds.breteDoors,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final d in BreteDoor.values) ...[
                              if (d != BreteDoor.entry) const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _DoorPanel(
                                  title:   d == BreteDoor.entry ? 'Porta de entrada' : 'Porta de saída',
                                  door:    status.doorOf(d),
                                  fault:   status.faultOf(d),
                                  enabled: online && !emergency,
                                  onSend:  (c) => _send(c, d),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    TutorialTarget(
                      id:    TutorialIds.breteDoors,
                      child: _DoorPanel(
                        title:   'Porteira',
                        door:    status.door,
                        enabled: online && !emergency,
                        onSend:  _send,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.base),
                  // Sempre visível; o rearme aparece junto enquanto em == 1.
                  TutorialTarget(
                    id:    TutorialIds.breteEmergency,
                    child: AppButton(
                      label:     'Parada de emergência',
                      icon:      Icons.report_rounded,
                      variant:   AppButtonVariant.danger,
                      onPressed: online ? _emergency : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Rearme (só em emergência) e reinício lado a lado. O reinício
                  // fica liberado mesmo offline: é o caminho para destravar.
                  Row(
                    children: [
                      if (emergency) ...[
                        Expanded(
                          child: AppButton(
                            label:     'Rearmar',
                            icon:      Icons.restart_alt_rounded,
                            variant:   AppButtonVariant.outline,
                            onPressed: online && !_restarting
                                ? () => _send(BreteCommand.reset)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: TutorialTarget(
                          id:    TutorialIds.breteRestart,
                          child: AppButton(
                            label:     'Reiniciar sistema',
                            icon:      Icons.power_settings_new_rounded,
                            variant:   AppButtonVariant.outline,
                            isLoading: _restarting,
                            onPressed: status.connection == BreteConnection.connecting
                                ? null
                                : _restart,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _Label('Animal via RFID'),
                  const SizedBox(height: AppSpacing.sm),
                  TutorialTarget(
                    id:    TutorialIds.breteRfid,
                    child: _RfidCard(
                      status:  status,
                      animal:  matched,
                      reading: _reading,
                      onRead:  online && status.rfidAvailable ? _readRfid : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _Label('Sensores e pedais'),
                  const SizedBox(height: AppSpacing.sm),
                  TutorialTarget(
                    id:    TutorialIds.breteSensors,
                    child: _SensorsCard(sensors: status.sensors, twoDoors: status.hasExitDoor),
                  ),
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

/// Uma porta guilhotina: estado atual e comandos (Parar enquanto se move).
class _DoorPanel extends StatelessWidget {
  const _DoorPanel({
    required this.title,
    required this.door,
    required this.enabled,
    required this.onSend,
    this.fault,
  });

  final String title;
  final DoorState door;

  /// Código da falha (`f1`/`f2`), quando a porta está em FALHA.
  final String? fault;
  final bool enabled;
  final void Function(BreteCommand command) onSend;

  @override
  Widget build(BuildContext context) {
    final (label, sub, color, icon) = switch (door) {
      DoorState.open    => ('Aberta', 'Animal pode passar',
          AppColors.brandGreen, Icons.door_front_door_outlined),
      DoorState.closed  => ('Fechada', 'Passagem bloqueada',
          AppColors.info, Icons.door_front_door_rounded),
      DoorState.moving  => ('Em movimento…', 'Aguarde o fim do curso',
          AppColors.amber, Icons.sync_rounded),
      DoorState.stopped => ('Parada no meio', 'Abra ou feche para continuar',
          AppColors.amber, Icons.pause_circle_outline_rounded),
      DoorState.fault   => ('Em falha',
          'Porta ${BreteBleProtocol.faultLabel(fault ?? '')}. Use Reiniciar sistema',
          AppColors.danger, Icons.error_outline_rounded),
      DoorState.unknown => ('Desconhecido', 'Aguardando o dispositivo',
          AppColors.mutedGreen, Icons.help_outline_rounded),
    };
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border:       Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      // spaceBetween (e não Spacer): sozinho o painel fica num ListView, sem
      // altura limitada; lado a lado, o IntrinsicHeight alinha os botões.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(title, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              Icon(icon, size: 44, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      color,
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, textAlign: TextAlign.center, style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
          Column(
            children: [
              if (door == DoorState.moving)
                AppButton(
                  label:     'Parar',
                  icon:      Icons.stop_rounded,
                  variant:   AppButtonVariant.outline,
                  onPressed: enabled ? () => onSend(BreteCommand.stop) : null,
                )
              else ...[
                AppButton(
                  label:     'Abrir',
                  icon:      Icons.login_rounded,
                  onPressed: enabled && door != DoorState.open && door != DoorState.fault
                      ? () => onSend(BreteCommand.open)
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label:     'Fechar',
                  icon:      Icons.logout_rounded,
                  variant:   AppButtonVariant.outline,
                  onPressed: enabled && door != DoorState.closed && door != DoorState.fault
                      ? () => onSend(BreteCommand.close)
                      : null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.stopPressed});

  /// Botão físico de parada ainda apertado — o rearme será recusado.
  final bool stopPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:        AppColors.danger.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border:       Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.report_rounded, size: 36, color: AppColors.danger),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parada de emergência',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color:      AppColors.danger,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stopPressed
                        ? 'Solte o botão de parada do brete para poder rearmar.'
                        : 'Motores travados — rearme para operar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
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
                    !status.rfidAvailable
                        ? 'Leitor RFID não instalado neste brete'
                        : tag == null
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
  const _SensorsCard({required this.sensors, required this.twoDoors});
  final BreteSensors sensors;

  /// Firmware de duas portas (BLE/simulação) — o MQTT descreve uma porta só.
  final bool twoDoors;

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
          children: twoDoors
              ? [
                  row('Sensor IR — entrada', active: sensors.irEntry, on: 'obstruído', off: 'livre'),
                  row('Sensor IR — saída', active: sensors.irExit, on: 'obstruído', off: 'livre'),
                  row('Botão 1 (entrada)', active: sensors.button1, on: 'apertado', off: 'solto'),
                  row('Botão 2 (saída)', active: sensors.button2, on: 'apertado', off: 'solto'),
                  row('Botão de parada', active: sensors.stopButton, on: 'apertado', off: 'solto'),
                ]
              : [
                  row('Sensor IR superior', active: sensors.irEntry, on: 'obstruído', off: 'livre'),
                  row('Sensor IR inferior', active: sensors.irExit, on: 'obstruído', off: 'livre'),
                  row('Pedal 1 (abrir)', active: sensors.button1, on: 'acionado', off: 'pronto'),
                  row('Pedal 2 (fechar)', active: sensors.button2, on: 'acionado', off: 'pronto'),
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
              const Icon(Icons.link_off_rounded, color: AppColors.danger),
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
