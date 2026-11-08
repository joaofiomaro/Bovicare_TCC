import 'package:flutter/material.dart';

/// Grade que se adapta à tela, para cartões de altura variável (KPIs).
///
/// - Colunas pela largura disponível: 2 em celulares, até [maxColumns] em
///   tablets/paisagem (cada item com pelo menos [minItemWidth]).
/// - Altura de cada linha = a do cartão mais alto dela: nada é cortado com a
///   fonte do sistema ampliada (ao contrário de `GridView` com
///   `childAspectRatio` fixo), e os cartões de uma linha ficam alinhados.
class AppAdaptiveGrid extends StatelessWidget {
  const AppAdaptiveGrid({
    required this.children,
    this.minItemWidth = 140,
    this.maxColumns = 4,
    this.spacing = 12,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  /// Quantas colunas cabem em [width] (função pura, testável).
  static int columnsFor(
    double width, {
    double minItemWidth = 140,
    int maxColumns = 4,
    double spacing = 12,
  }) =>
      ((width + spacing) ~/ (minItemWidth + spacing)).clamp(1, maxColumns);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = columnsFor(
          constraints.maxWidth,
          minItemWidth: minItemWidth,
          maxColumns:   maxColumns,
          spacing:      spacing,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var start = 0; start < children.length; start += cols) ...[
              if (start > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) SizedBox(width: spacing),
                      Expanded(
                        child: start + c < children.length
                            ? children[start + c]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
