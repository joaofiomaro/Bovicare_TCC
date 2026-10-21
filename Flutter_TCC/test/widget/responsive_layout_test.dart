import 'package:bovicare/features/health/presentation/providers/health_events_provider.dart';
import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/presentation/providers/animals_provider.dart';
import 'package:bovicare/features/herd/presentation/screens/animal_profile_screen.dart';
import 'package:bovicare/features/vaccination/presentation/providers/vaccinations_provider.dart';
import 'package:bovicare/features/vets/domain/entities/vet_entity.dart';
import 'package:bovicare/features/vets/domain/repositories/vet_repository.dart';
import 'package:bovicare/features/vets/presentation/providers/vets_provider.dart';
import 'package:bovicare/features/vets/presentation/screens/vet_detail_screen.dart';
import 'package:bovicare/features/vets/presentation/screens/vets_list_screen.dart';
import 'package:bovicare/features/weighing/presentation/providers/weighings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Garante que nenhuma tela crítica estoura (faixa amarela/preta de overflow)
/// num celular pequeno com a fonte do sistema ampliada.
///
/// Qualquer RenderFlex overflow é reportado como exceção pelo framework e faz
/// o teste falhar.

const _smallPhone = Size(320, 568);
const _largeFont  = 1.3;

const _vet = VetEntity(
  id:               '${kDemoVetIdPrefix}1',
  name:             'Dra. Maria Aparecida Fernandes de Souza',
  crmv:             'CRMV-SP 123456',
  specialties:      ['Reprodução', 'Clínica de grandes animais', 'Sanidade'],
  phone:            '(19) 99999-0000',
  whatsapp:         '(19) 99999-0000',
  email:            'maria@example.com',
  city:             'Rio Claro',
  state:            'SP',
  lat:              -22.41,
  lng:              -47.56,
  isAvailable:      true,
  coverageRadiusKm: 80,
  distanceKm:       12,
);

final _animal = AnimalEntity(
  id:        'a1',
  earTag:    '047',
  name:      'Mimosa',
  breed:     'Nelore',
  sex:       AnimalSex.female,
  birthDate: DateTime(2022, 3, 12),
  status:    AnimalStatus.healthy,
  weightKg:  384,
);

class _FakeVetsNotifier extends VetsNotifier {
  @override
  Future<List<VetEntity>> build() async => [_vet, _vet.copyWith(id: 'v2')];
}

Future<void> _pumpSmall(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize     = _smallPhone
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Coleta os erros de layout com o diagnóstico completo (qual widget
  // estourou), em vez da mensagem resumida de `takeException`.
  final errors   = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size:       _smallPhone,
            textScaler: TextScaler.linear(_largeFont),
          ),
          child: screen,
        ),
      ),
    ),
  );
  // Animações de entrada dos cards (flutter_animate).
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
  FlutterError.onError = previous;

  if (errors.isNotEmpty) {
    fail(errors.map((e) => e.toString()).join('\n\n'));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('lista de veterinários não estoura em tela pequena',
      (tester) async {
    await _pumpSmall(
      tester,
      const VetsListScreen(),
      overrides: [
        vetsProvider.overrideWith(_FakeVetsNotifier.new),
        // Erro → o mapa (tiles de rede) não é montado no teste.
        userLocationProvider.overrideWith((_) => throw Exception('sem GPS')),
      ],
    );

    expect(find.text('Mais próximos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detalhe do veterinário mostra o cabeçalho inteiro',
      (tester) async {
    await _pumpSmall(
      tester,
      VetDetailScreen(vetId: _vet.id),
      overrides: [
        vetDetailProvider.overrideWith((_, __) async => _vet),
      ],
    );

    expect(find.text(_vet.name), findsOneWidget);
    expect(find.text('Perfil de demonstração'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abas da ficha do animal exibem "Reprodução" completo',
      (tester) async {
    await _pumpSmall(
      tester,
      AnimalProfileScreen(animalId: _animal.id),
      overrides: [
        animalDetailProvider.overrideWith((_, __) async => _animal),
        vaccinationsProvider.overrideWith((_, __) async => []),
        animalHealthEventsProvider.overrideWith((_, __) async => []),
        animalWeighingsProvider.overrideWith((_, __) async => []),
      ],
    );

    final tab = find.text('Reprodução');
    expect(tab, findsOneWidget);
    // O texto cabe na largura da aba (não é cortado).
    final paragraph = tester.renderObject<RenderParagraph>(tab);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
