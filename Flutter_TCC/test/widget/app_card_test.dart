import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bovicare/shared/widgets/app_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppCard — render', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppCard(child: Text('Conteúdo do card')),
      ));
      expect(find.text('Conteúdo do card'), findsOneWidget);
    });

    testWidgets('elevated variant renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppCard(child: Text('OK')),
      ));
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('outlined variant renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppCard(
          variant: AppCardVariant.outlined,
          child: Text('OK'),
        ),
      ));
      expect(find.byType(AppCard), findsOneWidget);
    });
  });

  group('AppCard — tap', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        AppCard(
          onTap: () => tapped = true,
          child: const Text('Clicável'),
        ),
      ));
      await tester.tap(find.byType(AppCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        AppCard(
          onTap: () {},
          child: const Text('Clicável'),
        ),
      ));
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not render InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppCard(child: Text('Não clicável')),
      ));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('AppCard — single Container', () {
    testWidgets('has exactly one Container wrapper', (tester) async {
      await tester.pumpWidget(_wrap(
        AppCard(onTap: () {}, child: const Text('X')),
      ));
      // Apenas um Container com decoração — sem duplicação
      final containers = tester.widgetList<Container>(find.byType(Container));
      final decorated = containers.where((c) => c.decoration != null).length;
      expect(decorated, 1);
    });
  });
}
