import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../providers/vets_provider.dart';
import '../widgets/vet_card.dart';
import '../widgets/vets_map.dart';

class VetsListScreen extends ConsumerStatefulWidget {
  const VetsListScreen({super.key});

  @override
  ConsumerState<VetsListScreen> createState() => _VetsListScreenState();
}

class _VetsListScreenState extends ConsumerState<VetsListScreen> {
  final _searchController = TextEditingController();
  bool _mapExpanded = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vets          = ref.watch(vetsProvider);
    final onlyAvailable = ref.watch(vetAvailableFilterProvider);
    final location      = ref.watch(userLocationProvider);

    final availableCount = vets.maybeWhen(
      data: (list) => list.where((v) => v.isAvailable).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title:    'Veterinários',
            subtitle: vets.maybeWhen(
              data: (_) => '$availableCount disponíveis perto de você',
              orElse: () => null,
            ),
            actions: [
              IconButton(
                tooltip:  onlyAvailable ? 'Mostrar todos' : 'Somente disponíveis',
                icon:     Icon(
                  onlyAvailable
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: () => ref
                    .read(vetAvailableFilterProvider.notifier)
                    .state = !onlyAvailable,
              ),
            ],
          ),

          // Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm,
              AppSpacing.base, AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(vetSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText:  'Buscar por nome ou especialidade…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(vetSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled:    true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border:    const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide:   BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          // Mapa recolhível
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _mapExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, AppSpacing.xs,
                      AppSpacing.base, AppSpacing.xs,
                    ),
                    child: SizedBox(
                      height: 180,
                      child: location.when(
                        loading: () => const AppSkeleton(height: 180),
                        error:   (_, __) => const SizedBox.shrink(),
                        data:    (loc) => vets.maybeWhen(
                          data: (list) => VetsMap(
                            vets:    list,
                            userLat: loc.$1,
                            userLng: loc.$2,
                          ),
                          orElse: () => const AppSkeleton(height: 180),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Cabeçalho da lista com toggle do mapa
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical:   AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mais próximos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _mapExpanded = !_mapExpanded),
                  child: Text(
                    _mapExpanded ? 'Ocultar mapa' : 'Ver mapa',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:      AppColors.brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de vets
          Expanded(
            child: vets.when(
              loading: () => ListView.separated(
                padding:    const EdgeInsets.all(AppSpacing.base),
                itemCount:  4,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, __) => const AnimalListTileSkeleton(),
              ),
              error: (e, _) => AppEmptyState(
                icon:        Icons.error_outline_rounded,
                title:       'Erro ao carregar',
                subtitle:    e.toString(),
                actionLabel: 'Tentar novamente',
                onAction:    () => ref.invalidate(vetsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return AppEmptyState(
                    icon:        Icons.medical_services_outlined,
                    title:       'Nenhum veterinário encontrado',
                    subtitle:    onlyAvailable
                        ? 'Nenhum disponível agora. Tente remover o filtro.'
                        : 'Tente uma busca diferente.',
                    actionLabel: onlyAvailable ? 'Mostrar todos' : null,
                    onAction:    onlyAvailable
                        ? () => ref
                            .read(vetAvailableFilterProvider.notifier)
                            .state = false
                        : null,
                  );
                }
                return RefreshIndicator(
                  color:     AppColors.brandGreen,
                  onRefresh: () async => ref.invalidate(vetsProvider),
                  child: ListView.separated(
                    padding:    const EdgeInsets.all(AppSpacing.base),
                    itemCount:  list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => VetCard(
                      vet:            list[i],
                      animationIndex: i,
                      onTap: () => context.goNamed(
                        AppRoutes.vetDetail,
                        pathParameters: {'id': list[i].id},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
