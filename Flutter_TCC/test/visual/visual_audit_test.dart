// Auditoria visual automática: percorre as telas do app nos temas claro e
// escuro e em vários tamanhos de aparelho, e reprova:
//  • texto/ícone com contraste insuficiente sobre o fundo REAL (WCAG AA);
//  • qualquer estouro de layout (faixa amarela/preta) ou exceção de build.
//
// Rodar só esta auditoria:  flutter test test/visual

import 'package:bovicare/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:bovicare/features/auth/domain/entities/user_entity.dart';
import 'package:bovicare/features/auth/presentation/screens/login_screen.dart';
import 'package:bovicare/features/auth/presentation/screens/register_screen.dart';
import 'package:bovicare/features/brete/presentation/screens/brete_screen.dart';
import 'package:bovicare/features/health/domain/entities/health_event.dart';
import 'package:bovicare/features/health/presentation/widgets/health_event_sheet.dart';
import 'package:bovicare/features/health/presentation/widgets/pregnancy_sheet.dart';
import 'package:bovicare/features/herd/presentation/screens/animal_form_screen.dart';
import 'package:bovicare/features/herd/presentation/screens/animal_profile_screen.dart';
import 'package:bovicare/features/herd/presentation/screens/archived_animals_screen.dart';
import 'package:bovicare/features/herd/presentation/screens/herd_list_screen.dart';
import 'package:bovicare/features/herd/presentation/widgets/animal_exit_sheet.dart';
import 'package:bovicare/features/profile/presentation/screens/profile_screen.dart';
import 'package:bovicare/features/reports/presentation/screens/reports_screen.dart';
import 'package:bovicare/features/service_call/presentation/screens/home_dashboard_screen.dart';
import 'package:bovicare/features/service_call/presentation/screens/open_service_call_screen.dart';
import 'package:bovicare/features/service_call/presentation/screens/producer_calls_screen.dart';
import 'package:bovicare/features/service_call/presentation/screens/vet_agenda_screen.dart';
import 'package:bovicare/features/service_call/presentation/screens/vet_calls_screen.dart';
import 'package:bovicare/features/service_call/presentation/widgets/vet_call_action_sheet.dart';
import 'package:bovicare/features/settings/presentation/screens/alert_settings_screen.dart';
import 'package:bovicare/features/settings/presentation/screens/consents_screen.dart';
import 'package:bovicare/features/tutorial/presentation/screens/welcome_screen.dart';
import 'package:bovicare/features/vaccination/domain/entities/vaccine_info.dart';
import 'package:bovicare/features/vaccination/presentation/screens/vaccination_screen.dart';
import 'package:bovicare/features/vets/presentation/screens/vet_detail_screen.dart';
import 'package:bovicare/features/vets/presentation/screens/vet_professional_profile_screen.dart';
import 'package:bovicare/features/vets/presentation/screens/vets_list_screen.dart';
import 'package:bovicare/features/weighing/presentation/widgets/weighing_form_sheet.dart';
import 'package:bovicare/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/contrast_audit.dart';
import '../helpers/fake_app.dart';

class _Case {
  const _Case(this.name, this.path, this.build,
      {this.inShell = true, this.user = producer, this.tabs = const []});
  final String name;
  final String path;
  final Widget Function() build;
  final bool inShell;
  final UserEntity user;

  /// Abas/textos a tocar para auditar também o conteúdo de cada aba.
  final List<String> tabs;
}

