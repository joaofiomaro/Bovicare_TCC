import 'dart:async';
import 'dart:io';

import 'package:bovicare/core/theme/app_theme.dart';
import 'package:bovicare/features/auth/domain/entities/user_entity.dart';
import 'package:bovicare/features/auth/presentation/providers/auth_provider.dart';
import 'package:bovicare/features/brete/data/simulated_brete_gateway.dart';
import 'package:bovicare/features/brete/presentation/providers/brete_provider.dart';
import 'package:bovicare/features/dashboard/domain/entities/activity_item.dart';
import 'package:bovicare/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:bovicare/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bovicare/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:bovicare/features/health/domain/entities/health_event.dart';
import 'package:bovicare/features/health/domain/repositories/health_event_repository.dart';
import 'package:bovicare/features/health/presentation/providers/health_events_provider.dart';
import 'package:bovicare/features/herd/domain/entities/animal_entity.dart';
import 'package:bovicare/features/herd/domain/entities/sale_record.dart';
import 'package:bovicare/features/herd/domain/repositories/animal_repository.dart';
import 'package:bovicare/features/herd/domain/repositories/sale_repository.dart';
import 'package:bovicare/features/herd/presentation/providers/animals_provider.dart';
import 'package:bovicare/features/herd/presentation/providers/sales_provider.dart';
import 'package:bovicare/features/service_call/domain/entities/service_call.dart';
import 'package:bovicare/features/service_call/domain/repositories/service_call_repository.dart';
import 'package:bovicare/features/service_call/presentation/providers/service_calls_provider.dart';
import 'package:bovicare/features/settings/domain/entities/user_settings.dart';
import 'package:bovicare/features/settings/presentation/providers/settings_provider.dart';
import 'package:bovicare/features/vaccination/domain/entities/vaccination_record.dart';
import 'package:bovicare/features/vaccination/domain/repositories/vaccination_repository.dart';
import 'package:bovicare/features/vaccination/presentation/providers/vaccinations_provider.dart';
import 'package:bovicare/features/vets/domain/entities/vet_entity.dart';
import 'package:bovicare/features/vets/domain/repositories/vet_repository.dart';
import 'package:bovicare/features/vets/presentation/providers/vets_provider.dart';
import 'package:bovicare/features/weighing/domain/entities/weighing.dart';
import 'package:bovicare/features/weighing/domain/repositories/weighing_repository.dart';
import 'package:bovicare/features/weighing/presentation/providers/weighings_provider.dart';
import 'package:bovicare/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── Dados de exemplo (cobrem todos os estados visuais) ───────────────────────

final now = DateTime.now();

final fakeAnimals = <AnimalEntity>[
  AnimalEntity(
    id: 'a1', earTag: '047', name: 'Mimosa', breed: 'Nelore',
    sex: AnimalSex.female, birthDate: DateTime(2021, 3, 12),
    status: AnimalStatus.pregnant, weightKg: 412, rfid: '982000123456789',
    pregnancyDate: now.subtract(const Duration(days: 120)),
  ),
  AnimalEntity(
    id: 'a2', earTag: '048', name: 'Estrela da Manhã Dourada', breed: 'Girolando',
    sex: AnimalSex.female, birthDate: DateTime(2022, 7, 2),
    status: AnimalStatus.attention, weightKg: 356,
  ),
  AnimalEntity(
    id: 'a3', earTag: '112', breed: 'Angus', sex: AnimalSex.male,
    birthDate: DateTime(2020, 1, 20), status: AnimalStatus.sick, weightKg: 610,
  ),
  AnimalEntity(
    id: 'a4', earTag: '113', name: 'Trovão', breed: 'Brahman',
    sex: AnimalSex.male, birthDate: DateTime(2023, 9, 9),
    status: AnimalStatus.healthy,
  ),
  AnimalEntity(
    id: 'a5', earTag: '090', name: 'Pintada', breed: 'Gir',
    sex: AnimalSex.female, birthDate: DateTime(2019, 5, 5),
    status: AnimalStatus.healthy, exitType: AnimalExitType.sold,
    exitDate: now.subtract(const Duration(days: 10)),
  ),
  AnimalEntity(
    id: 'a6', earTag: '091', breed: 'Nelore', sex: AnimalSex.male,
    birthDate: DateTime(2019, 5, 5), status: AnimalStatus.sick,
    exitType: AnimalExitType.deceased, deathCause: 'Tristeza parasitária',
    exitDate: now.subtract(const Duration(days: 3)),
  ),
];

final fakeVaccinations = <VaccinationRecord>[
  VaccinationRecord(
    id: 'v1', animalId: 'a1', vaccineName: 'Febre Aftosa', dose: '1ª dose',
    date: now.subtract(const Duration(days: 5)), quarantineDays: 30,
    lot: '22B-2025', veterinarianName: 'Dra. Maria',
    nextDoseDate: now.add(const Duration(days: 3)),
  ),
  VaccinationRecord(
    id: 'v2', animalId: 'a2', vaccineName: 'Brucelose', dose: 'Dose única',
    date: now.subtract(const Duration(days: 200)), quarantineDays: 0,
    nextDoseDate: now.subtract(const Duration(days: 2)),
  ),
];

