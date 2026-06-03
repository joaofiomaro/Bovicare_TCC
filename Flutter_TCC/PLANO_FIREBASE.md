# BoviCare — Plano de Integração Firebase
> Status: 🟡 Em Andamento — ETAPAs 1, 2, 3 e 5 concluídas · ETAPA 4 pendente (manual) · ETAPAs 6–12 pendentes
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

## 1. Auditoria do Estado Atual

### 1.1 Autenticação (PROBLEMA CRÍTICO)

| Aspecto | Estado atual | Problema |
|---|---|---|
| Mecanismo | SharedPreferences JSON | Não é autenticação real |
| Senha | Não é validada | Qualquer e-mail conhecido loga |
| Sessão | Booleano local | Sem expiração, sem token |
| Multi-device | Impossível | Dados presos no dispositivo |
| Segurança | Nula | Dados acessíveis sem credencial real |

### 1.2 Banco de Dados (OFFLINE-LOCAL ONLY)

| Box Hive | Dados | Sync | Problema |
|---|---|---|---|
| `animals` | 7 animais seed | ❌ Nenhum | Perdido se app reinstalado |
| `vaccinations` | Registros locais | ❌ Nenhum | Não existe na nuvem |
| `vets` | Seed fixo | ❌ Nenhum | Igual em todos os dispositivos |
| `SharedPreferences` | Usuário + sessão | ❌ Nenhum | Apagado com o app |

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
lib/core/                          ← todo o core
lib/features/*/domain/             ← todas as entities, use cases, repositories
lib/features/*/presentation/       ← todos os screens e widgets
lib/shared/widgets/                ← design system
lib/core/router/                   ← navegação
```

### MUDA (Data Sources e inicialização)
```
lib/main.dart                                    ← init Firebase + remover Hive de animals/vaccinations
lib/features/auth/data/datasources/              ← AuthLocalDataSource → AuthFirebaseDataSource
lib/features/auth/data/repositories/             ← injetar Firebase
lib/features/herd/data/datasources/              ← AnimalLocalDataSource → AnimalFirestoreDataSource
lib/features/herd/data/models/                   ← AnimalModel.toFirestore() / fromFirestore()
lib/features/vaccination/data/datasources/       ← VaccinationLocalDataSource → VaccinationFirestoreDataSource
lib/features/vaccination/data/models/            ← VaccinationModel.toFirestore() / fromFirestore()
pubspec.yaml                                     ← novas dependências Firebase
android/build.gradle.kts                         ← Google services plugin
android/app/build.gradle.kts                     ← apply plugin
android/app/google-services.json                 ← NÃO commitado (.gitignore)
```

### REMOVIDO
```
lib/features/auth/data/datasources/auth_local_data_source.dart   ← substituído
lib/features/herd/data/datasources/animal_local_data_source.dart ← substituído
lib/features/vaccination/data/datasources/vaccination_local_data_source.dart ← substituído
Hive.openBox('animals')   ← removido do main.dart
Hive.openBox('vaccinations') ← removido do main.dart
hive_flutter (pubspec)    ← avaliar remoção
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

**O Hive permanece apenas para:**
- Dados que não precisam de cloud (preferência de tema → SharedPreferences)
- Cache de vets (seed público, raramente muda)

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
/users/{uid}/animals/{animalId}
/users/{uid}/vaccinations/{vaccinationId}
/vets/{vetId}   ← coleção pública, leitura autenticada
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

### Coleção pública: `/vets/{vetId}`
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

### Adicionar ao pubspec.yaml
```yaml
# Firebase
firebase_core:    ^3.6.0
firebase_auth:    ^5.3.1
cloud_firestore:  ^5.4.4
google_sign_in:   ^6.2.1
```

### Remover do pubspec.yaml (após migração confirmada)
```yaml
# hive_flutter — remover se nenhum Box for usado para dados de negócio
# Manter shared_preferences para SharedPreferences (theme)
```

### Manter
```yaml
shared_preferences  # para themeProvider
freezed             # models continuam imutáveis
json_serializable   # continua útil para testes e modelos
```

---

## 7. Checklist de Segurança

Executar ANTES de qualquer commit Firebase:

- [x] `google-services.json` adicionado ao `Flutter_TCC/.gitignore`
- [x] `GoogleService-Info.plist` adicionado ao `Flutter_TCC/.gitignore` (iOS)
- [x] `git status` confirmado — nenhum arquivo sensível no staging (commit `2676dd6`)
- [x] Firestore em **Production Mode** (não Test Mode) — confirmado, região `southamerica-east1`
- [ ] Security Rules publicadas ANTES de qualquer dado ser salvo — pendente ETAPA 4
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
- [x] `Hive.openBox('vets')` mantido (seed local)
- [ ] Testar boot sem crash no emulador
- [x] **Commit:** incluído no commit `2676dd6` junto com ETAPA 2