final _cases = <_Case>[
  _Case('Início (produtor)', '/dashboard', () => const HomeDashboardScreen()),
  _Case('Rebanho', '/herd', () => const HerdListScreen()),
  _Case('Arquivados', '/herd/archived', () => const ArchivedAnimalsScreen()),
  _Case('Ficha do animal', '/herd/a1', () => const AnimalProfileScreen(animalId: 'a1'),
      tabs: ['Sanitário', 'Reprodução', 'Histórico']),
  _Case('Novo animal', '/herd/new', () => const AnimalFormScreen()),
  _Case('Editar animal', '/herd/a1/edit', () => AnimalFormScreen(initial: fakeAnimals.first)),
  _Case('Vacinação', '/herd/a1/vaccine', () => const VaccinationScreen(animalId: 'a1')),
  _Case('Brete', '/brete', () => const BreteScreen()),
  _Case('Veterinários', '/vets', () => const VetsListScreen()),
  _Case('Detalhe do vet', '/vets/vet-1', () => const VetDetailScreen(vetId: 'vet-1')),
  _Case('Relatórios', '/reports', () => const ReportsScreen()),
  _Case('Perfil', '/profile', () => const ProfileScreen()),
  _Case('Config. de alertas', '/profile/alerts', () => const AlertSettingsScreen()),
  _Case('Privacidade', '/profile/consents', () => const ConsentsScreen()),
  _Case('Alertas', '/alerts', () => const AlertsScreen()),
  _Case('Meus chamados', '/my-calls', () => const ProducerCallsScreen()),
  _Case('Abrir chamado', '/new-call', () => const OpenServiceCallScreen()),
  _Case('Início (vet)', '/dashboard', () => const HomeDashboardScreen(), user: vetUser),
  _Case('Chamados (vet)', '/calls', () => const VetCallsScreen(), user: vetUser),
  _Case('Agenda (vet)', '/agenda', () => const VetAgendaScreen(), user: vetUser),
  _Case('Perfil profissional', '/profile/professional',
      () => const VetProfessionalProfileScreen(), user: vetUser),
  _Case('Login', '/login', () => const LoginScreen(), inShell: false),
  _Case('Cadastro', '/register', () => const RegisterScreen(), inShell: false),
  // Completar perfil fica fora: lê o FirebaseAuth direto no initState.
  _Case('Boas-vindas', '/welcome', () => const WelcomeScreen(), inShell: false),
];

/// Folhas, diálogos e menus: abertos sobre uma tela anfitriã.
class _Overlay {
  const _Overlay(this.name, this.open,
      {this.host = _herdHost, this.user = producer});
  final String name;
  final _Case host;
  final UserEntity user;

  /// Abre a sobreposição a partir de um contexto da tela anfitriã.
  final Future<void> Function(WidgetTester tester, BuildContext context) open;
}

const _herdHost = _Case('Rebanho', '/herd', HerdListScreen.new);

void _fire(Future<Object?> future) => future.ignore();

