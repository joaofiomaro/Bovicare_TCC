import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/datetime_ext.dart';
import '../../../../shared/widgets/app_chip_filter.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/report_data.dart';
import '../providers/report_provider.dart';
import '../widgets/report_preview.dart';
import '../widgets/report_type_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType? _activeType;
  String      _format = 'PDF';

  static const _formats = ['PDF', 'CSV'];

  Future<void> _generate(ReportType type) async {
    setState(() => _activeType = type);
    await ref.read(reportProvider.notifier).generate(type);
    if (!mounted) return;
    ref.read(reportProvider).whenData((data) {
      if (data != null) {
        AppToast.success(
          context,
          '${data.totalRecords} ${data.totalRecords == 1 ? 'registro' : 'registros'} gerados.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter      = ref.watch(reportFilterProvider);
    final reportState = ref.watch(reportProvider);
    final isLoading   = reportState.isLoading;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title:    'Relatórios',
            subtitle: 'Geração e exportação',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seleção de período
                  AppChipFilter<ReportPeriod>(
                    options: ReportPeriod.values
                        .map((p) => ChipOption(label: p.label, value: p))
                        .toList(),
                    selected: {filter.period},
                    onSelected: (period, {required isSelected}) {
                      ref.read(reportFilterProvider.notifier).state =
                          filter.copyWith(
                        period:      period,
                        clearCustom: period != ReportPeriod.custom,
                      );
                      ref.read(reportProvider.notifier).clear();
                      setState(() => _activeType = null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Date pickers para período livre
                  if (filter.period == ReportPeriod.custom) ...[
                    _DateRangePicker(
                      start:          filter.customStart,
                      end:            filter.customEnd,
                      onStartChanged: (d) {
                        ref.read(reportFilterProvider.notifier).state =
                            filter.copyWith(customStart: d);
                        ref.read(reportProvider.notifier).clear();
                        setState(() => _activeType = null);
                      },
                      onEndChanged: (d) {
                        ref.read(reportFilterProvider.notifier).state =
                            filter.copyWith(customEnd: d);
                        ref.read(reportProvider.notifier).clear();
                        setState(() => _activeType = null);
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),
                  ],

                  // Tipos de relatório
                  const _SectionLabel('Tipos'),
                  const SizedBox(height: AppSpacing.sm),
                  ...ReportType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ReportTypeCard(
                        type:       type,
                        isLoading:  isLoading && _activeType == type,
                        onGenerate: isLoading ? () {} : () => _generate(type),
                      ),
                    ),
                  ),

                  // Seleção de formato
                  const SizedBox(height: AppSpacing.sm),
                  const _SectionLabel('Formato'),
                  const SizedBox(height: AppSpacing.sm),
                  AppChipFilter<String>(
                    options: _formats
                        .map((f) => ChipOption(label: f, value: f))
                        .toList(),
                    selected: {_format},
                    onSelected: (fmt, {required isSelected}) =>
                        setState(() => _format = fmt),
                  ),

                  // Preview do relatório gerado
                  const SizedBox(height: AppSpacing.xl),
                  reportState.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(
                        'Erro ao gerar relatório: $e',
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                    data: (report) => report != null
                        ? ReportPreview(data: report)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime?           start;
  final DateTime?           end;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label:     'De',
            date:      start,
            lastDate:  end ?? DateTime.now(),
            onChanged: onStartChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DateField(
            label:      'Até',
            date:       end,
            firstDate:  start,
            lastDate:   DateTime.now(),
            onChanged:  onEndChanged,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.onChanged,
    this.date,
    this.firstDate,
    this.lastDate,
  });

  final String              label;
  final DateTime?           date;
  final DateTime?           firstDate;
  final DateTime?           lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context:     context,
          initialDate: date ?? DateTime.now(),
          firstDate:   firstDate ?? DateTime(2000),
          lastDate:    lastDate  ?? DateTime.now(),
          locale:      const Locale('pt', 'BR'),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    primary: AppColors.brandGreen,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical:   AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:        isDark
              ? AppColors.darkSurface
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border:       Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ghostGreen,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size:  14,
              color: AppColors.mutedGreen,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null ? date!.toBrDate : label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: date != null
                          ? Theme.of(context).colorScheme.onSurface
                          : AppColors.mutedGreen,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
