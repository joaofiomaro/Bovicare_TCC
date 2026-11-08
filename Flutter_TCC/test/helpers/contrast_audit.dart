import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Um texto (ou ícone) cujo contraste com o fundo real fica abaixo do mínimo.
class ContrastIssue {
  const ContrastIssue({
    required this.text,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.minimum,
    required this.where,
  });

  final String text;
  final Color  foreground;
  final Color  background;
  final double ratio;
  final double minimum;
  final String where;

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  String toString() =>
      '"$text"  ${_hex(foreground)} sobre ${_hex(background)}  '
      '= ${ratio.toStringAsFixed(2)}:1 (mínimo ${minimum.toStringAsFixed(1)})  '
      '← $where';
}

/// Luminância relativa (WCAG 2.x).
double luminance(Color c) {
  double ch(double v) => v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

/// Razão de contraste WCAG entre duas cores opacas (1 a 21).
double contrastRatio(Color a, Color b) {
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Color _over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

/// Fundo que o próprio render object pinta (atrás dos filhos), se houver.
Color? _ownBackground(RenderObject r) {
  if (r is RenderDecoratedBox && r.position == DecorationPosition.background) {
    final d = r.decoration;
    if (d is BoxDecoration) return d.color ?? _gradientColor(d.gradient);
    if (d is ShapeDecoration) return d.color ?? _gradientColor(d.gradient);
  }
  if (r is RenderPhysicalModel) return r.color;
  if (r is RenderPhysicalShape) return r.color;
  if (r is RenderCustomPaint) {
    // Fundo preenchido de campos de texto (InputDecorator).
    for (final p in [r.painter, r.foregroundPainter]) {
      if (p == null) continue;
      try {
        final fill = (p as dynamic).fillColor;
        if (fill is Color && fill.a > 0) return fill;
      // O painter do InputDecorator é privado: lê `fillColor` dinamicamente
      // e ignora outros tipos de pintura.
      // ignore: avoid_catching_errors
      } on NoSuchMethodError {
        continue;
      }
    }
  }
  final creator = r.debugCreator;
  if (creator is DebugCreator) {
    final w = creator.element.widget;
    if (w is ColoredBox) return w.color;
  }
  return null;
}

Color? _gradientColor(Gradient? g) {
  if (g == null || g.colors.isEmpty) return null;
  // Média das paradas: aproximação suficiente para detectar texto ilegível.
  var r = 0.0;
  var gr = 0.0;
  var b = 0.0;
  var a = 0.0;
  for (final c in g.colors) {
    r += c.r; gr += c.g; b += c.b; a += c.a;
  }
  final n = g.colors.length;
  return Color.from(alpha: a / n, red: r / n, green: gr / n, blue: b / n);
}

/// Fundo pintado logo no topo de uma subárvore irmã (ex.: o retângulo verde
/// de um cabeçalho em Stack, atrás do título).
Color? _subtreeBackground(RenderObject r, [int depth = 0]) {
  final own = _ownBackground(r);
  if (own != null && own.a > 0) return own;
  if (depth > 8) return null;
  final children = <RenderObject>[];
  r.visitChildren(children.add);
  if (children.length != 1) return null;
  return _subtreeBackground(children.single, depth + 1);
}

Rect _globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// Cor de fundo efetiva sob o ponto central de [paragraph], compondo as
/// camadas semitransparentes até chegar a uma opaca.
Color _effectiveBackground(RenderParagraph paragraph, Color fallback) {
  final center = _globalRect(paragraph).center;
  final layers = <Color>[];

  RenderObject child = paragraph;
  var parent = paragraph.parent;
  while (parent != null) {
    // Irmãos pintados atrás (Stack, slots do InputDecorator…).
    final siblings = <RenderObject>[];
    parent.visitChildren(siblings.add);
    for (final s in siblings.reversed) {
      if (identical(s, child) || s is! RenderBox || !s.hasSize) continue;
      if (!_globalRect(s).contains(center)) continue;
      final bg = _subtreeBackground(s);
      if (bg != null) layers.add(bg);
    }
    final own = _ownBackground(parent);
    if (own != null && own.a > 0) layers.add(own);
    if (layers.isNotEmpty && layers.last.a >= 0.999) break;

    child  = parent;
    parent = parent.parent;
  }

  var result = fallback;
  for (final c in layers.reversed) {
    result = _over(c, result);
  }
  return result;
}

/// Opacidade acumulada dos ancestrais (FadeTransition, Opacity…).
double _inheritedOpacity(RenderObject r) {
  var o = 1.0;
  var p = r.parent;
  while (p != null) {
    if (p is RenderOpacity) o *= p.opacity;
    if (p is RenderAnimatedOpacity) o *= p.opacity.value;
    if (p is RenderSliverOpacity) o *= p.opacity;
    p = p.parent;
  }
  return o;
}

String _describe(RenderParagraph p) {
  final creator = p.debugCreator;
  if (creator is! DebugCreator) return '';
  final names = <String>[];
  creator.element.visitAncestorElements((e) {
    final name = e.widget.runtimeType.toString();
    // Só widgets do app (privados ou com nome de tela/componente próprio).
    if (name.startsWith('_') ||
        name.startsWith('App') ||
        name.endsWith('Screen') ||
        name.endsWith('Card') ||
        name.endsWith('Tile') ||
        name.endsWith('Sheet')) {
      names.add(name);
    }
    return names.length < 3;
  });
  return names.join(' < ');
}

/// Verifica o contraste de todo texto e ícone visível na tela.
///
/// Regras (WCAG 2.1 AA): texto comum ≥ 4,5:1; texto grande (≥ 24 px, ou
/// ≥ 18,66 px em negrito) e ícones ≥ 3:1. Com [minimumOverride], aplica um
/// único mínimo para tudo.
List<ContrastIssue> auditContrast(
  WidgetTester tester, {
  double? minimumOverride,
}) {
  final issues = <ContrastIssue>[];
  final view   = tester.view;
  final screen = Offset.zero & (view.physicalSize / view.devicePixelRatio);
  final scaffoldBg =
      Theme.of(tester.element(find.byType(Navigator).first))
          .scaffoldBackgroundColor;

  for (final element in find.byType(RichText).evaluate()) {
    final p = element.renderObject;
    if (p is! RenderParagraph || !p.attached || !p.hasSize) continue;
    // Logotipos e controles desativados não têm exigência de contraste
    // (WCAG 1.4.3, exceções "logotypes" e "inactive user interface").
    if (_isLogo(p) || _isDisabledControl(p)) continue;
    if (p.size.isEmpty) continue;
    final rect = _globalRect(p);
    if (!screen.overlaps(rect)) continue;

    final opacity = _inheritedOpacity(p);
    if (opacity < 0.05) continue;

    final bg = _effectiveBackground(p, scaffoldBg);
    final textScale = p.textScaler.scale(14) / 14;

    p.text.visitChildren((span) {
      if (span is! TextSpan) return true;
      final text = span.text;
      if (text == null || text.trim().isEmpty) return true;
      final style = span.style;
      final color = style?.color ??
          p.text.style?.color ??
          DefaultTextStyle.of(element).style.color;
      if (color == null) return true;

      final isIcon = (style?.fontFamily ?? p.text.style?.fontFamily ?? '')
              .contains('Icons') ||
          (style?.fontFamily ?? '').startsWith('Material');
      final size   = (style?.fontSize ?? p.text.style?.fontSize ?? 14) * textScale;
      final weight = style?.fontWeight ?? p.text.style?.fontWeight ?? FontWeight.w400;
      final large  = size >= 24 || (size >= 18.66 && weight.value >= FontWeight.w600.value);

      final fg = color.withValues(alpha: color.a * opacity);
      final ratio = contrastRatio(_over(fg, bg), bg);
      final minimum = minimumOverride ?? (isIcon || large ? 3.0 : 4.5);
      if (ratio < minimum) {
        issues.add(ContrastIssue(
          text:       isIcon ? '[ícone]' : text.trim().replaceAll('\n', ' '),
          foreground: _over(fg, bg),
          background: bg,
          ratio:      ratio,
          minimum:    minimum,
          where:      _describe(p),
        ));
      }
      return true;
    });
  }
  return issues;
}

/// Marcas de terceiros (ex.: "G" do Google) mantêm as cores oficiais.
bool _isLogo(RenderParagraph p) {
  final creator = p.debugCreator;
  if (creator is! DebugCreator) return false;
  var logo = false;
  creator.element.visitAncestorElements((e) {
    logo = e.widget.runtimeType.toString() == '_GoogleIcon';
    return !logo;
  });
  return logo;
}

/// Texto/ícone dentro de um botão desativado (`onPressed: null`).
bool _isDisabledControl(RenderParagraph p) {
  final creator = p.debugCreator;
  if (creator is! DebugCreator) return false;
  var disabled = false;
  creator.element.visitAncestorElements((e) {
    final w = e.widget;
    if (w is ButtonStyleButton) {
      disabled = !w.enabled;
      return false;
    }
    if (w is IconButton) {
      disabled = w.onPressed == null;
      return false;
    }
    return true;
  });
  return disabled;
}
