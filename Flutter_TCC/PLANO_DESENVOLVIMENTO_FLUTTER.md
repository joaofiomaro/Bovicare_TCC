# BoviCare — Plano de Desenvolvimento Flutter
> Projeto: `Flutter_TCC/` | Status: 🟡 Em Desenvolvimento — Fases 0–6, 8–10 concluídas · Fase 7 adiada (hardware) · Fase 11 pendente · `flutter analyze` 0 issues
> Última atualização: 2026-06-02

---

## Índice

1. [Visão Geral](#1-visão-geral)
2. [Stack Tecnológica](#2-stack-tecnológica)
3. [Arquitetura](#3-arquitetura)
4. [Estrutura de Pastas](#4-estrutura-de-pastas)
5. [Design System & Tokens](#5-design-system--tokens)
6. [Telas & Funcionalidades](#6-telas--funcionalidades)
7. [Fases de Desenvolvimento](#7-fases-de-desenvolvimento)
8. [Checklist de Progresso](#8-checklist-de-progresso)
9. [Regras de Qualidade](#9-regras-de-qualidade)

---

## 1. Visão Geral

**BoviCare** é um aplicativo mobile de gestão de rebanho bovino desenvolvido como TCC. O app conecta produtores rurais e veterinários, oferecendo gestão de animais, controle sanitário, integração IoT com brete eletrônico (ESP32) e rede de veterinários.

**Referência de UI/UX:** protótipo web em `js/`, `css/`, `index.html` (será removido após conclusão da migração Flutter).

---

## 2. Stack Tecnológica

### Core
| Lib | Versão | Uso |
|---|---|---|
| `flutter` | SDK ≥3.22 | Framework base |
| `dart` | SDK ≥3.4 | Linguagem |

### State Management & DI
| Lib | Versão | Uso |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management + DI (compile-safe, testável) |
| `riverpod_annotation` | ^2.6.1 | Code gen para providers |

### Navegação
| Lib | Versão | Uso |
|---|---|---|
| `go_router` | ^14.8.1 | Navegação declarativa, deep linking, shell routes |

### Persistência Local
| Lib | Versão | Uso |
|---|---|---|
| `hive_flutter` | ^1.1.0 | NoSQL local DB (animais, cache) |
| `shared_preferences` | ^2.3.5 | Preferências simples (tema, login state) |

### Rede & IoT
| Lib | Versão | Uso |
|---|---|---|
| `dio` | ^5.8.0 | HTTP client com interceptors |
| `mqtt_client` | ^10.7.0 | Comunicação MQTT com ESP32 do brete |
| `connectivity_plus` | ^6.1.4 | Monitoramento de rede |

### UI & Animações
| Lib | Versão | Uso |
|---|---|---|
| `flutter_animate` | ^4.5.2 | Animações declarativas fluidas |
| `shimmer` | ^3.0.0 | Skeleton loading (shimmer effect) |
| `material_symbols_icons` | ^4.2787.1 | Ícones Material 3 (substituiu phosphor_flutter — incompatível com Flutter 3.44+) |
| `google_fonts` | ^6.2.1 | Plus Jakarta Sans |
| `cached_network_image` | ^3.4.1 | Imagens com cache |
| `flutter_svg` | ^2.0.17 | Assets SVG |
| `lottie` | ^3.3.1 | Animações Lottie (splash, loading states) |

### Mapas
| Lib | Versão | Uso |
|---|---|---|
| `flutter_map` | ^7.0.2 | Mapas open-source (sem chave de API) |
| `latlong2` | ^0.9.1 | Coordenadas para flutter_map |
| `geolocator` | ^13.0.4 | Localização GPS do usuário |

### Formulários & Validação
| Lib | Versão | Uso |
|---|---|---|
| `formz` | ^0.7.0 | Validação de campos tipada e reutilizável |

### Utilitários
| Lib | Versão | Uso |
|---|---|---|
| `intl` | ^0.20.2 | Formatação data/hora, moeda (pt-BR) |
| `logger` | ^2.5.0 | Logging estruturado por nível |
| `flutter_dotenv` | ^5.2.1 | Variáveis de ambiente (.env) |
| `url_launcher` | ^6.3.1 | Ligar, WhatsApp, email para vets |
| `permission_handler` | ^11.3.1 | Permissões runtime (câmera RFID, GPS) |
| `image_picker` | ^1.1.2 | Foto de perfil e animais |

### Code Generation
| Lib | Versão | Uso |
|---|---|---|
| `freezed` | ^2.5.8 | Models imutáveis com copyWith, unions |
| `freezed_annotation` | ^2.4.4 | Anotações Freezed |
| `json_serializable` | ^6.9.5 | Serialização JSON automática |
| `build_runner` | ^2.4.15 | Runner de code generation |
| ~~`hive_generator`~~ | removido | Conflito de versão com `freezed` (source_gen incompatível) — adaptadores Hive escritos manualmente |
| `riverpod_generator` | ^2.6.3 | Code gen para Riverpod |

### Qualidade
| Lib | Versão | Uso |
|---|---|---|
| `very_good_analysis` | ^7.0.0 | Linting rigoroso (rules opinionadas) |
| `mocktail` | ^1.0.5 | Mocks para testes |
| `flutter_test` | SDK | Unit + widget tests |

---

## 3. Arquitetura

### Padrão: Feature-First Clean Architecture

```
Presentation Layer  ← UI, Providers Riverpod, Widgets
       ↕
Domain Layer        ← Entities, Use Cases, Repositories (interfaces)
       ↕
Data Layer          ← Models, Data Sources (API/Local), Repository Impl
```

**Princípios:**
- Cada feature é um módulo autossuficiente (`data/`, `domain/`, `presentation/`)
- Dependências apontam sempre para dentro (Presentation → Domain ← Data)
- Providers Riverpod usam `@riverpod` annotation (code gen)
- Models com `@freezed` (imutabilidade garantida em compile time)
- Erros tratados com `Either<Failure, T>` pattern (sem exceptions soltas)
- Nenhuma lógica de negócio em widgets

### Camadas por Feature
```
features/auth/
├── data/
│   ├── datasources/      # AuthLocalDataSource, AuthRemoteDataSource
│   ├── models/           # UserModel (freezed + json_serializable)
│   └── repositories/     # AuthRepositoryImpl
├── domain/
│   ├── entities/         # UserEntity (freezed, sem JSON)
│   ├── repositories/     # AuthRepository (interface/abstract)
│   └── usecases/         # LoginUseCase, RegisterUseCase, LogoutUseCase
└── presentation/
    ├── providers/         # authProvider, loginStateProvider (riverpod_generator)
    ├── screens/           # LoginScreen, RegisterScreen
    └── widgets/           # LoginForm, RegisterForm
```

---

## 4. Estrutura de Pastas

```
Flutter_TCC/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Paleta de cores do design system
│   │   │   ├── app_typography.dart     # TextStyles + Google Fonts
│   │   │   ├── app_spacing.dart        # Constantes de espaçamento (4, 8, 12, 16...)
│   │   │   ├── app_radius.dart         # Border radius padrão
│   │   │   ├── app_shadows.dart        # BoxShadow padrão
│   │   │   └── app_durations.dart      # Durações de animação (fast, normal, slow)
│   │   ├── errors/
│   │   │   ├── failures.dart           # Sealed class Failure (ServerFailure, CacheFailure...)
│   │   │   └── exceptions.dart         # Exceptions customizadas
│   │   ├── extensions/
│   │   │   ├── build_context_ext.dart  # context.colors, context.textTheme, context.go()
│   │   │   ├── string_ext.dart         # capitalize, isValidEmail, etc.
│   │   │   └── datetime_ext.dart       # toRelative(), toBrFormat(), etc.
│   │   ├── network/
│   │   │   ├── dio_client.dart         # Dio instance + interceptors
│   │   │   └── api_endpoints.dart      # URLs base e endpoints
│   │   ├── router/
│   │   │   ├── app_router.dart         # GoRouter config + ShellRoute
│   │   │   └── app_routes.dart         # Constantes de rota (nomes e paths)
│   │   ├── theme/
│   │   │   ├── app_theme.dart          # ThemeData light + dark
│   │   │   ├── color_scheme.dart       # ColorScheme Material 3
│   │   │   └── theme_provider.dart     # Riverpod provider do tema
│   │   └── utils/
│   │       ├── logger.dart             # Logger global configurado
│   │       └── validators.dart         # Formz input validators reutilizáveis
│   ├── features/
│   │   ├── auth/                       # Login, Cadastro
│   │   ├── dashboard/                  # Dashboard com KPIs
│   │   ├── herd/                       # Listagem do rebanho
│   │   ├── animal/                     # Ficha animal + Novo Animal
│   │   ├── vaccination/                # Registro de vacinação
│   │   ├── brete/                      # Controle IoT ESP32
│   │   ├── vets/                       # Veterinários + Detalhe
│   │   ├── reports/                    # Relatórios
│   │   └── profile/                    # Perfil + configurações
│   ├── shared/
│   │   ├── data/
│   │   │   └── local/
│   │   │       └── hive_service.dart   # Inicialização e helpers do Hive
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── app_user.dart       # UserEntity compartilhada
│   │   └── widgets/                    # Design System — componentes globais
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── app_card.dart
│   │       ├── app_bottom_sheet.dart
│   │       ├── app_toast.dart
│   │       ├── app_skeleton.dart
│   │       ├── app_badge.dart
│   │       ├── app_avatar.dart
│   │       ├── app_header.dart
│   │       ├── app_bottom_nav.dart
│   │       ├── app_chip_filter.dart
│   │       ├── app_progress_bar.dart
│   │       └── app_empty_state.dart
│   └── main.dart
├── assets/
│   ├── images/
│   │   ├── bovicare_logo.png
│   │   └── cow_icon.png
│   ├── icons/
│   │   └── (SVG icons se necessário)
│   ├── animations/
│   │   └── (arquivos Lottie .json)
│   └── fonts/
│       └── (fallback — Google Fonts via pacote)
├── test/
│   ├── unit/
│   │   ├── features/
│   │   └── core/
│   ├── widget/
│   └── integration/
├── .env                                # Variáveis de ambiente (não commitar)
├── .env.example                        # Template do .env
├── analysis_options.yaml               # Regras de linting (very_good_analysis)
├── pubspec.yaml
└── README.md
```

---

## 5. Design System & Tokens

### Paleta de Cores (fiel ao protótipo web)
```dart
// Marca — Verde BoviCare
brandGreen      = Color(0xFF1C6B3A)   // Primary
brandLight      = Color(0xFFE8F5EE)   // Surface tint
brandPale       = Color(0xFFF2FAF5)   // Background alt
brandDeep       = Color(0xFF134D29)   // Pressed / variant

// Neutros
inkBlack        = Color(0xFF0F1F16)   // Texto principal
mutedGreen      = Color(0xFF6B8070)   // Texto secundário
ghostGreen      = Color(0xFFB8CCBF)   // Borders, placeholders
surfaceLight    = Color(0xFFF8FBF9)   // Background claro
surfaceWhite    = Color(0xFFFFFFFF)

// Semânticas
dangerRed       = Color(0xFF8B1A1A)
dangerLight     = Color(0xFFFFF0F0)
amberWarning    = Color(0xFFA07000)
amberLight      = Color(0xFFFFF8E6)
infoBlue        = Color(0xFF1A56A0)
infoLight       = Color(0xFFEEF4FF)

// Dark Mode (variantes ajustadas para contraste WCAG AA)
// Definidas no app_theme.dart via ColorScheme.dark()
```

### Tipografia
- Família: **Plus Jakarta Sans** (via `google_fonts`)
- Escala Material 3: displayLarge → bodySmall
- Pesos usados: 300, 400, 500, 600, 700

### Espaçamento (múltiplos de 4)
```
xs  = 4px   sm  = 8px   md  = 12px   base = 16px
lg  = 20px  xl  = 24px  2xl = 32px   3xl  = 48px
```

### Border Radius
```
sm = 8px    md = 12px    lg = 16px    xl = 24px    full = 999px
```

### Durações de Animação
```
fast   = 200ms    normal = 350ms    slow = 500ms    verySlow = 800ms
```

---

## 6. Telas & Funcionalidades

| # | Tela | Rota | Feature | Status |
|---|---|---|---|---|
| 01 | Splash Screen | `/splash` | auth | ✅ Completo — auth real, redireciona por sessão |
| 02 | Login | `/login` | auth | ✅ Completo — authProvider, validação Formz, AppToast |
| 03 | Cadastro | `/register` | auth | ✅ Completo — authProvider, UserRole tipado, persistência |
| 04 | Dashboard | `/dashboard` | dashboard | ✅ Completo — KPIs animados, timeline, skeleton, pull-to-refresh |
| 05 | Rebanho | `/herd` | herd | ✅ Completo — CRUD Hive, filtros, busca live, skeleton, FAB |
| 06 | Ficha Animal | `/herd/:id` | animal | ✅ Completo — 4 tabs, prenhez, grade de ações, histórico |
| 07 | Novo Animal | `/herd/new` | animal | ✅ Completo — formulário, RFID simulado, date picker |
| 08 | Registrar Vacinação | `/herd/:id/vaccine` | vaccination | ✅ Completo — formulário, QuarantineCalculator, salva no Hive |
| 09 | Painel Brete | `/brete` | brete | ⏸️ Adiado — aguarda hardware ESP32 (placeholder funcional) |
| 10 | Veterinários | `/vets` | vets | ✅ Completo — mapa OSM, filtros, busca, lista com distância |
| 11 | Detalhe Veterinário | `/vets/:id` | vets | ✅ Completo — perfil, especialidades, ContactButtons funcionais |
| 12 | Relatórios | `/reports` | reports | ✅ Completo — 4 tipos, 4 períodos, DataTable, toast com contagem |
| 13 | Perfil | `/profile` | profile | ✅ Completo — hero, editar dados, LGPD, sync, logout com confirmação |

---

## 7. Fases de Desenvolvimento

---

### FASE 0 — Setup & Configuração do Projeto ✅
> Objetivo: projeto Flutter rodando com arquitetura, tooling e dependências configurados.

**Tarefas:**
- [x] `flutter create --org br.com.bovicare --project-name bovicare flutter_TCC`
- [x] Atualizar `pubspec.yaml` com todas as dependências da stack
- [x] Configurar `analysis_options.yaml` com `very_good_analysis`
- [x] Criar `.env` e `.env.example` (MQTT_BROKER_URL, API_BASE_URL, MAPS_TILE_URL)
- [x] Configurar `assets/` no `pubspec.yaml` (images, fonts, animations)
- [x] Estruturar todas as pastas de `lib/` — 98 diretórios criados
- [x] Configurar `main.dart` com `ProviderScope`, `flutter_dotenv`, `Hive.initFlutter()`
- [x] Criar `app_router.dart` com GoRouter e rotas placeholder
- [x] Adicionar suporte web (`flutter create . --platforms web`)
- [x] `flutter analyze` retorna **0 issues**
- [x] `flutter run` — emulador Pixel 8 API 35 configurado; GPU acelerada via `hw.gpu.mode = host`

> ✅ Concluído em: 2026-06-02.
> Flutter 3.44.1 + Android Studio instalados. `phosphor_flutter` → `material_symbols_icons` (incompatível com Flutter 3.44). `hive_generator` removido (conflito source_gen/freezed). AVD otimizado: GPU host, CPU 2 cores, RAM 1536 MB para evitar BSOD por sobrecarga.

**Critério de conclusão:** `flutter run` abre o app sem crash, rota `/` funciona.

---

### FASE 1 — Core Layer (Design System + Tema + Router) ✅
> Objetivo: fundação visual e navegação completas.

**Tarefas:**
- [x] `app_colors.dart` — paleta completa (brand, neutros, semânticas, dark mode)
- [x] `app_typography.dart` — TextStyles Material 3 com Plus Jakarta Sans (Google Fonts)
- [x] `app_spacing.dart`, `app_radius.dart`, `app_shadows.dart`, `app_durations.dart`
- [x] `app_theme.dart` — ThemeData light + dark completos (Material 3, ColorScheme completo)
- [x] `theme_provider.dart` — StateNotifier Riverpod + SharedPreferences com persistência
- [x] `app_routes.dart` — constantes de nomes e paths de todas as rotas
- [x] `app_router.dart` — GoRouter com ShellRoute (bottom nav), transições slide/fade customizadas
- [x] `build_context_ext.dart` — helpers: `colors`, `textTheme`, `isDark`, `screenSize`, `showSnack`
- [x] `string_ext.dart` — `capitalize`, `titleCase`, `isValidEmail`, `isValidPassword`, `initials`
- [x] `datetime_ext.dart` — `toBrDate`, `toBrDateTime`, `toRelative`, `ageInYears`, `ageInMonths`
- [x] `failures.dart` — sealed class: `ServerFailure`, `CacheFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `UnknownFailure`
- [x] `logger.dart` — Logger global (`appLogger`)
- [x] `validators.dart` — `EmailInput`, `PasswordInput`, `RequiredInput` (Formz)
- [ ] `exceptions.dart` — exceptions customizadas (pendente)
- [ ] `dio_client.dart` — Dio instance + interceptors (pendente — criado quando backend definido)
- [ ] `api_endpoints.dart` — endpoints da API (pendente — criado quando backend definido)

> ✅ Concluído em: 2026-06-02. Auth guard no router pendente (será implementado na Fase 3 após AuthProvider).

**Critério de conclusão:** Tema light/dark funcionando, navegação entre rotas placeholder sem erros.

---

### FASE 2 — Shared Widgets (Design System Componentes) ✅
> Objetivo: biblioteca de componentes prontos para uso em todas as features.

**Tarefas:**
- [x] `AppButton` — variantes: primary, outline, danger, ghost | estados: loading, disabled
- [x] `AppTextField` — label flutuante, toggle senha, ícones prefixo/sufixo, errorText
- [x] `AppCard` — variantes: elevated, outlined | suporte ripple
- [x] `AppBottomSheet` — modal configurável (ícone, título, mensagem, callbacks confirm/cancel)
- [x] `AppToast` — success, error, info | SnackBar flutuante | ScaffoldMessenger wrapper
- [x] `AppSkeleton` — shimmer genérico + `AnimalListTileSkeleton` + `KpiCardSkeleton`
- [x] `AppBadge` — 5 tipos: success, danger, warning, info, neutral
- [x] `AppAvatar` — CachedNetworkImage + fallback de iniciais
- [x] `AppHeader` — barra verde com arco decorativo, título, subtitle, ações, back button
- [x] `AppShell` — NavigationBar Material 3 com 5 tabs + ShellRoute GoRouter
- [x] `AppChipFilter` — chips de filtro animados, seleção única ou múltipla
- [x] `AppProgressBar` — barra animada com label, percentual e cor customizável
- [x] `AppEmptyState` — ícone + título + subtítulo + ação opcional
- [ ] Testar todos widgets isolados em um `WidgetTestScreen` temporário

> ✅ 13 de 13 widgets implementados. Concluído em 2026-06-02.

**Critério de conclusão:** Todos os 13 widgets renderizam sem erros em light e dark mode.

---

### FASE 3 — Feature: Auth (Splash, Login, Cadastro) ✅
> Objetivo: fluxo de autenticação completo com persistência local.

**Tarefas:**

**Domain:**
- [x] `UserEntity` (freezed) — id, name, email, role (producer/vet), farmName
- [x] `AuthRepository` (interface abstract)
- [x] `LoginUseCase`, `RegisterUseCase`, `LogoutUseCase`, `GetCurrentUserUseCase`

**Data:**
- [x] `UserModel` (freezed + json_serializable) — toEntity/fromEntity
- [x] `AuthLocalDataSource` — SharedPreferences (sem backend; login por e-mail salvo)
- [x] `AuthRepositoryImpl`

**Presentation:**
- [x] `authProvider` — AsyncNotifier<UserEntity?> com login/register/logout
- [x] `SplashScreen` — redireciona por sessão real (authProvider.future)
- [x] `LoginScreen` — chama authProvider, AppToast em erro, validação Formz
- [x] `RegisterScreen` — chama authProvider com UserRole tipado, persiste no SharedPreferences

> ✅ Concluído em 2026-06-02. Auth local via SharedPreferences (sem backend). loginControllerProvider e registerControllerProvider unificados no authProvider.notifier.

**Critério de conclusão:** Splash → Login → (sem conta) Cadastro → Dashboard. Persistência de sessão ao reabrir app.

---

### FASE 4 — Feature: Dashboard ✅
> Objetivo: tela principal com KPIs animados, saudação dinâmica e timeline.

**Tarefas:**

**Domain:**
- [x] `DashboardStats` entity (freezed) — totalAnimals, pregnantCount, alertCount, upcomingVaccinations, alertMessage, alertDetail
- [x] `ActivityItem` entity (freezed) — type (ActivityType enum), title, subtitle, date
- [x] `GetDashboardStatsUseCase`, `GetRecentActivitiesUseCase`

**Data:**
- [x] `DashboardLocalDataSource` — mock (TODO: agregar dados reais do Hive na Fase 5 → pendente integração)
- [x] `DashboardRepositoryImpl`

**Presentation:**
- [x] `dashboardProvider` — AsyncNotifier<DashboardState> com busca paralela (Dart 3 records `.wait`)
- [x] `DashboardScreen` — header custom (greeting/nome/fazenda/avatar), banner de alerta, RefreshIndicator
- [x] `KpiCard` — contador animado via TweenAnimationBuilder + fade/slideY com flutter_animate
- [x] `ActivityTimeline` — spine dot-line fiel ao protótipo, usa `toTimelineLabel`
- [x] `DashboardSkeleton` — layout shimmer completo (header + KPIs + módulos + timeline)
- [x] `_ModulesList` — acesso rápido a Rebanho, Brete, Vets, Relatórios via GoRouter

> ✅ Concluído em 2026-06-02.

**Critério de conclusão:** KPIs animam ao entrar, pull-to-refresh atualiza dados, greeting muda por hora.

---

### FASE 5 — Feature: Herd (Rebanho + Ficha Animal + Novo Animal) ✅
> Objetivo: gestão completa do rebanho.

**Tarefas:**

**Domain:**
- [x] `AnimalEntity` (freezed) — id, earTag, name, breed, sex, birthDate, weightKg, status (AnimalStatus), rfid, pregnancyDate
- [x] `AnimalEntityX` extension — displayName, sexLabel, ageInYears, ageInMonths, pregnancyProgress, pregnancyDays, expectedBirthDate
- [x] `AnimalRepository` (interface) — getAll, getById, save (upsert), delete
- [x] `GetAnimalsUseCase`, `GetAnimalByIdUseCase`, `SaveAnimalUseCase`, `DeleteAnimalUseCase`

**Data:**
- [x] `AnimalModel` (freezed + json_serializable) — sem hive_generator; persistência via `Box<String>` JSON
- [x] `AnimalLocalDataSource` — CRUD Hive + seed de 7 animais demonstrativos, ordenados por earTag
- [x] `AnimalRepositoryImpl`

**Presentation:**
- [x] `animalsProvider` — AsyncNotifier reativo a `herdFilterProvider` (HerdFilter enum) + `herdSearchProvider`
- [x] `animalDetailProvider` — FutureProvider.autoDispose.family<AnimalEntity?, String>
- [x] `HerdListScreen` — busca live, 5 chips de filtro (Todos/Fêmeas/Machos/Prenhas/Alertas), skeleton, FAB, swipe-to-delete com diálogo de confirmação
- [x] `AnimalListTile` — ícone status colorido, Dismissible, animação de entrada escalonada por índice
- [x] `AnimalProfileScreen` — header verde + 4 tabs (Resumo | Sanitário | Reprodução | Histórico)
- [x] `_ResumoTab` — card de prenhez com AppProgressBar (283 dias), grid de 6 ações de manejo, timeline mock
- [x] `_SanitarioTab` / `_ReproducaoTab` / `_HistoricoTab` — conteúdo parcial, aguardam Fase 6
- [x] `NewAnimalScreen` — dropdown de raça, seletor de sexo, date picker, RFID simulado, salva no Hive
- [x] `main.dart` — `Hive.openBox<String>('animals')` no boot

> ✅ Concluído em 2026-06-02.

**Critério de conclusão:** CRUD completo de animais com persistência Hive. Tabs navegáveis na ficha.

---

### FASE 6 — Feature: Vaccination (Registro de Vacinação) ✅
> Objetivo: registro de vacinação com cálculo automático de carência.

**Tarefas:**

**Domain:**
- [x] `VaccinationRecord` entity (freezed) — id, animalId, vaccineName, dose, date, quarantineDays, lot, veterinarianName, nextDoseDate
- [x] `VaccineInfo` value object — catálogo com `quarantineDaysFor()` e `nextDoseFor()` (normas MAPA)
- [x] `VaccinationRepository` (interface)
- [x] `RegisterVaccinationUseCase`, `GetAnimalVaccinationsUseCase`
- [x] `CalculateQuarantineEndUseCase` — pura, sem repositório

**Data:**
- [x] `VaccinationModel` (freezed + json_serializable) — `Box<String>` JSON, sorted by date desc
- [x] `VaccinationLocalDataSource` — CRUD Hive
- [x] `VaccinationRepositoryImpl`

**Presentation:**
- [x] `vaccinationsProvider(animalId)` — FutureProvider.autoDispose.family
- [x] `vaccinationFormProvider` — AsyncNotifier com invalidação automática do cache
- [x] `VaccinationScreen` — 5 campos, card do animal, date picker, dropdown vet (mock Fase 8)
- [x] `QuarantineCalculator` widget — cálculo reativo: próxima dose + carência por vacina
- [x] `_SanitarioTab` — lista real de vacinações com data de carência e próxima dose
- [x] `_HistoricoTab` — timeline real mesclando vacinações + eventos do animal
- [x] `_ResumoTab` — histórico recente real (sem mock)
- [x] `main.dart` — abre `Box<String>('vaccinations')` em paralelo com `'animals'`

> ✅ Concluído em 2026-06-02.

**Critério de conclusão:** Vacinação salva no animal, cálculo de carência correto, aparece no histórico.

---

### FASE 7 — Feature: Brete (IoT ESP32)
> Objetivo: painel de controle do brete eletrônico com comunicação MQTT real.

**Tarefas:**

**Domain:**
- [ ] `BreteStatus` entity (isDoorOpen, sensor1Active, sensor2Active, pedal1Active, pedal2Active, isEmergency, lastUpdated)
- [ ] `BreteRepository` (interface)
- [ ] `OpenDoorUseCase`, `CloseDoorUseCase`, `TriggerEmergencyUseCase`, `StreamBreteStatusUseCase`

**Data:**
- [ ] `MqttService` — conexão, publicação, subscribe com `mqtt_client`
- [ ] `BreteRemoteDataSource` — traduz MQTT payloads para `BreteStatus`
- [ ] `BreteRepositoryImpl`

**Presentation:**
- [ ] `breteStatusProvider` (StreamProvider — atualiza em tempo real)
- [ ] `breteControllerProvider` (AsyncNotifier para comandos)
- [ ] `BreteScreen` — painel principal
- [ ] `BreteDoorWidget` — animação 3D da porta com AnimationController (aberta/fechada)
- [ ] `SensorIndicator` widget — LED visual (verde/vermelho) por sensor
- [ ] `PedalControl` widget — botões pedal 1/2 com feedback haptico
- [ ] `EmergencyButton` widget — botão vermelho com AppBottomSheet de confirmação
- [ ] `ConnectionStatusBar` — badge MQTT (conectado/desconectado/reconectando)
- [ ] Fallback simulação para demo sem ESP32 físico

**Critério de conclusão:** Painel atualiza via MQTT stream, animação porta funciona, emergência abre confirmação.

---

### FASE 8 — Feature: Vets (Veterinários + Detalhe) ✅
> Objetivo: busca e contato de veterinários com mapa real.

**Tarefas:**

**Domain:**
- [x] `VetEntity` (freezed) — id, name, crmv, specialties, phone, whatsapp, email, city, state, lat, lng, isAvailable, coverageRadiusKm, distanceKm (runtime, não persistido)
- [x] `VetRepository` (interface)
- [x] `GetVetsUseCase`, `GetVetByIdUseCase`
- [x] `CalculateDistanceUseCase` — Haversine formula, use case puro

**Data:**
- [x] `VetModel` (freezed + json_serializable) — `Box<String>` JSON, sem hive_generator
- [x] `VetLocalDataSource` — CRUD Hive + seed de 4 veterinários ao redor de Rio Claro, SP
- [x] `LocationService` — wrapper geolocator com fallback Rio Claro, SP (-22.41, -47.56)
- [x] `VetRepositoryImpl`

**Presentation:**
- [x] `vetsProvider` — AsyncNotifier com filtro disponibilidade + busca + distâncias calculadas e ordenadas
- [x] `userLocationProvider` — FutureProvider com fallback seguro (sem crash se GPS negado)
- [x] `vetDetailProvider` — FutureProvider.autoDispose.family
- [x] `VetsListScreen` — busca, toggle disponibilidade, mapa recolhível, lista animada, pull-to-refresh
- [x] `VetsMap` widget — flutter_map + OpenStreetMap, marcador do usuário + marcadores dos vets por disponibilidade
- [x] `VetCard` widget — avatar, nome, especialidades, distância, CRMV, badge disponibilidade, animação entrada
- [x] `VetDetailScreen` — SliverAppBar com header verde, card especialidades, card localização, ContactButtons
- [x] `ContactButtons` widget — Ligar (tel:), WhatsApp (wa.me), Email (mailto:) via url_launcher
- [x] AndroidManifest — `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`
- [x] `main.dart` — abre `Box<String>('vets')` no boot

> ✅ Concluído em 2026-06-02.

**Critério de conclusão:** Mapa carrega com marcadores, distância calculada do usuário, botões de contato funcionam.

---

### FASE 9 — Feature: Reports (Relatórios) ✅
> Objetivo: geração de relatórios por tipo e período.

**Tarefas:**

**Domain:**
- [x] `ReportPeriod` enum (lastMonth, quarter, year, custom) com `dateRange` computed
- [x] `ReportType` enum (sanitary, reproductive, financial, inventory) com labels e subtítulos
- [x] `ReportFilter` — período, datas customizadas, `copyWith`
- [x] `ReportData` entity — headers, rows (List<List<String>>), metadados
- [x] `GenerateReportUseCase` — agrega `AnimalRepository` + `VaccinationRepository`:
  - Sanitário: vacinações no período com carência
  - Reprodutivo: animais prenhes com dias de gestação
  - Financeiro: animais com peso registrado
  - Inventário: rebanho completo

**Vaccination (extensão):**
- [x] `VaccinationRepository.getAll()` adicionado para o relatório sanitário

**Presentation:**
- [x] `reportFilterProvider` — StateProvider<ReportFilter>
- [x] `reportProvider` — AsyncNotifier<ReportData?> com generate/clear
- [x] `ReportTypeCard` — card com ícone, loading indicator, ação de gerar
- [x] `ReportPreview` — DataTable horizontal com zebra striping e summary card
- [x] `ReportsScreen` — chips de período, date pickers livres, 4 cards de tipo,
       chips PDF/CSV, preview inline, toast com contagem de registros

> ✅ Concluído em 2026-06-02.

**Critério de conclusão:** Cada tipo de relatório retorna dados filtrados, sem crash em período sem dados.

---

### FASE 10 — Feature: Profile (Perfil + Configurações) ✅
> Objetivo: gestão de conta, preferências e LGPD.

**Tarefas:**

**Domain (extensão Auth):**
- [x] `UpdateProfileUseCase` — atualiza nome e fazenda no SharedPreferences
- [x] `DeleteAccountUseCase` — LGPD: apaga todos os Hive boxes + SharedPreferences
- [x] `AuthRepository.updateProfile()` + `deleteAccount()` — interface + impl
- [x] `AuthNotifier.updateProfile()` + `deleteAccount()` — provider

**Presentation:**
- [x] `ProfileScreen` — hero (AppAvatar 40px, nome, role/fazenda)
- [x] Seção Conta: Editar dados (modal bottom sheet), Configurar alertas (toast), toggle Dark/Light
- [x] `_EditProfileSheet` — nome + fazenda editáveis, e-mail read-only, salva via authProvider
- [x] Seção LGPD: consentimentos, exportar dados, excluir conta com confirmação
- [x] Seção Sincronização: `_SyncCard` com botão animado e toast de sucesso
- [x] Logout — `AppBottomSheet` de confirmação → `authProvider.logout()` → `/login`
- [x] Excluir conta — `AppBottomSheet` danger → limpa todos os dados → `/login`

> ✅ Concluído em 2026-06-02.

**Critério de conclusão:** Dark mode persiste entre sessões, logout limpa dados locais, retorna ao login.

---

### FASE 11 — Qualidade, Testes & Polish
> Objetivo: app production-ready sem regressões.

**Tarefas:**

**Testes:**
- [ ] Unit tests — todos os UseCases (mocktail)
- [ ] Unit tests — Validators (Formz)
- [ ] Unit tests — Extensions
- [ ] Widget tests — Shared Widgets (AppButton, AppTextField, AppCard)
- [ ] Integration test — fluxo Auth (splash → login → dashboard → logout)

**Performance & Polish:**
- [ ] Profiling: sem jank em animações (60fps+)
- [ ] Revisar todos os `const` constructors
- [ ] Lazy loading de providers não críticos
- [ ] Imagens comprimidas em `assets/`
- [ ] Revisar permissões no AndroidManifest + Info.plist
- [ ] Ícone do app e splash screen nativas (flutter_launcher_icons + flutter_native_splash)

**Documentação:**
- [ ] Atualizar README.md com setup e arquitetura
- [ ] Docstrings nos widgets públicos do design system

**Critério de conclusão:** 0 erros de análise, testes passam, animações a 60fps.

---

## 8. Checklist de Progresso

### FASE 0 — Setup ✅
- [x] Projeto Flutter criado (`flutter create --org br.com.bovicare`)
- [x] Flutter 3.44.1 instalado + Android Studio via winget
- [x] `pubspec.yaml` configurado com stack completa (173 deps)
- [x] `analysis_options.yaml` com `very_good_analysis`
- [x] `.env` e `.env.example` criados
- [x] Assets configurados no pubspec + logo/cow_icon copiados
- [x] 98 diretórios de estrutura criados
- [x] `main.dart` com ProviderScope + dotenv + Hive + intl + orientação
- [x] Suporte web adicionado (`flutter create . --platforms web`)
- [x] `flutter analyze` → **0 issues**
- [x] `flutter run` — emulador Android configurado com GPU host, BSOD corrigido via otimização do AVD

> ✅ Concluído em: 2026-06-02.

### FASE 1 — Core ✅
- [x] `app_colors.dart` — paleta completa light + dark
- [x] `app_typography.dart` — escala Material 3 com Plus Jakarta Sans
- [x] `app_spacing.dart`, `app_radius.dart`, `app_shadows.dart`, `app_durations.dart`
- [x] `app_theme.dart` — ThemeData light + dark, Material 3 completo
- [x] `theme_provider.dart` — StateNotifier Riverpod + SharedPreferences
- [x] `app_routes.dart` — nomes e paths de todas as rotas
- [x] `app_router.dart` — GoRouter com ShellRoute, transições slide/fade
- [x] `build_context_ext.dart`, `string_ext.dart`, `datetime_ext.dart` (+ `toTimelineLabel` adicionado na Fase 4)
- [x] `failures.dart` — 6 sealed classes (implementam `Exception` para uso como throw)
- [x] `validators.dart` — EmailInput, PasswordInput, RequiredInput (Formz)
- [x] `logger.dart` — appLogger global
- [ ] `exceptions.dart` — pendente
- [ ] `dio_client.dart`, `api_endpoints.dart` — pendente (aguarda definição do backend)

> ✅ Concluído em: 2026-06-02.

### FASE 2 — Shared Widgets ✅ (13/13)
- [x] `AppButton` — 4 variantes (primary, outline, danger, ghost) + loading
- [x] `AppTextField` — toggle senha, prefixIcon, suffixIcon, errorText
- [x] `AppCard` — elevated + outlined, ripple via InkWell
- [x] `AppBottomSheet` — modal confirmação configurável
- [x] `AppToast` — success/error/info via ScaffoldMessenger
- [x] `AppSkeleton` — shimmer genérico + AnimalListTileSkeleton + KpiCardSkeleton
- [x] `AppBadge` — 5 tipos (success, danger, warning, info, neutral)
- [x] `AppAvatar` — CachedNetworkImage + fallback iniciais
- [x] `AppHeader` — verde + arco decorativo + back button + subtitle
- [x] `AppShell` — NavigationBar Material 3, 5 tabs, ShellRoute
- [x] `AppChipFilter` — chips animados, seleção única ou múltipla
- [x] `AppProgressBar` — barra animada, label, percentual, cor customizável
- [x] `AppEmptyState` — ícone + título + subtitle + ação opcional

### FASE 3 — Auth ✅
- [x] `UserEntity` (freezed) — id, name, email, role, farmName
- [x] `AuthRepository` (interface abstract)
- [x] `LoginUseCase`, `RegisterUseCase`, `LogoutUseCase`, `GetCurrentUserUseCase`
- [x] `UserModel` (freezed + json_serializable) — toEntity/fromEntity
- [x] `AuthLocalDataSource` — SharedPreferences (login, register, logout, getCurrentUser)
- [x] `AuthRepositoryImpl`
- [x] `authProvider` — AsyncNotifier<UserEntity?> com login/register/logout
- [x] `SplashScreen` — redireciona para dashboard ou login baseado em sessão real
- [x] `LoginScreen` — chama authProvider, AppToast em erro
- [x] `RegisterScreen` — chama authProvider com UserRole tipado

### FASE 4 — Dashboard ✅
- [x] `DashboardStats` entity (freezed), `ActivityItem` entity (freezed + ActivityType enum)
- [x] `GetDashboardStatsUseCase`, `GetRecentActivitiesUseCase`
- [x] `DashboardLocalDataSource` (mock, TODO Hive na Fase 5), `DashboardRepositoryImpl`
- [x] `dashboardProvider` — AsyncNotifier com DashboardState (stats + atividades em paralelo)
- [x] `DashboardScreen` — header dinâmico (bom dia/tarde/noite), avatar, banner de alerta
- [x] `KpiCard` — contador animado TweenAnimationBuilder + flutter_animate fade/slideY
- [x] `ActivityTimeline` — spine dot-line fiel ao protótipo web
- [x] `DashboardSkeleton` — shimmer layout completo
- [x] `_ModulesList` — acesso rápido a Rebanho, Brete, Vets, Relatórios
- [x] `datetime_ext.toTimelineLabel` — "Hoje, 08:14" / "Ontem, 16:32"

### FASE 5 — Herd ✅
- [x] `AnimalEntity` (freezed) — id, earTag, name, breed, sex, birthDate, weightKg, status, rfid, pregnancyDate + extensões (displayName, ageInYears, pregnancyProgress…)
- [x] `AnimalRepository` (interface) + `SaveAnimalUseCase`, `DeleteAnimalUseCase`, `GetAnimalsUseCase`, `GetAnimalByIdUseCase`
- [x] `AnimalModel` (freezed + json_serializable) — persistência via `Box<String>` JSON (sem hive_generator)
- [x] `AnimalLocalDataSource` — CRUD Hive + seed de 7 animais demonstrativos
- [x] `AnimalRepositoryImpl`
- [x] `animalsProvider` — AsyncNotifier reativo a `herdFilterProvider` + `herdSearchProvider`
- [x] `animalDetailProvider` — FutureProvider.autoDispose.family
- [x] `HerdListScreen` — busca live, chips de filtro (5 opções), skeleton, FAB, swipe-to-delete com confirmação
- [x] `AnimalListTile` — status icon colorido, Dismissible, animação de entrada escalonada
- [x] `AnimalProfileScreen` — header verde + 4 tabs (Resumo, Sanitário, Reprodução, Histórico)
- [x] `_PregnancyCard` — progress bar gestação (283 dias), data parto previsto
- [x] `_ActionGrid` — 6 ações de manejo (Vacinação funcional, demais com toast "em breve")
- [x] `NewAnimalScreen` — formulário completo, RFID simulado, date picker, salva no Hive
- [x] `main.dart` atualizado — `Hive.openBox<String>('animals')` no boot

### FASE 6 — Vaccination ✅
- [x] `VaccinationRecord` entity (freezed), `VaccineInfo` value object
- [x] `VaccinationRepository`, `RegisterVaccinationUseCase`, `GetAnimalVaccinationsUseCase`, `CalculateQuarantineEndUseCase`
- [x] `VaccinationModel` (freezed + json_serializable), `VaccinationLocalDataSource`, `VaccinationRepositoryImpl`
- [x] `vaccinationsProvider` (FutureProvider.autoDispose.family), `vaccinationFormProvider` (AsyncNotifier)
- [x] `VaccinationScreen` — formulário completo com QuarantineCalculator reativo
- [x] `_SanitarioTab`, `_HistoricoTab`, `_ResumoTab` integradas com dados reais do Hive
- [x] `flutter analyze` → 0 issues

### FASE 7 — Brete ⏸️ Adiado
> Aguarda programação do hardware ESP32. A arquitetura MQTT será implementada
> quando o hardware estiver disponível. Apenas o data source precisará ser
> criado — domain e presentation permanecerão inalterados.
- [ ] `BreteStatus` entity, `BreteRepository`
- [ ] `MqttService`, `BreteRemoteDataSource` ou `BreteSimulatedDataSource`
- [ ] `breteStatusProvider` (StreamProvider), `breteControllerProvider`
- [x] `BreteScreen` — placeholder (rota funcional)
- [ ] Animação porta, sensores, pedais, botão emergência

### FASE 8 — Vets ✅
- [x] `VetEntity` (freezed) — id, name, crmv, specialties, phone, city, lat/lng, isAvailable, coverageRadiusKm, distanceKm (runtime)
- [x] `VetRepository`, `GetVetsUseCase`, `GetVetByIdUseCase`
- [x] `CalculateDistanceUseCase` — Haversine, pura
- [x] `VetModel` (freezed + json_serializable), `VetLocalDataSource` (seed 4 vets), `VetRepositoryImpl`
- [x] `LocationService` — geolocator com fallback Rio Claro, SP
- [x] `vetsProvider` — AsyncNotifier com filtro disponibilidade + busca + distância calculada
- [x] `userLocationProvider` — FutureProvider com fallback seguro
- [x] `vetDetailProvider` — FutureProvider.autoDispose.family
- [x] `VetsListScreen` — busca, filtro disponibilidade, mapa recolhível, lista animada
- [x] `VetsMap` — flutter_map + OSM + marcadores coloridos por disponibilidade
- [x] `VetCard` — avatar, especialidades, distância, badge
- [x] `VetDetailScreen` — SliverAppBar, especialidades, localização, contato
- [x] `ContactButtons` — tel:, wa.me, mailto: via url_launcher
- [x] AndroidManifest + main.dart atualizados (permissões GPS + Box vets)

### FASE 9 — Reports ✅
- [x] `ReportType`, `ReportPeriod`, `ReportFilter`, `ReportData`, `GenerateReportUseCase`
- [x] `reportFilterProvider`, `reportProvider` (AsyncNotifier)
- [x] `ReportsScreen` — chips de período, date pickers, 4 cards de tipo, chips formato
- [x] `ReportTypeCard`, `ReportPreview` (DataTable horizontal, zebra striping)
- [x] `VaccinationRepository.getAll()` adicionado (extensão necessária)

### FASE 10 — Profile ✅
- [x] `UpdateProfileUseCase`, `DeleteAccountUseCase` (LGPD)
- [x] `AuthRepository` + `AuthRepositoryImpl` + `AuthNotifier` estendidos
- [x] `ProfileScreen` — hero completo, editar dados, toggle dark/light, LGPD, sync, logout

### FASE 11 — Qualidade
- [ ] Unit tests UseCases
- [ ] Widget tests Design System
- [ ] Integration test Auth flow
- [ ] Performance 60fps
- [ ] Ícone + splash nativa
- [ ] README finalizado

---

## 9. Regras de Qualidade

### Código
1. **Zero lógica de negócio em widgets** — apenas chamadas a providers e rendering
2. **Providers são AsyncNotifier** por padrão — não StateNotifier nu
3. **Todos os models são imutáveis** — `@freezed` obrigatório
4. **Erros tipados** — `Either<Failure, T>` em repositórios, nunca `throw` direto em domain
5. **Providers são `const`** quando possível — `ConsumerWidget` com `ref.watch`, nunca `setState`
6. **Sem imports circulares** — domain não importa data, presentation não importa data diretamente
7. **Comentários apenas quando o "por quê" não é óbvio** — sem docstrings desnecessárias
8. **Construtores `const`** em todos os widgets que suportam

### Commits
- Convenção: `feat:`, `fix:`, `refactor:`, `style:`, `test:`, `docs:`
- Um commit por tarefa concluída, não por fase

### Atualizações deste arquivo
- Ao concluir uma tarefa: marque `[x]` e adicione `> ✅ Concluído em: <data>. Como foi feito: <descrição breve.>`
- Ao iniciar uma fase: atualize o Status no cabeçalho

---

*Documento mantido sincronizado com o progresso real do desenvolvimento.*