final fakeHealthEvents = <HealthEvent>[
  HealthEvent(
    id: 'h1', animalId: 'a1', type: HealthEventType.medication,
    date: now.subtract(const Duration(days: 2)), title: 'Ivermectina',
    dose: '10 ml', withdrawalDays: 35, notes: 'Aplicação subcutânea',
  ),
  HealthEvent(
    id: 'h2', animalId: 'a1', type: HealthEventType.pregnancyDiagnosis,
    date: now.subtract(const Duration(days: 120)), title: 'Prenhez confirmada',
  ),
  HealthEvent(
    id: 'h3', animalId: 'a1', type: HealthEventType.observation,
    date: now.subtract(const Duration(days: 1)), title: 'Mancando da pata traseira',
  ),
];

final fakeWeighings = <Weighing>[
  Weighing(id: 'w1', animalId: 'a1', weightKg: 380, date: now.subtract(const Duration(days: 90))),
  Weighing(id: 'w2', animalId: 'a1', weightKg: 395, date: now.subtract(const Duration(days: 45))),
  Weighing(id: 'w3', animalId: 'a1', weightKg: 412, date: now.subtract(const Duration(days: 2))),
];

const fakeVet = VetEntity(
  id: 'vet-1', name: 'Dra. Maria Aparecida Fernandes de Souza',
  crmv: 'CRMV-SP 123456',
  specialties: ['Reprodução', 'Clínica de grandes animais', 'Sanidade'],
  phone: '(19) 99999-0000', whatsapp: '(19) 99999-0000',
  email: 'maria@example.com', city: 'Rio Claro', state: 'SP',
  lat: -22.41, lng: -47.56, isAvailable: true, coverageRadiusKm: 80,
  distanceKm: 12,
);

final fakeCalls = <ServiceCall>[
  ServiceCall(
    id: 'c1', producerId: 'u1', producerName: 'João Produtor',
    city: 'Rio Claro', state: 'SP', title: 'Vaca com febre',
    description: 'Animal prostrado desde ontem, sem comer.',
    urgency: ServiceUrgency.high, status: ServiceStatus.open,
    createdAt: now.subtract(const Duration(hours: 3)), animalEarTag: '048',
  ),
  ServiceCall(
    id: 'c2', producerId: 'u1', producerName: 'João Produtor',
    city: 'Rio Claro', state: 'SP', title: 'Exame de prenhez',
    description: 'Lote de 10 matrizes.', urgency: ServiceUrgency.normal,
    status: ServiceStatus.accepted, vetId: 'vet-1', vetName: 'Dra. Maria',
    createdAt: now.subtract(const Duration(days: 1)),
    scheduledDate: now.add(const Duration(days: 2)),
  ),
  ServiceCall(
    id: 'c3', producerId: 'u1', producerName: 'João Produtor',
    city: 'Rio Claro', state: 'SP', title: 'Vacinação do rebanho',
    description: 'Aftosa.', urgency: ServiceUrgency.low,
    status: ServiceStatus.completed, vetId: 'vet-1', vetName: 'Dra. Maria',
    createdAt: now.subtract(const Duration(days: 9)),
    completedAt: now.subtract(const Duration(days: 7)),
    resolution: 'Todos vacinados.',
  ),
];

const producer = UserEntity(
  id: 'u1', name: 'João Fiomaro', email: 'joao@example.com',
  role: UserRole.producer, farmName: 'Fazenda Boa Vista',
);
const vetUser = UserEntity(
  id: 'vet-1', name: 'Dra. Maria', email: 'maria@example.com',
  role: UserRole.vet,
);

// ── Repositórios falsos ──────────────────────────────────────────────────────

class _Animals implements AnimalRepository {
  @override Future<List<AnimalEntity>> getAll() async => fakeAnimals;
  @override Future<AnimalEntity?> getById(String id) async =>
      fakeAnimals.where((a) => a.id == id).firstOrNull;
  @override Future<void> save(AnimalEntity animal) async {}
  @override Future<void> delete(String id) async {}
  @override Future<void> recordDeath({required List<String> animalIds,
      required DateTime date, String? cause, String? notes}) async {}
}

class _Vaccinations implements VaccinationRepository {
  @override Future<List<VaccinationRecord>> getAll() async => fakeVaccinations;
  @override Future<List<VaccinationRecord>> getByAnimal(String id) async =>
      fakeVaccinations.where((v) => v.animalId == id).toList();
  @override Future<void> save(VaccinationRecord record) async {}
  @override Future<void> delete(String id) async {}
}

