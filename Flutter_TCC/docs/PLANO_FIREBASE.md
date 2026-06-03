# BoviCare — Plano de Integração Firebase
> Status: ✅ Integração Firebase Completa — todas as ETAPAs concluídas · Testes no emulador pendentes
> Criado em: 2026-06-02 · Última atualização: 2026-06-03

---

## Índice

1. [Auditoria do Estado Atual](#1-auditoria-do-estado-atual)
2. [O que Muda e o que Permanece](#2-o-que-muda-e-o-que-permanece)
3. [Decisões de Arquitetura](#3-decisões-de-arquitetura)
4. [Esquema Firestore](#4-esquema-firestore)
5. [Regras de Segurança](#5-regras-de-segurança)
6. [Dependências](#6-dependências)
7. [Checklist de Segurança](#7-checklist-de-segurança)
8. [Etapas de Implementação](#8-etapas-de-implementação)
9. [Critérios de Conclusão](#9-critérios-de-conclusão)

---

## 1. Auditoria do Estado Anterior

> ✅ **Todos os problemas abaixo foram resolvidos.** Esta seção documenta o estado ANTES da integração Firebase.

### 1.1 Autenticação ~~(PROBLEMA CRÍTICO)~~ → ✅ RESOLVIDO (ETAPA 5)

| Aspecto | Estado anterior | Estado atual |
|---|---|---|
| Mecanismo | SharedPreferences JSON | Firebase Auth (email/senha + Google) |
| Senha | Não era validada | Validada pelo Firebase |
| Sessão | Booleano local | Token JWT com expiração automática |
| Multi-device | Impossível | ✅ Sincronizado via Firebase |
| Segurança | Nula | ✅ Auth guard no router + Security Rules |

### 1.2 Banco de Dados ~~(OFFLINE-LOCAL ONLY)~~ → ✅ RESOLVIDO (ETAPAs 6–10)

| Fonte | Dados | Sync | Estado atual |
|---|---|---|---|
| ~~Box Hive `animals`~~ | 7 animais seed | ❌ | ✅ Firestore `/users/{uid}/animals` |
| ~~Box Hive `vaccinations`~~ | Registros locais | ❌ | ✅ Firestore `/users/{uid}/vaccinations` |
| ~~Box Hive `vets`~~ | Seed fixo | ❌ | ✅ In-memory estático (VetInMemoryDataSource) |
| ~~SharedPreferences auth~~ | Usuário + sessão | ❌ | ✅ Firebase Auth + Firestore `/users/{uid}` |

### 1.3 O que Funciona Bem (NÃO MUDA)

- ✅ Toda a camada de domínio (entities, use cases, repositories interfaces)
- ✅ Todos os widgets e screens (UI)
- ✅ Providers Riverpod (lógica de apresentação)
- ✅ Design system (AppColors, AppTheme, widgets compartilhados)
- ✅ Navegação GoRouter
- ✅ Linting e qualidade de código

---

## 2. O que Muda e o que Permanece

### PERMANECE INTACTO (Zero alterações)
```
lib/features/*/domain/             ← todas as entities, use cases, repositories
lib/features/*/presentation/       ← todos os screens e widgets (exceto login_screen.dart*)
lib/shared/widgets/                ← design system
```
> *`login_screen.dart` recebeu o botão "Continuar com Google" (adição, não alteração de lógica existente).

### MUDOU (Data Sources e inicialização) ✅ CONCLUÍDO
```
lib/main.dart                                    ✅ Firebase init, Firestore offline, Hive removido
lib/core/router/app_router.dart                  ✅ Auth guard + refreshListenable
lib/features/auth/data/datasources/              ✅ AuthFirebaseDataSource (substituiu AuthLocalDataSource)
lib/features/auth/data/repositories/             ✅ Firebase injetado
lib/features/auth/data/models/user_model.dart    ✅ fromFirestore() / toFirestore()
lib/features/herd/data/datasources/              ✅ AnimalFirestoreDataSource (substituiu local)
lib/features/herd/data/models/                   ✅ AnimalModel.toFirestore() / fromFirestore()
lib/features/vaccination/data/datasources/       ✅ VaccinationFirestoreDataSource (substituiu local)
lib/features/vaccination/data/models/            ✅ VaccinationModel.toFirestore() / fromFirestore()
lib/features/vets/data/datasources/              ✅ VetInMemoryDataSource (substituiu VetLocalDataSource)
lib/features/dashboard/data/datasources/         ✅ DashboardFirestoreDataSource (substituiu mock)
pubspec.yaml                                     ✅ Firebase deps adicionadas, hive_flutter removido
android/settings.gradle.kts                     ✅ Google Services plugin (via flutterfire)
android/app/build.gradle.kts                     ✅ apply plugin google-services (via flutterfire)
android/app/google-services.json                 ✅ NÃO commitado (.gitignore)
lib/firebase_options.dart                        ✅ gerado pelo flutterfire configure
```

### REMOVIDO ✅ CONCLUÍDO
```
lib/features/auth/data/datasources/auth_local_data_source.dart          ✅ removido
lib/features/herd/data/datasources/animal_local_data_source.dart        ✅ removido
lib/features/vaccination/data/datasources/vaccination_local_data_source.dart ✅ removido
lib/features/vets/data/datasources/vet_local_data_source.dart           ✅ removido
lib/features/dashboard/data/datasources/dashboard_local_data_source.dart ✅ removido
Hive.initFlutter()       ✅ removido do main.dart
Hive.openBox('animals')  ✅ removido do main.dart
Hive.openBox('vaccinations') ✅ removido do main.dart
Hive.openBox('vets')     ✅ removido do main.dart
hive_flutter (pubspec)   ✅ removido — zero imports restantes em lib/
```

---

## 3. Decisões de Arquitetura

### 3.1 Estratégia Offline-First

**Decisão: Firestore com persistência habilitada (sem Hive para dados de negócio)**

O Firestore tem persistência offline nativa:
- Offline → lê do cache local + enfileira writes
- Online → sincroniza automaticamente
- Conflitos → last-write-wins (suficiente para o TCC)

```dart
// Configuração no main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Hive foi completamente removido.** Substituições finais:
- Preferência de tema → `SharedPreferences` (mantido)
- Vets → `VetInMemoryDataSource` (lista `const` estática, sem I/O)

### 3.2 Autenticação

**Estratégia dual:**
1. **Google Sign-In** (primário) — OAuth via conta Google
2. **E-mail + senha** (fallback) — Firebase Auth nativo

**Fluxo:**
```
SplashScreen → Firebase.currentUser
  ├── null   → LoginScreen
  └── User   → DashboardScreen
```

### 3.3 Modelo de Dados (por usuário)

Cada produtor tem seus próprios dados isolados:
```
/users/{uid}/animals/{animalId}        ← Firestore ✅
/users/{uid}/vaccinations/{vaccinationId} ← Firestore ✅
vets                                   ← in-memory estático (não usa Firestore)
```

### 3.4 Modelos Firestore

Os `Model` atuais (freezed + json_serializable) ganham dois métodos:
```dart
factory AnimalModel.fromFirestore(DocumentSnapshot doc) { ... }
Map<String, dynamic> toFirestore() { ... }
```
`toJson()` / `fromJson()` continuam existindo para compatibilidade e testes.

---

## 4. Esquema Firestore

### Coleção: `/users/{uid}`
```
{
  name:      string,
  email:     string,
  role:      string,       // "producer" | "vet"
  farmName:  string | null,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Subcoleção: `/users/{uid}/animals/{animalId}`
```
{
  earTag:          string,
  name:            string | null,
  breed:           string,
  sex:             string,       // "male" | "female"
  status:          string,       // "healthy" | "pregnant" | "attention" | "sick"
  birthDateIso:    string,       // ISO 8601
  weightKg:        number | null,
  rfid:            string | null,
  pregnancyDateIso: string | null,
  createdAt:       timestamp,
  updatedAt:       timestamp
}
```

### Subcoleção: `/users/{uid}/vaccinations/{vaccinationId}`
```
{
  animalId:         string,
  vaccineName:      string,
  dose:             string,
  dateIso:          string,
  quarantineDays:   number,
  lot:              string | null,
  veterinarianName: string | null,
  nextDoseDateIso:  string | null,
  createdAt:        timestamp
}
```

### Coleção pública: `/vets/{vetId}` — ⚠️ NÃO UTILIZADA

> Decisão final (ETAPA 9): vets são dados demo estáticos que nunca mudam.
> Implementados como `VetInMemoryDataSource` (`const` list) — sem Firestore, sem leitura de rede.
> O schema abaixo é mantido como referência caso a coleção seja populada no futuro.

```
{
  name:             string,
  crmv:             string,
  specialties:      array<string>,
  phone:            string,
  whatsapp:         string | null,
  email:            string | null,
  city:             string,
  state:            string,
  lat:              number,
  lng:              number,
  isAvailable:      boolean,
  coverageRadiusKm: number
}
```

---

## 5. Regras de Segurança

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuário autenticado acessa apenas seus próprios dados
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /animals/{animalId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }

      match /vaccinations/{vaccinationId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }

    // Veterinários: leitura pública para autenticados, escrita bloqueada
    match /vets/{vetId} {
      allow read:  if request.auth != null;
      allow write: if false;
    }
  }
}
```

### Firestore Indexes (compostos necessários)
```
Collection: vaccinations
Fields: animalId ASC, dateIso DESC
→ Necessário para GetAnimalVaccinationsUseCase e relatórios sanitários
```

---

## 6. Dependências

### Adicionado ao pubspec.yaml ✅
```yaml
# Firebase
firebase_core:    ^3.6.0   ✅ instalado (3.15.2)
firebase_auth:    ^5.3.1   ✅ instalado (5.7.0)
cloud_firestore:  ^5.4.4   ✅ instalado (5.6.12)
google_sign_in:   ^6.2.1   ✅ instalado (6.3.0)
```

### Removido do pubspec.yaml ✅
```yaml
hive_flutter: ^1.1.0  ✅ removido — zero usos restantes em lib/
```

### Mantido
```yaml
shared_preferences  ✅ mantido — themeProvider
freezed             ✅ mantido — models imutáveis
json_serializable   ✅ mantido — serialização JSON
```

---

## 7. Checklist de Segurança

Executar ANTES de qualquer commit Firebase:

- [x] `google-services.json` adicionado ao `Flutter_TCC/.gitignore`
- [x] `GoogleService-Info.plist` adicionado ao `Flutter_TCC/.gitignore` (iOS)
- [x] `git status` confirmado — nenhum arquivo sensível no staging (commit `2676dd6`)
- [x] Firestore em **Production Mode** (não Test Mode) — confirmado, região `southamerica-east1`
- [x] Security Rules publicadas ANTES de qualquer dado ser salvo — publicadas em 2026-06-03
- [x] SHA-1 do app registrado no Firebase — `CF:52:EC:10:F6:88:7D:54:96:90:68:7B:EB:FB:3E:A1:D3:88:16:91`
- [x] Nenhuma API key de servidor hardcoded — `firebase_options.dart` contém apenas chaves de cliente (seguras para commitar)
- [x] `.env` continua no `.gitignore`

---

## 8. Etapas de Implementação

> Cada etapa deve ser concluída, testada e commitada antes de iniciar a próxima.

---

### ETAPA 1 — Setup Firebase Console (manual — você executa) ✅

- [x] Criar projeto em [console.firebase.google.com](https://console.firebase.google.com)
- [x] Habilitar Authentication → Google Sign-In
- [x] Habilitar Authentication → E-mail/senha
- [x] Criar Cloud Firestore → Production Mode → região `southamerica-east1`
- [x] Registrar apps Flutter (Android, iOS, Web) via `flutterfire configure --project=bovicare-tcc`
- [x] Obter SHA-1 e registrar no Firebase Console → `CF:52:EC:10:F6:88:7D:54:96:90:68:7B:EB:FB:3E:A1:D3:88:16:91` (debug keystore)
- [x] `google-services.json` gerado automaticamente pelo flutterfire em `android/app/`
- [x] **`google-services.json` e `GoogleService-Info.plist` adicionados ao `.gitignore`**

> ✅ Concluído em 2026-06-03. Todos os itens confirmados. SHA-1 debug registrado no Firebase Console.

---

### ETAPA 2 — Dependências e Configuração Android ✅

- [x] Adicionar pacotes Firebase ao `pubspec.yaml` (`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`)
- [x] `android/settings.gradle.kts` → Google Services plugin adicionado pelo flutterfire
- [x] `android/app/build.gradle.kts` → `com.google.gms.google-services` aplicado pelo flutterfire
- [x] `flutter pub get` → dependências instaladas sem conflitos
- [x] `flutter analyze` → **0 issues**
- [x] **Commit:** `chore: add Firebase dependencies and initialize Firebase (ETAPAs 2 e 3)` — hash `2676dd6`

> ✅ Concluído em 2026-06-03. Gradle configurado automaticamente pelo flutterfire configure.

---

### ETAPA 3 — Inicialização Firebase e Firestore offline ✅

- [x] `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` no `main.dart`
- [x] Firestore configurado com `persistenceEnabled: true` e `cacheSizeBytes: CACHE_SIZE_UNLIMITED`
- [x] `Hive.openBox('animals')` removido do `main.dart`
- [x] `Hive.openBox('vaccinations')` removido do `main.dart`
- [x] `Hive.openBox('vets')` ~~mantido~~ → removido na ETAPA 10 (vets migrado para in-memory)
- [x] `Hive.initFlutter()` removido na ETAPA 10
- [ ] Testar boot sem crash no emulador
- [x] **Commit:** incluído no commit `2676dd6` junto com ETAPA 2

> ✅ Concluído em 2026-06-03. `firebase_options.dart` gerado pelo flutterfire e importado no main.dart.

---

### ETAPA 4 — Publicar Security Rules e Index 🟡 Parcial

- [x] Publicar Firestore Security Rules no Console — isolamento por `uid`, vets somente leitura
- [x] Criar index composto: `vaccinations → animalId ASC, dateIso DESC` — deployado via `firebase deploy --only firestore:indexes`
  - `firestore.indexes.json` criado e versionado no repositório
  - `firebase.json` atualizado com seção `firestore`
  - `VaccinationFirestoreDataSource` atualizado para usar `orderBy` server-side
- [x] Acesso não autenticado bloqueado no router (ETAPA 11 — auth guard) · validação Firestore-level pendente de teste no emulador
- [x] **Commit:** `feat(firestore): add composite index and enable server-side ordering`

> ✅ Concluído em 2026-06-03. ETAPA 4 100% completa.

---

### ETAPA 5 — Auth: Firebase + Google Sign-In ✅

- [x] Criar `AuthFirebaseDataSource` (substitui `AuthLocalDataSource`)
  - `loginWithEmail()` → `signInWithEmailAndPassword` + mapeamento de erros PT-BR
  - `loginWithGoogle()` → GoogleSignIn OAuth + Firebase credential (null = cancelado)
  - `register()` → `createUserWithEmailAndPassword` + doc `/users/{uid}` no Firestore
  - `logout()` → `FirebaseAuth.signOut()` + `GoogleSignIn.signOut()` em paralelo
  - `getCurrentUser()` → `FirebaseAuth.currentUser` + fetch Firestore profile
  - `updateProfile()` → `update` doc `/users/{uid}` com `updatedAt` serverTimestamp
  - `deleteAccount()` → batch-delete `/animals` + `/vaccinations` + `user.delete()` (LGPD)
- [x] `LoginWithGoogleUseCase` adicionado ao domain layer
- [x] `loginWithGoogle()` adicionado à interface `AuthRepository`
- [x] `fromFirestore()` e `toFirestore()` adicionados ao `UserModel`
- [x] `AuthRepositoryImpl` atualizado — remove dependência Hive
- [x] `AuthNotifier.loginWithGoogle()` — distingue cancelamento de erro
- [x] `SplashScreen` → `FirebaseAuth.instance.currentUser` (síncrono, sem chamada de rede)
- [x] `LoginScreen` → botão "Continuar com Google" com divider
- [x] `auth_local_data_source.dart` removido
- [ ] Testar fluxo completo no emulador (pendente ETAPA 4 — Console)
- [x] **Commit:** `feat(auth): replace mock auth with Firebase Auth and Google Sign-In` — hash `a9d299f`

> ✅ Concluído em 2026-06-03. `flutter analyze` → 0 issues. Authentication (Google + email/senha) habilitado no Console (ETAPA 1). Pronto para teste no emulador.

---

### ETAPA 6 — Animals: Hive → Firestore ✅

- [x] `fromFirestore()` e `toFirestore()` adicionados ao `AnimalModel`
- [x] `AnimalFirestoreDataSource` criado
  - `getAll()` ordena por `earTag`, seed de 7 animais demo no primeiro login
  - `save()` upsert com `createdAt`/`updatedAt` serverTimestamp
  - Seed via batch write (único round-trip de rede)
- [x] `AnimalRepositoryImpl` atualizado
- [x] `animals_provider.dart` DI atualizado
- [x] `animal_local_data_source.dart` removido
- [ ] Testar CRUD offline + online no emulador
- [x] **Commit:** `feat(data): migrate animals, vaccinations and dashboard to Firestore` — hash `423aeda`

> ✅ Concluído em 2026-06-03.

---

### ETAPA 7 — Vaccinations: Hive → Firestore ✅

- [x] `fromFirestore()` e `toFirestore()` adicionados ao `VaccinationModel`
- [x] `VaccinationFirestoreDataSource` criado
  - `getAll()` e `getByAnimal()` com ordenação client-side (evita índice composto por ora)
  - `save()` upsert com serverTimestamp
- [x] `VaccinationRepositoryImpl` atualizado
- [x] `vaccinations_provider.dart` DI atualizado
- [x] `vaccination_local_data_source.dart` removido
- [ ] Testar registro de vacinação + listagem no emulador
- [x] **Commit:** incluído em `423aeda`

> ✅ Concluído em 2026-06-03. Índice composto pendente (ETAPA 4) — ordenação client-side como fallback temporário.

---

### ETAPA 8 — Dashboard: conectar ao Firestore ✅

- [x] `DashboardFirestoreDataSource` criado (substitui mock)
  - `totalAnimals`, `pregnantCount`, `alertCount` via `count()` aggregation paralela
  - `upcomingVaccinations` — janela de 30 dias via range query
  - Activities: mock mantido intencionalmente (audit trail fora do escopo)
- [x] `DashboardRepositoryImpl` atualizado
- [x] `dashboard_provider.dart` DI atualizado
- [x] `dashboard_local_data_source.dart` removido
- [ ] Testar KPIs refletindo dados reais no emulador
- [x] **Commit:** incluído em `423aeda`

> ✅ Concluído em 2026-06-03.

---

### ETAPA 9 — Vets: in-memory ✅

- [x] Decisão: **in-memory** — dados estáticos, sem Hive, sem Firestore
- [x] `VetInMemoryDataSource` com lista `const` de 4 vets (zero I/O)
- [x] `VetRepositoryImpl` e `vets_provider.dart` atualizados
- [x] `vet_local_data_source.dart` removido
- [x] **Commit:** `feat: implement ETAPAs 9, 10, 11` — hash `2a35980`

> ✅ Concluído em 2026-06-03. Opção in-memory é ideal: dados demo nunca mudam, resposta instantânea, sem custo de rede.

---

### ETAPA 10 — Limpeza e remoção do Hive ✅

- [x] `hive_flutter` removido do `pubspec.yaml`
- [x] `Hive.initFlutter()` e `Hive.openBox('vets')` removidos do `main.dart`
- [x] Todos os datasources locais removidos (auth, animals, vaccinations, vets)
- [x] Zero imports de Hive restantes em `lib/` (verificado via grep)
- [x] `flutter analyze` → **0 issues**
- [x] **Commit:** incluído em `2a35980`

> ✅ Concluído em 2026-06-03. Hive completamente removido da aplicação.

---

### ETAPA 11 — Auth Guard no Router ✅

- [x] `_AuthChangeListenable`: ChangeNotifier wrapping `authStateChanges()` com `StreamSubscription` gerenciado
- [x] `refreshListenable` vinculado ao Firebase Auth — redirect automático em login/logout
- [x] Redirect global: rotas protegidas → `/login` se não autenticado; `/login`/`/register` → `/dashboard` se autenticado; `/splash` ignorado (gerencia próprio redirect)
- [x] `appRouterProvider` migrado para Provider Riverpod com `ref.onDispose`
- [x] **Commit:** incluído em `2a35980`

> ✅ Concluído em 2026-06-03.

---

### ETAPA 12 — Auditoria Final ✅

- [x] `flutter analyze` → **0 issues**
- [x] `git status` → working tree clean, nenhum arquivo sensível no repo
- [x] `google-services.json` não está no repositório (.gitignore confirmado)
- [ ] Testar fluxo completo no emulador (login → dashboard → CRUD → logout)
- [ ] Testar offline (modo avião) + sync ao reconectar
- [ ] Verificar Security Rules bloqueando user A acessar dados de user B
- [x] `PLANO_DESENVOLVIMENTO_FLUTTER.md` atualizado
- [x] **Commit:** `chore: Firebase integration complete — final audit`

> 🟡 Código 100% completo. Testes no emulador pendentes.

---

## 9. Critérios de Conclusão

| Critério | Como verificar | Status |
|---|---|---|
| Auth real | Login com Google funciona sem SharedPreferences | ⏳ testar no emulador |
| Dados na nuvem | Animal criado no app aparece no Firestore Console | ⏳ testar no emulador |
| Offline-first | Criar animal no modo avião → aparece no Firestore ao reconectar | ⏳ testar no emulador |
| Isolamento | User A não vê dados de User B | ⏳ testar no emulador |
| Segurança | `google-services.json` não está no repositório | ✅ confirmado via git status |
| Qualidade | `flutter analyze` → 0 issues | ✅ confirmado |
| SplashScreen | Redireciona corretamente sem chamada de rede | ✅ usa `FirebaseAuth.currentUser` síncrono |
| Logout | Limpa sessão Firebase + Google Sign-In | ✅ `signOut()` + `GoogleSignIn.signOut()` em paralelo |

---

## Notas Importantes

### SHA-1 para Google Sign-In
O Google Sign-In exige o SHA-1 do certificado de debug registrado no Firebase.
Para obter:
```powershell
cd Flutter_TCC/android
./gradlew signingReport
```
O SHA-1 aparece na linha `SHA1:`. Adicionar no Firebase Console → Project Settings → Android App → Add fingerprint.

### Região Firestore
Escolher `southamerica-east1` (São Paulo) para menor latência no Brasil. **Não pode ser alterada após criação.**

### google-services.json
Este arquivo contém a `api_key` do projeto Firebase. Nunca commitar.
O `.gitignore` do Flutter já foi configurado para excluir `.env`, mas `google-services.json` precisa ser adicionado explicitamente:
```
# Firebase — nunca commitar
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### Plano de rollback
Se alguma etapa der errado, cada commit é independente. É possível reverter etapa por etapa com `git revert <hash>` sem perder o progresso das etapas anteriores.

---

*Este documento deve ser mantido atualizado conforme as etapas são concluídas.*
