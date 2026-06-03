import 'package:bovicare/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppButton — render', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Salvar', onPressed: () {}),
      ));
      expect(find.text('Salvar'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Adicionar',
          onPressed: () {},
          icon: Icons.add,
        ),
      ));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('AppButton — loading state', () {
    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Entrar', onPressed: () {}, isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides label when loading', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Entrar', onPressed: () {}, isLoading: true),
      ));
      expect(find.text('Entrar'), findsNothing);
    });

    testWidgets('button is disabled when loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Entrar',
          onPressed: () => tapped = true,
          isLoading: true,
        ),
      ));
      await tester.tap(find.byType(AppButton));
      expect(tapped, isFalse);
    });
  });

  group('AppButton — variants', () {
    testWidgets('primary variant renders ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Ok', onPressed: () {}),
      ));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('outline variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Ok',
          onPressed: () {},
          variant: AppButtonVariant.outline,
        ),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('ghost variant renders TextButton', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Ok',
          onPressed: () {},
          variant: AppButtonVariant.ghost,
        ),
      ));
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('AppButton — tap', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Ok', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onPressed when null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppButton(label: 'Ok', onPressed: null),
      ));
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
    });
  });
}
