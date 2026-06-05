import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/report_data.dart';

/// Exibe o resultado gerado em uma tabela horizontal rolável.
class ReportPreview extends StatelessWidget {
  const ReportPreview({required this.data, super.key});
  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumo do relatório
        Container(
          width:      double.infinity,
          padding:    const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:        AppColors.brandPale,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border:       Border.all(
              color: AppColors.brandGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.brandGreen,
                size:  20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${data.totalRecords} ${data.totalRecords == 1 ? 'registro' : 'registros'} '
                  '· ${_fmt(data.periodStart)} a ${_fmt(data.periodEnd)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:      AppColors.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (data.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'Nenhum dado no período selecionado.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedGreen,
                    ),
              ),
            ),
          )
        else
          // Tabela com scroll horizontal para acomodar muitas colunas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight:  36,
              dataRowMinHeight:  36,
              dataRowMaxHeight:  48,
              columnSpacing:     16,
              headingRowColor:   WidgetStatePropertyAll(
                isDark ? AppColors.darkSurface2 : AppColors.brandPale,
              ),
              decoration: BoxDecoration(
                border:       Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              columns: data.headers
                  .map(
                    (h) => DataColumn(
                      label: Text(
                        h,
                        style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.mutedGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: [
                ...data.rows.asMap().entries.map((entry) {
                  final isEven = entry.key.isEven;
                  return DataRow(
                    color: WidgetStatePropertyAll(
                      isEven
                          ? Colors.transparent
                          : (isDark
                              ? AppColors.darkSurface.withValues(alpha: 0.5)
                              : AppColors.brandPale.withValues(alpha: 0.4)),
                    ),
                    cells: entry.value
                        .map(
                          (cell) => DataCell(
                            Text(
                              cell,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }),
                // Linha de totais (ex.: relatório de vendas).
                if (data.footer case final footer?)
                  DataRow(
                    color: WidgetStatePropertyAll(
                      isDark
                          ? AppColors.darkSurface2
                          : AppColors.brandPale,
                    ),
                    cells: footer
                        .map(
                          (cell) => DataCell(
                            Text(
                              cell,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
