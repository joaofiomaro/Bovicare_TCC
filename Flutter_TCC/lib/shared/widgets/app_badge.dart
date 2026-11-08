import 'package:flutter/material.dart';
import '../../core/constants/app_radius.dart';
import '../../core/theme/app_palette.dart';

enum BadgeType { success, danger, warning, info, neutral }

/// Badge de status colorido — ex: "Saudável", "Doente", "Prenha".
class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, this.type = BadgeType.neutral, super.key});

  final String label;
  final BadgeType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context.palette);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullAll),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.2)),
    );
  }

  /// Fundo suave + texto forte do mesmo tom, adaptados ao tema.
  (Color, Color) _colors(AppPalette p) => switch (type) {
    BadgeType.success => (p.brandTintStrong, p.brand),
    BadgeType.danger  => (p.dangerTint,      p.danger),
    BadgeType.warning => (p.amberTint,       p.amber),
    BadgeType.info    => (p.infoTint,        p.info),
    BadgeType.neutral => (p.brandTint,       p.muted),
  };
}
