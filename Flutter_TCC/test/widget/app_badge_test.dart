import 'package:bovicare/shared/widgets/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppBadge — render', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppBadge(label: 'Saudável'),
      ));
      expect(find.text('Saudável'), findsOneWidget);
    });

    testWidgets('renders without explicit type (defaults to neutral)', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppBadge(label: 'Neutro'),
      ));
      expect(find.byType(AppBadge), findsOneWidget);
    });
  });

  group('AppBadge — all types render', () {
    for (final type in BadgeType.values) {
      testWidgets('type $type renders without error', (tester) async {
        await tester.pumpWidget(_wrap(
          AppBadge(label: type.name, type: type),
        ));
        expect(find.byType(AppBadge), findsOneWidget);
        expect(find.text(type.name), findsOneWidget);
      });
    }
  });
}