final _overlays = <_Overlay>[
  _Overlay('Vermifugação', (t, c) async => _fire(showHealthEventSheet(c,
      animalId: 'a1', type: HealthEventType.deworming))),
  _Overlay('Observação', (t, c) async => _fire(showHealthEventSheet(c,
      animalId: 'a1', type: HealthEventType.observation))),
  _Overlay('Reprodução', (t, c) async =>
      _fire(showPregnancySheet(c, animal: fakeAnimals.first))),
  _Overlay('Pesagem', (t, c) async =>
      _fire(showWeighingSheet(c, animalId: 'a1', currentWeight: 412))),
  _Overlay('Saída do rebanho', (t, c) async =>
      _fire(showAnimalExitSheet(c, animals: fakeAnimals.take(2).toList()))),
  _Overlay('Confirmação', (t, c) async => _fire(AppBottomSheet.show(c,
      title: 'Excluir animal?',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir'))),
  _Overlay('Ação do chamado (vet)', (t, c) async =>
      _fire(showVetCallActionSheet(c, fakeCalls.first)),
      host: const _Case('Chamados (vet)', '/calls', VetCallsScreen.new, user: vetUser),
      user: vetUser),
  _Overlay('Esqueci minha senha', (t, c) async {
    await t.tap(find.text('Esqueci minha senha'));
  }, host: const _Case('Login', '/login', LoginScreen.new, inShell: false)),
  _Overlay('Menu de vacinas', (t, c) async {
    await t.tap(find.text(VaccineInfo.vaccines.first).first);
  }, host: _Case('Vacinação', '/herd/a1/vaccine',
      () => const VaccinationScreen(animalId: 'a1'))),
];

/// Aparelhos: celular pequeno com fonte ampliada, intermediário, grande e tablet.
const _devices = <(String, Size, double)>[
  ('pequeno 320×568 fonte 1,3×', Size(320, 568), 1.3),
  ('médio 360×800',              Size(360, 800), 1.0),
  ('grande 412×915',             Size(412, 915), 1.0),
  ('tablet 800×1280',            Size(800, 1280), 1.0),
];

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('pt_BR');
    await loadAppFonts();
  });
  setUp(() {
    // Tutorial já visto e dicas desligadas: nenhuma folha cobre a tela.
    SharedPreferences.setMockInitialValues({
      'tutorial_intro_seen': true,
      'tutorial_tips_enabled': false,
    });
  });

  group('contraste', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final modeName = mode == ThemeMode.dark ? 'escuro' : 'claro';
      for (final c in _cases) {
        testWidgets('${c.name} — tema $modeName', (tester) async {
          final errors = _captureErrors();
          await pumpScreen(tester, c.build(),
              path: c.path, mode: mode, inShell: c.inShell, user: c.user);

          final issues = <String>[...auditContrast(tester).map((i) => '$i')];
          for (final tab in c.tabs) {
            await tester.tap(find.text(tab).first);
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 400));
            }
            issues.addAll(auditContrast(tester).map((i) => '[$tab] $i'));
          }
          errors.restore();
          await settleAndDispose(tester);

          final report = [
            ...errors.messages,
            ...issues,
          ];
          if (report.isNotEmpty) {
            fail('${c.name} (tema $modeName):\n  ${report.toSet().join('\n  ')}');
          }
        });
      }
    }
  });

  group('folhas e diálogos', () {
    final variants = <(String, ThemeMode, Size, double)>[
      ('claro', ThemeMode.light, const Size(360, 800), 1),
      ('escuro', ThemeMode.dark, const Size(360, 800), 1),
      ('escuro, 320×568 fonte 1,3×', ThemeMode.dark, const Size(320, 568), 1.3),
    ];
    for (final (variant, mode, size, scale) in variants) {
      for (final o in _overlays) {
        testWidgets('${o.name} — $variant', (tester) async {
          final errors = _captureErrors();
          final host = o.host;
          await pumpScreen(tester, host.build(),
              path: host.path, mode: mode, size: size, textScale: scale,
              inShell: host.inShell, user: o.user);
          final context = tester.element(find.byType(Scaffold).last);
          int barriers() => find.byType(ModalBarrier).evaluate().length;
          final before = barriers();
          await o.open(tester, context);
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
          // Garante que a sobreposição abriu de fato (nova rota modal).
          expect(barriers(), greaterThan(before), reason: '${o.name} não abriu');
          final issues = auditContrast(tester).map((i) => '$i').toList();
          errors.restore();
          await settleAndDispose(tester);
          final report = [...errors.messages, ...issues];
          if (report.isNotEmpty) {
            fail('${o.name} ($variant):\n  ${report.toSet().join('\n  ')}');
          }
        });
      }
    }
  });

  group('layout responsivo (tema escuro)', () {
    for (final (device, size, scale) in _devices) {
      for (final c in _cases) {
        testWidgets('${c.name} — $device', (tester) async {
          final errors = _captureErrors();
          await pumpScreen(tester, c.build(),
              path: c.path, mode: ThemeMode.dark, size: size,
              textScale: scale, inShell: c.inShell, user: c.user);
          errors.restore();
          await settleAndDispose(tester);
          if (errors.messages.isNotEmpty) {
            fail('${c.name} ($device):\n${errors.messages.join('\n\n')}');
          }
        });
      }
    }
  });
}

class _Errors {
  _Errors(this._previous);
  final void Function(FlutterErrorDetails)? _previous;
  final messages = <String>[];
  void restore() => FlutterError.onError = _previous;
}

_Errors _captureErrors() {
  final e = _Errors(FlutterError.onError);
  FlutterError.onError = (d) {
    final text = d.toString();
    // Fonte não empacotada no teste (sem rede) não é defeito visual.
    if (text.contains('google_fonts') || text.contains('GoogleFonts')) return;
    e.messages.add(text.split('\n').take(25).join('\n'));
  };
  return e;
}
