import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

/// Contêiner padrão dos bottom sheets de formulário (alça + teclado).
class AppSheetContainer extends StatelessWidget {
  const AppSheetContainer({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Teclado aberto empurra o conteúdo; fechado, respeita a barra de gestos.
    final bottom = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.paddingOf(context).bottom,
    );
    // Material (e não Container) para que ListTiles/InkWells da folha
    // mostrem o efeito de toque.
    return Material(
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.base,
          AppSpacing.base,
          AppSpacing.base + bottom,
        ),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:        cs.outlineVariant,
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...children,
          ],
        ),
        ),
      ),
    );
  }
}
