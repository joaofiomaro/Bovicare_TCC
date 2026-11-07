import 'package:bovicare/shared/widgets/app_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mesma configuração de idioma do main.dart. Sem os delegates o seletor
  // abria em branco (não havia textos Material em pt-BR).
  Widget app(Widget child) => MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('pt', 'BR')],
        home: Scaffold(body: child),
      );

  testWidgets('seletor de data abre em português e devolve a data', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(app(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          picked = await pickAppDate(context, initialDate: DateTime(2026, 3, 10));
        },
        child: const Text('abrir'),
      ),
    )));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 3, 15));
  });

  testWidgets('AppDateField abre o seletor ao tocar', (tester) async {
    await tester.pumpWidget(app(AppDateField(
      label:     'Data',
      date:      DateTime(2026, 3, 10),
      onChanged: (_) {},
    )));

    await tester.tap(find.text('10/03/2026'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
