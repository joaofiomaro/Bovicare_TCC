import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_chip_filter.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../providers/animals_provider.dart';
import '../widgets/animal_list_tile.dart';

class HerdListScreen extends ConsumerStatefulWidget {
  const HerdListScreen({super.key});

  @override
  ConsumerState<HerdListScreen> createState() => _HerdListScreenState();
}

class _HerdListScreenState extends ConsumerState<HerdListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animals       = ref.watch(filteredAnimalsProvider);
    final currentFilter = ref.watch(herdFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title:    'Rebanho',
            subtitle: animals.maybeWhen(
              data: (list) => '${list.length} ${list.length == 1 ? 'animal' : 'animais'}',
              orElse: () => null,
            ),
            actions: [
              IconButton(
                onPressed: () => context.goNamed(AppRoutes.newAnimal),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                tooltip: 'Adicionar animal',
              ),
            ],
          ),
          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => ref.read(herdSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText:    'Buscar por brinco, nome ou RFID…',
                prefixIcon:  const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(herdSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled:      true,
                fillColor:   Theme.of(context).colorScheme.surfaceContainerHighest,
                border:      const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide:   BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Chips de filtro
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppChipFilter<HerdFilter>(
              options: const [
                ChipOption(label: 'Todos',   value: HerdFilter.all),
                ChipOption(label: 'Fêmeas',  value: HerdFilter.females),
                ChipOption(label: 'Machos',  value: HerdFilter.males),
                ChipOption(label: 'Prenhas', value: HerdFilter.pregnant),
                ChipOption(label: 'Alertas', value: HerdFilter.alerts, icon: Icons.warning_amber_rounded),
              ],
              selected: {currentFilter},
              onSelected: (value, {required isSelected}) =>
                  ref.read(herdFilterProvider.notifier).state = value,
            ),
          ),
          const Divider(height: 1),
          // Lista
          Expanded(
            child: animals.when(
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: AnimalListTileSkeleton(),
                ),
              ),
              error: (e, _) => AppEmptyState(
                icon:        Icons.error_outline_rounded,
                title:       'Erro ao carregar',
                subtitle:    e.toString(),
                actionLabel: 'Tentar novamente',
                onAction:    () => ref.invalidate(animalsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return AppEmptyState(
                    icon:        Icons.pets_rounded,
                    title:       'Nenhum animal encontrado',
                    subtitle:    'Tente outro filtro ou cadastre um novo animal.',
                    actionLabel: 'Cadastrar',
                    onAction:    () => context.goNamed(AppRoutes.newAnimal),
                  );
                }
                return RefreshIndicator(
                  color:     AppColors.brandGreen,
                  onRefresh: () async => ref.invalidate(animalsProvider),
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => AnimalListTile(
                      animal:         list[i],
                      animationIndex: i,
                      onTap:   () => context.goNamed(
                        AppRoutes.animal,
                        pathParameters: {'id': list[i].id},
                      ),
                      onDelete: () async {
                        final ok = await ref
                            .read(animalsProvider.notifier)
                            .delete(list[i].id);
                        if (context.mounted) {
                          if (ok) {
                            AppToast.success(context, 'Animal removido.');
                          } else {
                            AppToast.error(
                                context, 'Erro ao remover. Tente novamente.');
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:       () => context.goNamed(AppRoutes.newAnimal),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
        tooltip:         'Adicionar animal',
        child:           const Icon(Icons.add_rounded),
      ),
    );
  }
}
