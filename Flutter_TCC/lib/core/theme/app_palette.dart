import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Cores semânticas que **mudam com o tema** (claro/escuro).
///
/// Use `context.palette.x` sempre que a cor for texto, ícone, borda ou fundo
/// suave de um cartão. As constantes de [AppColors] continuam valendo para o
/// que é igual nos dois temas (cabeçalho verde, botões cheios com texto
/// branco).
///
/// Todos os pares texto × fundo abaixo têm contraste ≥ 4,5:1 (WCAG AA), e os
/// ícones decorativos ([subtle]) ≥ 3:1 — verificado em
/// `test/visual/visual_audit_test.dart`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.muted,
    required this.subtle,
    required this.border,
    required this.card,
    required this.field,
    required this.brandTint,
    required this.brandTintStrong,
    required this.danger,
    required this.dangerTint,
    required this.amber,
    required this.amberTint,
    required this.info,
    required this.infoTint,
    required this.onHeaderMuted,
  });

  /// Verde da marca como TEXTO/ÍCONE (links, abas, ícones de destaque).
  final Color brand;

  /// Texto secundário (legendas, rótulos, datas).
  final Color muted;

  /// Ícones decorativos e marcadores (não-texto, ≥ 3:1).
  final Color subtle;

  /// Bordas e divisórias.
  final Color border;

  /// Fundo de cartões e folhas.
  final Color card;

  /// Fundo de campos e áreas de entrada.
  final Color field;

  /// Fundo suave da marca (cartões de destaque).
  final Color brandTint;

  /// Fundo da marca um pouco mais forte (ícones em pílula, chips ativos).
  final Color brandTintStrong;

  final Color danger;
  final Color dangerTint;
  final Color amber;
  final Color amberTint;
  final Color info;
  final Color infoTint;

  /// Texto secundário sobre o cabeçalho verde (igual nos dois temas).
  final Color onHeaderMuted;

  static const light = AppPalette(
    brand:           AppColors.brandGreen,
    muted:           Color(0xFF55695B),
    subtle:          Color(0xFF7F9586),
    border:          AppColors.ghostGreen,
    card:            AppColors.white,
    field:           AppColors.surfaceLight,
    brandTint:       AppColors.brandPale,
    brandTintStrong: AppColors.brandLight,
    danger:          AppColors.danger,
    dangerTint:      AppColors.dangerLight,
    amber:           Color(0xFF7F5A00),
    amberTint:       AppColors.amberLight,
    info:            AppColors.info,
    infoTint:        AppColors.infoLight,
    onHeaderMuted:   AppColors.onBrandMuted,
  );

  static const dark = AppPalette(
    brand:           Color(0xFF7DD3A0),
    muted:           Color(0xFF9DBBA8),
    subtle:          Color(0xFF6E8F7B),
    border:          AppColors.darkBorder,
    card:            AppColors.darkSurface,
    field:           AppColors.darkSurface,
    brandTint:       Color(0xFF173322),
    brandTintStrong: Color(0xFF1F4430),
    danger:          Color(0xFFFF9A90),
    dangerTint:      Color(0xFF3A1A1A),
    amber:           Color(0xFFF2C14E),
    amberTint:       Color(0xFF33290F),
    info:            Color(0xFF9CC2FF),
    infoTint:        Color(0xFF16263D),
    onHeaderMuted:   AppColors.onBrandMuted,
  );

  @override
  AppPalette copyWith({
    Color? brand,
    Color? muted,
    Color? subtle,
    Color? border,
    Color? card,
    Color? field,
    Color? brandTint,
    Color? brandTintStrong,
    Color? danger,
    Color? dangerTint,
    Color? amber,
    Color? amberTint,
    Color? info,
    Color? infoTint,
    Color? onHeaderMuted,
  }) =>
      AppPalette(
        brand:           brand ?? this.brand,
        muted:           muted ?? this.muted,
        subtle:          subtle ?? this.subtle,
        border:          border ?? this.border,
        card:            card ?? this.card,
        field:           field ?? this.field,
        brandTint:       brandTint ?? this.brandTint,
        brandTintStrong: brandTintStrong ?? this.brandTintStrong,
        danger:          danger ?? this.danger,
        dangerTint:      dangerTint ?? this.dangerTint,
        amber:           amber ?? this.amber,
        amberTint:       amberTint ?? this.amberTint,
        info:            info ?? this.info,
        infoTint:        infoTint ?? this.infoTint,
        onHeaderMuted:   onHeaderMuted ?? this.onHeaderMuted,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brand:           l(brand, other.brand),
      muted:           l(muted, other.muted),
      subtle:          l(subtle, other.subtle),
      border:          l(border, other.border),
      card:            l(card, other.card),
      field:           l(field, other.field),
      brandTint:       l(brandTint, other.brandTint),
      brandTintStrong: l(brandTintStrong, other.brandTintStrong),
      danger:          l(danger, other.danger),
      dangerTint:      l(dangerTint, other.dangerTint),
      amber:           l(amber, other.amber),
      amberTint:       l(amberTint, other.amberTint),
      info:            l(info, other.info),
      infoTint:        l(infoTint, other.infoTint),
      onHeaderMuted:   l(onHeaderMuted, other.onHeaderMuted),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Paleta do tema atual (claro ou escuro).
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
