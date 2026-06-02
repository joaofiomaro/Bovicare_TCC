import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_typography.dart';

/// Configuração completa dos temas light e dark do BoviCare.
/// Utiliza Material 3 com ColorScheme customizado.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
  );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary:          AppColors.brandGreen,
    onPrimary:        AppColors.white,
    primaryContainer: AppColors.brandLight,
    onPrimaryContainer: AppColors.brandDeep,
    secondary:        AppColors.mutedGreen,
    onSecondary:      AppColors.white,
    secondaryContainer: AppColors.brandPale,
    onSecondaryContainer: AppColors.inkBlack,
    tertiary:         AppColors.info,
    onTertiary:       AppColors.white,
    error:            AppColors.danger,
    onError:          AppColors.white,
    errorContainer:   AppColors.dangerLight,
    onErrorContainer: AppColors.danger,
    surface:          AppColors.white,
    onSurface:        AppColors.inkBlack,
    surfaceContainerHighest: AppColors.surfaceLight,
    outline:          AppColors.ghostGreen,
    outlineVariant:   AppColors.brandLight,
    shadow:           Color(0x1A000000),
    scrim:            Color(0x80000000),
    inverseSurface:   AppColors.inkBlack,
    onInverseSurface: AppColors.white,
    inversePrimary:   AppColors.brandLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary:          AppColors.brandLight,
    onPrimary:        AppColors.brandDeep,
    primaryContainer: AppColors.brandDeep,
    onPrimaryContainer: AppColors.brandLight,
    secondary:        AppColors.darkTextMuted,
    onSecondary:      AppColors.darkBackground,
    secondaryContainer: AppColors.darkSurface2,
    onSecondaryContainer: AppColors.darkText,
    tertiary:         AppColors.infoLight,
    onTertiary:       AppColors.darkBackground,
    error:            Color(0xFFFFB4AB),
    onError:          Color(0xFF690005),
    errorContainer:   Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface:          AppColors.darkBackground,
    onSurface:        AppColors.darkText,
    surfaceContainerHighest: AppColors.darkSurface,
    outline:          AppColors.darkBorder,
    outlineVariant:   AppColors.darkSurface2,
    shadow:           Color(0x40000000),
    scrim:            Color(0xA0000000),
    inverseSurface:   AppColors.darkText,
    onInverseSurface: AppColors.darkBackground,
    inversePrimary:   AppColors.brandGreen,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    final isLight = brightness == Brightness.light;
    final textColor = isLight ? AppColors.inkBlack : AppColors.darkText;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(textColor),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          elevation: 0,
          textStyle: AppTypography.textTheme(textColor).labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: colorScheme.primary),
          textStyle: AppTypography.textTheme(textColor).labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surfaceLight : AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: colorScheme.error, width: 2)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: colorScheme.primary, size: 24);
          return IconThemeData(color: colorScheme.outline, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = AppTypography.textTheme(textColor).labelSmall!;
          if (states.contains(WidgetState.selected)) return style.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600);
          return style.copyWith(color: colorScheme.outline);
        }),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: AppTypography.textTheme(textColor).labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primaryContainer;
          return colorScheme.surfaceContainerHighest;
        }),
      ),
    );
  }
}
