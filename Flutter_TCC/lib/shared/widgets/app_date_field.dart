import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/extensions/datetime_ext.dart';

/// Abre o seletor de data no padrão do app (pt-BR, cor da marca).
Future<DateTime?> pickAppDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final last  = lastDate ?? DateTime.now();
  final first = firstDate ?? DateTime(2000);
  final initial = initialDate.isAfter(last)
      ? last
      : (initialDate.isBefore(first) ? first : initialDate);
  return showDatePicker(
    context:     context,
    initialDate: initial,
    firstDate:   first,
    lastDate:    last,
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
}

/// Campo de data com rótulo — toque abre o seletor.
class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color:      AppColors.mutedGreen,
              ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await pickAppDate(
              context,
              initialDate: date,
              firstDate:   firstDate,
              lastDate:    lastDate,
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: InputDecorator(
            decoration: InputDecoration(
              filled:    true,
              fillColor: cs.surfaceContainerHighest,
              border:    const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide:   BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical:   AppSpacing.md,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.mutedGreen),
                const SizedBox(width: 8),
                Text(date.toBrDate),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
