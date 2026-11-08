import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../tutorial/presentation/guides.dart';
import '../../../tutorial/presentation/widgets/screen_tutorial.dart';
import '../../../tutorial/presentation/widgets/tutorial_target.dart';
import '../../domain/entities/vet_entity.dart';
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

  /// Relê o GPS e recalcula distâncias/ordenação (pull-to-refresh).
  Future<void> _refresh() async {
    ref
      ..invalidate(userLocationProvider)
      ..invalidate(vetsProvider);
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
    final usingFallback = location.valueOrNull?.isFallback ?? false;

    return ScreenTutorial(
      guide: Guides.vetsList,
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              title:    'Veterinários',
              subtitle: vets.maybeWhen(
                data: (_) => usingFallback
                    ? '$availableCount disponíveis na região de referência'
                    : '$availableCount disponíveis perto de você',
                orElse: () => null,
              ),
              actions: [
                const TutorialHelpButton(),
                TutorialTarget(
                  id:    TutorialIds.vetsFilter,
                  child: IconButton(
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
                ),
              ],
            ),

            // Busca, mapa, avisos e lista rolam juntos: em telas baixas (ou com
            // o teclado aberto) nada fica espremido ou cortado.
            Expanded(
              child: RefreshIndicator(
                color:     AppColors.brandGreen,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(child: TutorialTarget(
                      id:    TutorialIds.vetsSearch,
                      child: _searchField(context),
                    )),
                    SliverToBoxAdapter(child: TutorialTarget(
                      id:    TutorialIds.vetsMap,
                      child: _map(vets, location),
                    )),
                    // Aviso quando a posição real não está disponível.
                    if (usingFallback)
                      SliverToBoxAdapter(
                        child: _LocationFallbackNotice(
                          disabledByUser: location.valueOrNull?.source ==
                              LocationSource.disabledByUser,
                        ),
                      ),
                    SliverToBoxAdapter(child: TutorialTarget(
                      id:    TutorialIds.vetsList,
                      child: _listHeader(context),
                    )),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    ..._vetsList(vets, onlyAvailable),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm,
          AppSpacing.base, AppSpacing.xs,
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) {
            setState(() {}); // atualiza o botão de limpar
            ref.read(vetSearchProvider.notifier).state = v;
          },
          decoration: InputDecoration(
            hintText:  'Buscar por nome ou especialidade…',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
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
      );

  /// Mapa recolhível. A altura acompanha a tela (entre 140 e 220 px) para não
  /// tomar todo o espaço em aparelhos pequenos.
  Widget _map(
    AsyncValue<List<VetEntity>> vets,
    AsyncValue<UserLocation> location,
  ) {
    final height =
        (MediaQuery.sizeOf(context).height * 0.25).clamp(140.0, 220.0);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _mapExpanded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.xs,
                AppSpacing.base, AppSpacing.xs,
              ),
              child: SizedBox(
                height: height,
                child: location.when(
                  loading: () => AppSkeleton(height: height),
                  error:   (_, __) => const SizedBox.shrink(),
                  data:    (loc) => vets.maybeWhen(
                    data: (list) => VetsMap(
                      vets:    list,
                      userLat: loc.lat,
                      userLng: loc.lng,
                    ),
                    orElse: () => AppSkeleton(height: height),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  /// Cabeçalho da lista com toggle do mapa.
  Widget _listHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical:   AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mais próximos',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
              style: TextButton.styleFrom(
                foregroundColor: context.palette.brand,
                visualDensity:   VisualDensity.compact,
              ),
              child: Text(
                _mapExpanded ? 'Ocultar mapa' : 'Ver mapa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:      context.palette.brand,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );

  List<Widget> _vetsList(
    AsyncValue<List<VetEntity>> vets,
    bool onlyAvailable,
  ) {
    const padding = EdgeInsets.all(AppSpacing.base);
    return vets.when(
      loading: () => [
        SliverPadding(
          padding: padding,
          sliver: SliverList.separated(
            itemCount:  4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, __) => const AnimalListTileSkeleton(),
          ),
        ),
      ],
      error: (e, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon:        Icons.error_outline_rounded,
            title:       'Erro ao carregar',
            subtitle:    friendlyError(e),
            actionLabel: 'Tentar novamente',
            onAction:    _refresh,
          ),
        ),
      ],
      data: (list) {
        if (list.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon:        Icons.medical_services_outlined,
                title:       'Nenhum veterinário encontrado',
                subtitle:    onlyAvailable
                    ? 'Nenhum disponível agora. Tente remover o filtro.'
                    : _searchController.text.isNotEmpty
                        ? 'Tente uma busca diferente.'
                        : 'Quando um veterinário publicar o perfil no BoviCare, '
                            'ele aparece aqui.',
                actionLabel: onlyAvailable ? 'Mostrar todos' : null,
                onAction:    onlyAvailable
                    ? () => ref
                        .read(vetAvailableFilterProvider.notifier)
                        .state = false
                    : null,
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: padding,
            sliver: SliverList.separated(
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
          ),
        ];
      },
    );
  }
}

/// Aviso exibido quando o GPS está desligado/negado: o mapa e as distâncias
/// usam a cidade de referência (Rio Claro, SP) em vez da posição real.
class _LocationFallbackNotice extends StatelessWidget {
  const _LocationFallbackNotice({required this.disabledByUser});

  /// Consentimento de localização revogado em "Meus consentimentos".
  final bool disabledByUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, 0, AppSpacing.base, AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        context.palette.amberTint,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border:       Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_outlined, size: 16, color: context.palette.amber),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                disabledByUser
                    ? 'Localização desativada em Meus consentimentos — '
                        'mostrando a região de Rio Claro, SP.'
                    : 'Localização indisponível — mostrando a região de '
                        'Rio Claro, SP. Ative o GPS e puxe a lista para atualizar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.palette.amber,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
