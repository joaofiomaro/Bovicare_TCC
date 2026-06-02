import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

/// Chips de filtro animados com suporte a seleção única ou múltipla.
class AppChipFilter<T> extends StatelessWidget {
  const AppChipFilter({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.multiSelect = false,
    super.key,
  });

  final List<ChipOption<T>> options;
  final Set<T> selected;
  final void Function(T value, {required bool isSelected}) onSelected;

  /// Se false, comporta-se como seleção única (deselecionar não é permitido).
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected.contains(opt.value);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AnimatedChip(
              option: opt,
              isSelected: isSelected,
              onTap: () {
                if (!multiSelect && isSelected) return;
                onSelected(opt.value, isSelected: !isSelected);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnimatedChip<T> extends StatelessWidget {
  const _AnimatedChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ChipOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandGreen
                : (isDark ? AppColors.darkSurface2 : AppColors.brandPale),
            borderRadius: AppRadius.fullAll,
            border: Border.all(
              color: isSelected
                  ? AppColors.brandGreen
                  : (isDark ? AppColors.darkBorder : AppColors.ghostGreen),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 14,
                  color: isSelected ? AppColors.white : AppColors.mutedGreen,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.white
                      : (isDark ? AppColors.darkTextMuted : AppColors.mutedGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChipOption<T> {
  const ChipOption({required this.label, required this.value, this.icon});

  final String label;
  final T value;
  final IconData? icon;
}