> ✅ Concluído em 2026-06-03. `firebase_options.dart` gerado pelo flutterfire e importado no main.dart. Boot aguarda teste no emulador (ETAPA 4 primeiro, pois as Security Rules precisam estar publicadas).

---

### ETAPA 4 — Publicar Security Rules e Index

- [ ] Publicar Firestore Security Rules no Console
- [ ] Criar index composto: `vaccinations → animalId ASC, dateIso DESC`
- [ ] Verificar que regras bloqueiam acesso não autenticado
- [ ] **Nenhum commit** (configuração no console)

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

> ✅ Concluído em 2026-06-03. `flutter analyze` → 0 issues. Teste funcional aguarda habilitação de Authentication no Console (ETAPA 4).

---

### ETAPA 6 — Animals: Hive → Firestore

- [ ] Adicionar `toFirestore()` e `fromFirestore()` ao `AnimalModel`
- [ ] Criar `AnimalFirestoreDataSource`
  - Usa `FirebaseFirestore.instance.collection('users/$uid/animals')`
  - Mantém os mesmos métodos: `getAll()`, `getById()`, `save()`, `delete()`
  - `uid` obtido via `FirebaseAuth.instance.currentUser!.uid`
- [ ] Atualizar `AnimalRepositoryImpl` → usar `AnimalFirestoreDataSource`
- [ ] Testar CRUD offline + online
- [ ] Testar sync após reconexão
- [ ] **Commit:** `feat(herd): migrate animal data source from Hive to Firestore`

---

### ETAPA 7 — Vaccinations: Hive → Firestore

- [ ] Adicionar `toFirestore()` e `fromFirestore()` ao `VaccinationModel`
- [ ] Criar `VaccinationFirestoreDataSource`
  - `getAll()` → query sem filtro (para relatórios)
  - `getByAnimal(animalId)` → query com `where('animalId', isEqualTo: id)`
  - `save()`, `delete()`
- [ ] Atualizar `VaccinationRepositoryImpl`
- [ ] Criar index composto no Firestore se necessário
- [ ] Testar registro de vacinação + listagem
- [ ] **Commit:** `feat(vaccination): migrate vaccination data source to Firestore`

---

### ETAPA 8 — Dashboard: conectar ao Firestore

- [ ] Atualizar `DashboardLocalDataSource` → agregar dados reais do Firestore
  - `totalAnimals` = count da collection animals
  - `pregnantCount` = count com status == pregnant
  - `alertCount` = count com status sick ou attention
- [ ] Testar KPIs refletindo dados reais
- [ ] **Commit:** `feat(dashboard): connect stats to real Firestore data`

---

### ETAPA 9 — Vets: seed no Firestore (opcional)

- [ ] Avaliar: manter vets locais (Hive/seed) ou migrar para Firestore
  - Se migrar: criar script de seed único para popular `/vets`
  - Se manter local: sem alteração
- [ ] **Commit:** `feat(vets): seed vet data to Firestore public collection` (se aplicável)

---

### ETAPA 10 — Limpeza e remoção do Hive

- [ ] Remover `hive_flutter` do `pubspec.yaml` (se nenhum Box restante)
- [ ] Remover imports e arquivos de datasource antigos
- [ ] Remover `AnimalLocalDataSource`, `VaccinationLocalDataSource`, `AuthLocalDataSource`
- [ ] `flutter analyze` → 0 issues
- [ ] **Commit:** `refactor: remove Hive data sources replaced by Firestore`

---

### ETAPA 11 — Auth Guard no Router

- [ ] Adicionar redirect no `app_router.dart`
  - Rotas protegidas → redirect para `/login` se `FirebaseAuth.currentUser == null`
  - `/login` e `/register` → redirect para `/dashboard` se já autenticado
- [ ] **Commit:** `feat(router): add Firebase auth guard to protected routes`

---

### ETAPA 12 — Auditoria Final

- [ ] `flutter analyze` → **0 issues**
- [ ] Testar fluxo completo sem internet (modo avião)
- [ ] Testar sync ao reconectar
- [ ] Verificar Security Rules bloqueando user A acessar dados de user B
- [ ] `git status` → confirmar nenhum arquivo sensível no repo
- [ ] Atualizar `PLANO_DESENVOLVIMENTO_FLUTTER.md`
- [ ] **Commit:** `chore: Firebase integration complete — final audit`

---

## 9. Critérios de Conclusão

| Critério | Como verificar |
|---|---|
| Auth real | Login com Google funciona sem SharedPreferences |
| Dados na nuvem | Animal criado no app aparece no Firestore Console |
| Offline-first | Criar animal no modo avião → aparece no Firestore ao reconectar |
| Isolamento | User A não vê dados de User B |
| Segurança | `google-services.json` não está no repositório |
| Qualidade | `flutter analyze` → 0 issues |
| SplashScreen | Redireciona corretamente sem `Future.delayed` |
| Logout | Limpa sessão Firebase + Google Sign-In |

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