class _Health implements HealthEventRepository {
  @override Future<List<HealthEvent>> getAll() async => fakeHealthEvents;
  @override Future<List<HealthEvent>> getByAnimal(String id) async =>
      fakeHealthEvents.where((e) => e.animalId == id).toList();
  @override Future<void> add(HealthEvent event) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Weighings implements WeighingRepository {
  @override Future<List<Weighing>> getByAnimal(String id) async =>
      fakeWeighings.where((w) => w.animalId == id).toList();
  @override Future<void> add(Weighing weighing) async {}
}

class _Sales implements SaleRepository {
  @override Future<List<SaleRecord>> getAll() async => const [];
  @override Future<void> recordSale(SaleRecord sale) async {}
}

class _Dashboard implements DashboardRepository {
  @override
  Future<DashboardStats> getStats() async => const DashboardStats(
        totalAnimals: 4, pregnantCount: 1, alertCount: 2,
        upcomingVaccinations: 1,
      );
  @override
  Future<List<ActivityItem>> getRecentActivities() async => [
        ActivityItem(type: ActivityType.vaccination, title: 'Febre Aftosa — #047', date: now),
        ActivityItem(type: ActivityType.weight, title: 'Pesagem — 412 kg', date: now),
        ActivityItem(type: ActivityType.birth, title: 'Prenhez constatada', date: now),
        ActivityItem(type: ActivityType.brete, title: 'Passagem no brete', date: now),
      ];
}

class _Vets implements VetRepository {
  @override Future<List<VetEntity>> getAll() async =>
      [fakeVet, fakeVet.copyWith(id: 'v2', name: 'Dr. Paulo', isAvailable: false)];
  @override Future<VetEntity?> getById(String id) async => fakeVet;
  @override Future<VetEntity?> getMyProfile(String uid) async => fakeVet;
  @override Future<void> saveMyProfile(VetEntity profile) async {}
  @override Future<void> deleteMyProfile(String uid) async {}
}

class _Calls implements ServiceCallRepository {
  @override Stream<List<ServiceCall>> watchOpen() =>
      Stream.value(fakeCalls.where((c) => c.isOpen).toList());
  @override Stream<List<ServiceCall>> watchForVet(String id) =>
      Stream.value(fakeCalls.where((c) => c.vetId == id).toList());
  @override Stream<List<ServiceCall>> watchForProducer(String id) =>
      Stream.value(fakeCalls);
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserEntity user;
  @override Future<UserEntity?> build() async => user;
}

class _AlertSettings extends AlertSettingsNotifier {
  @override Future<AlertSettings> build() async => const AlertSettings();
}

class _Consents extends ConsentSettingsNotifier {
  @override Future<ConsentSettings> build() async => const ConsentSettings();
}

List<Override> fakeOverrides({UserEntity user = producer}) => [
      authProvider.overrideWith(() => _Auth(user)),
      animalRepositoryProvider.overrideWithValue(_Animals()),
      vaccinationRepositoryProvider.overrideWithValue(_Vaccinations()),
      healthEventRepositoryProvider.overrideWithValue(_Health()),
      weighingRepositoryProvider.overrideWithValue(_Weighings()),
      saleRepositoryProvider.overrideWithValue(_Sales()),
      dashboardRepositoryProvider.overrideWithValue(_Dashboard()),
      vetRepositoryProvider.overrideWithValue(_Vets()),
      serviceCallRepositoryProvider.overrideWithValue(_Calls()),
      alertSettingsProvider.overrideWith(_AlertSettings.new),
      consentSettingsProvider.overrideWith(_Consents.new),
      // Sem GPS no teste: o mapa (tiles de rede) não é montado.
      userLocationProvider.overrideWith((_) => throw Exception('sem GPS')),
      breteGatewayProvider.overrideWith((ref) {
        final g = SimulatedBreteGateway();
        ref.onDispose(g.dispose);
        return g;
      }),
    ];

// ── Montagem ─────────────────────────────────────────────────────────────────

/// Monta [screen] como no app: dentro do shell (barra inferior) quando
/// [inShell], com o tema real (claro/escuro) e o tamanho de tela dado.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required String path,
  required ThemeMode mode,
  Size size = const Size(360, 800),
  double textScale = 1,
  bool inShell = true,
  UserEntity user = producer,
}) async {
  tester.view
    ..physicalSize     = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final route = GoRoute(path: path, builder: (_, __) => screen);
  final router = GoRouter(
    initialLocation: path,
    routes: inShell
        ? [ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [route])]
        : [route],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeOverrides(user: user),
      child: MaterialApp.router(
        theme:     AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  // Dados (futures) + animações de entrada (flutter_animate).
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Encerra timers de animações em loop (skeleton/shimmer) antes do fim.
Future<void> settleAndDispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  unawaited(Future<void>.value());
}

/// Carrega a Plus Jakarta Sans empacotada com os nomes de família que o
/// google_fonts gera (`PlusJakartaSans_regular`, `_500`…). Sem isso o teste
/// desenha cada letra como um quadrado largo e acusa estouros inexistentes.
Future<void> loadAppFonts() async {
  const files = {
    'regular': 'Regular',
    '500': 'Medium',
    '600': 'SemiBold',
    '700': 'Bold',
    '800': 'ExtraBold',
  };
  for (final MapEntry(key: variant, value: file) in files.entries) {
    final bytes = File('assets/google_fonts/PlusJakartaSans-$file.ttf')
        .readAsBytesSync();
    final loader = FontLoader('PlusJakartaSans_$variant')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
