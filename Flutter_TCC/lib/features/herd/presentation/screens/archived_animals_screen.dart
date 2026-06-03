import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../domain/entities/animal_entity.dart';
import '../providers/animals_provider.dart';

/// Lista de animais com baixa (vendidos ou óbito). Histórico preservado.
class ArchivedAnimalsScreen extends ConsumerWidget {
  const ArchivedAnimalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archived = ref.watch(archivedAnimalsProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Arquivados',
            subtitle: 'Animais vendidos ou óbito',
            showBack: true,
          ),
          Expanded(
            child: archived.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppEmptyState(
                icon:     Icons.error_outline_rounded,
                title:    'Erro ao carregar',
                subtitle: e.toString(),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const AppEmptyState(
                    icon:     Icons.inventory_2_outlined,
                    title:    'Nenhum animal arquivado',
                    subtitle: 'Vendas e óbitos aparecerão aqui.',
                  );
                }
                return ListView.separated(
                  itemCount:        list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder:      (_, i) => _ArchivedTile(animal: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedTile extends StatelessWidget {
  const _ArchivedTile({required this.animal});
  final AnimalEntity animal;

  @override
  Widget build(BuildContext context) {
    final isSold = animal.exitType == AnimalExitType.sold;
    final dateStr = animal.exitDate?.toBrDate ?? '—';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSold ? AppColors.brandLight : AppColors.dangerLight,
        child: Icon(
          isSold ? Icons.sell_outlined : Icons.heart_broken_outlined,
          color: isSold ? AppColors.brandGreen : AppColors.danger,
          size:  20,
        ),
      ),
      title: Text(
        animal.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${animal.exitType.label} · $dateStr'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical:   AppSpacing.xs,
      ),
      onTap: () => context.goNamed(
        AppRoutes.animal,
        pathParameters: {'id': animal.id},
      ),
    );
  }
}
