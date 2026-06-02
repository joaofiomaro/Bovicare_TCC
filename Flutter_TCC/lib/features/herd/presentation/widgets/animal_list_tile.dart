import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/animal_entity.dart';

/// Tile de um animal na lista do rebanho.
/// Swipe para esquerda revela ação de exclusão com confirmação.
class AnimalListTile extends StatelessWidget {
  const AnimalListTile({
    required this.animal,
    required this.onTap,
    required this.onDelete,
    this.animationIndex = 0,
    super.key,
  });

  final AnimalEntity animal;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(animal.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
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
                label: _badgeLabel(animal.status),
                type:  _badgeType(animal.status),
              ),
            ],
          ),
        ),
      ),
    )
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

  String _badgeLabel(AnimalStatus s) => switch (s) {
    AnimalStatus.healthy   => 'Ativo',
    AnimalStatus.pregnant  => 'Prenha',
    AnimalStatus.attention => 'Vacina',
    AnimalStatus.sick      => 'Medicação',
  };

  BadgeType _badgeType(AnimalStatus s) => switch (s) {
    AnimalStatus.healthy   => BadgeType.info,
    AnimalStatus.pregnant  => BadgeType.success,
    AnimalStatus.attention => BadgeType.warning,
    AnimalStatus.sick      => BadgeType.danger,
  };
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
