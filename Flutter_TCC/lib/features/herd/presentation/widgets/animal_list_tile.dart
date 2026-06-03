import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/animal_entity.dart';
import '../extensions/animal_status_visuals.dart';

/// Tile de um animal na lista do rebanho.
/// - Modo normal: swipe para a esquerda revela exclusão com confirmação.
/// - Modo seleção: toque alterna a seleção (para baixa em lote), sem swipe.
class AnimalListTile extends StatelessWidget {
  const AnimalListTile({
    required this.animal,
    required this.onTap,
    required this.onDelete,
    this.animationIndex = 0,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    super.key,
  });

  final AnimalEntity animal;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int animationIndex;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectToggle;

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: selectionMode ? onSelectToggle : onTap,
      onLongPress: selectionMode ? null : onSelectToggle,
      child: ColoredBox(
        color: selected
            ? AppColors.brandPale
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (selectionMode)
                _SelectIndicator(selected: selected)
              else
                _StatusIcon(status: animal.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(animal),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedGreen,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(
                label: animal.status.label,
                type:  animal.status.badge,
              ),
            ],
          ),
        ),
      ),
    );

    // Em modo seleção não há swipe-to-delete (evita ações conflitantes).
    final tile = selectionMode
        ? content
        : Dismissible(
            key: ValueKey(animal.id),
            direction: DismissDirection.endToStart,
            background: _DeleteBackground(),
            confirmDismiss: (_) => _confirmDelete(context),
            onDismissed: (_) => onDelete(),
            child: content,
          );

    return tile
        .animate(delay: Duration(milliseconds: animationIndex * 40))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover animal'),
        content: Text('Deseja remover ${animal.displayName} do rebanho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  String _subtitle(AnimalEntity a) {
    final age = a.ageInYears > 0
        ? '${a.ageInYears} ${a.ageInYears == 1 ? 'ano' : 'anos'}'
        : '${a.ageInMonths} meses';
    final weight = a.weightKg != null ? ' · ${a.weightKg!.toStringAsFixed(0)} kg' : '';
    return '${a.breed} · ${a.sexLabel} · $age$weight';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final AnimalStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, color) = switch (status) {
      AnimalStatus.healthy   => (AppColors.infoLight,    AppColors.info),
      AnimalStatus.pregnant  => (AppColors.brandLight,   AppColors.brandGreen),
      AnimalStatus.attention => (AppColors.amberLight,   AppColors.amber),
      AnimalStatus.sick      => (AppColors.dangerLight,  AppColors.danger),
    };
    return Container(
      width:  44,
      height: 44,
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.all(Radius.circular(12))),
      child: Icon(Icons.pets_rounded, color: color, size: 22),
    );
  }
}

class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? AppColors.brandGreen : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: selected ? AppColors.brandGreen : AppColors.mutedGreen,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: AppColors.white, size: 22)
          : null,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: AppColors.dangerLight,
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
    );
  }
}
