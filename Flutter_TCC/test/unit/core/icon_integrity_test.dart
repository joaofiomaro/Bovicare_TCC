// Garante que nenhum ícone apareça em branco no APK de release.
//
// Um ícone some (quadrado vazio/branco) quando a fonte dele não vai dentro do
// app ou quando o "tree-shaking" do build remove o glifo. Este teste trava as
// três causas conhecidas.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Famílias de ícones cuja fonte é empacotada no app.
const _bundledIconSets = {'Icons', 'CupertinoIcons'};

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('a fonte dos ícones iOS (cupertino_icons) está declarada', () {
    // O próprio Flutter referencia CupertinoIcons (campo de texto no iPhone);
    // sem o pacote, o build avisa "Expected to find fonts for CupertinoIcons"
    // e esses ícones ficam em branco.
    expect(
      RegExp(r'^\s+cupertino_icons:', multiLine: true).hasMatch(pubspec),
      isTrue,
    );
    expect(pubspec, contains('uses-material-design: true'));
  });

  test('todo ícone usado vem de uma fonte empacotada', () {
    // Ex.: `Symbols.home` ou `FontAwesomeIcons.x` sem o pacote/fonte.
    final iconRef = RegExp(r'\b([A-Z]\w*Icons|Symbols)\.([a-z]\w*)');
    final unknown = <String>[];
    for (final f in _dartFiles('lib')) {
      final src = f.readAsStringSync();
      for (final m in iconRef.allMatches(src)) {
        if (!_bundledIconSets.contains(m.group(1))) {
          unknown.add('${f.path}: ${m.group(0)}');
        }
      }
    }
    expect(unknown, isEmpty, reason: 'Fonte de ícones não empacotada');
  });

  test('nenhum IconData criado em tempo de execução', () {
    // `IconData(codigo)` não constante é apagado pelo tree-shaking do release
    // e vira um quadrado em branco. Use sempre as constantes `Icons.x`.
    final dynamicIcon = RegExp(r'(?<!const\s)\bIconData\s*\(');
    final found = <String>[];
    for (final f in _dartFiles('lib')) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (dynamicIcon.hasMatch(lines[i])) found.add('${f.path}:${i + 1}');
      }
    }
    expect(found, isEmpty);
  });
}
