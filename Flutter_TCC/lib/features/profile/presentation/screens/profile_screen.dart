import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/app_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Meu Perfil'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                ListTile(
                  title: const Text('Modo escuro'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                    activeThumbColor: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
