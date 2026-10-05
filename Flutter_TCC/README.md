# BoviCare

Aplicativo mobile de gestão de rebanho bovino desenvolvido como TCC (Trabalho de Conclusão de Curso). Conecta produtores rurais e veterinários, oferecendo controle sanitário, gestão de animais e integração com brete eletrônico (ESP32).

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.44+ / Dart 3.12+ |
| State Management | Riverpod 2 (AsyncNotifier + code gen) |
| Navegação | GoRouter 15 (ShellRoute + auth guard) |
| Backend | Firebase Auth + Cloud Firestore |
| Auth | Firebase Auth (e-mail/senha + Google Sign-In) |
| Banco de dados | Firestore (offline-first, persistência nativa) |
| UI | Material 3, Plus Jakarta Sans, flutter_animate |
| Mapas | flutter_map + OpenStreetMap (sem chave de API) |
| IoT | MQTT (brete ESP32 — aguarda hardware) |
| Qualidade | very_good_analysis, mocktail, flutter_test |

---

## Arquitetura

Feature-First Clean Architecture com três camadas por feature:

```
Presentation  →  Providers Riverpod + Screens + Widgets
Domain        →  Entities (Freezed) + Use Cases + Repository Interfaces
Data          →  Models + Data Sources (Firestore/in-memory) + Repository Impls
```

```
lib/
├── core/           # Constants, errors, extensions, router, theme, utils
├── features/
│   ├── auth/       # Firebase Auth + Google Sign-In
│   ├── dashboard/  # KPIs agregados via Firestore count()
│   ├── herd/       # Rebanho: CRUD, ficha (4 tabs), baixa (venda/óbito), arquivados
│   ├── vaccination/# Registros sanitários (Firestore)
│   ├── brete/      # Painel IoT ESP32 (placeholder)
│   ├── vets/       # Veterinários (in-memory)
│   ├── weighing/   # Pesagens e ganho de peso (GMD)
│   ├── service_call/# Chamados produtor↔vet (coleção compartilhada)
│   ├── reports/    # Relatórios por tipo e período
│   └── profile/    # Perfil + LGPD + configurações
└── shared/
    └── widgets/    # Design system (AppButton, AppCard, AppTextField…)

firestore-tests/    # Testes das Security Rules (emulador + rules-unit-testing)
firestore.rules     # Regras de segurança (versionadas e publicadas)
firestore.indexes.json
```

---

## Pré-requisitos

- Flutter SDK ≥ 3.22
- Android Studio (AVD com GPU host mode recomendado)
- Conta Google com acesso ao Firebase Console

---

## Setup

**1. Clone o repositório**
```bash
git clone https://github.com/joaofiomaro/Bovicare_TCC.git
cd Bovicare_TCC/Flutter_TCC
```

**2. Instale as dependências**
```bash
flutter pub get
```

**3. Configure o Firebase**

O arquivo `google-services.json` não está no repositório (dados sensíveis).
Para configurar seu próprio Firebase:

```bash
# Instale os CLIs
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Autentique
firebase login

# Configure (cria lib/firebase_options.dart e android/app/google-services.json)
flutterfire configure --project=SEU_PROJETO_ID
```

No Firebase Console:
- Habilite Authentication → Google Sign-In e E-mail/senha
- Crie o Firestore em Production Mode (região: `southamerica-east1`)
- Registre o SHA-1 do debug keystore: `cd android && ./gradlew signingReport`

**4. Crie o `.env`**
```bash
cp .env.example .env
# Edite conforme necessário (MQTT_BROKER_URL, etc.)
```

**5. Deploy das Security Rules e índices Firestore**

O `.firebaserc` já aponta o projeto padrão, então basta (a partir de `Flutter_TCC/`):
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

**6. Execute o app**
```bash
flutter run
```

---

## Testes

```bash
# Todos os testes
flutter test

# Apenas unit tests
flutter test test/unit/

# Apenas widget tests
flutter test test/widget/

# Com cobertura
flutter test --coverage
```

**159 testes Flutter** (unit + widget) verdes.

### Testes das Security Rules (emulador)

Validam as regras do Firestore de forma reproduzível (não tocam produção):
```bash
cd firestore-tests
npm install      # primeira vez
npm test         # sobe o emulador, roda 26 casos e desliga
```
Requer Java 11+ (emulador) e Firebase CLI. Detalhes em `firestore-tests/README.md`.

---

## Qualidade

```bash
# Análise estática (deve retornar 0 issues)
flutter analyze
```

O projeto usa `very_good_analysis` com regras rigorosas. Todo PR deve manter `flutter analyze` em 0 issues.

---

## Funcionalidades

| Tela | Descrição | Status |
|---|---|---|
| Splash | Redirect automático por estado de auth | ✅ |
| Login | E-mail/senha + Google Sign-In | ✅ |
| Cadastro | Produtor ou veterinário | ✅ |
| Dashboard | KPIs reais (total, prenhas, alertas, vacinas) | ✅ |
| Rebanho | CRUD completo, filtros, busca live, modo seleção | ✅ |
| Ficha Animal | 4 tabs + evolução de peso/GMD + dar baixa | ✅ |
| Cadastro/Edição de Animal | Formulário reutilizável, RFID simulado, upsert | ✅ |
| Arquivados | Animais vendidos/óbito (histórico preservado) | ✅ |
| Vacinação | Formulário + cálculo de carência MAPA | ✅ |
| Brete IoT | Painel MQTT (aguarda hardware ESP32) | ⏸️ |
| Veterinários | Mapa OSM, filtros, botões de contato | ✅ |
| Baixa de rebanho | Venda/óbito, individual e em lote (batch atômico) | ✅ |
| Pesagens | Histórico + GMD por animal | ✅ |
| Chamados | Produtor abre; vet aceita (transação), evolui e conclui com laudo | ✅ |
| Dashboard do vet | Tabs e KPIs por papel (`tabsForRole`) | ✅ |
| Relatórios | Sanitário, reprodutivo, financeiro (+GMD), vendas, inventário | ✅ |
| Perfil | Editar dados, dark mode, LGPD, logout | ✅ |

---

## Segurança

- Autenticação real via Firebase Auth (sem dados sensíveis em SharedPreferences)
- Dados privados isolados por `uid` no Firestore (animais, vacinações, vendas, pesagens)
- **Security Rules por papel + schema** (`firestore.rules`): chamados compartilhados
  com leitura/escrita controladas (dono, vet atribuído, pool aberto); `delete` negado;
  cada escrita valida campos permitidos, tipos, tamanhos e enums; transições de status
  restritas (produtor só cancela em aberto; vet só evolui o próprio; encerrado é imutável)
- **`role` e `email` imutáveis** após o cadastro — fecha escalonamento de privilégio
  (produtor não vira veterinário para acessar chamados alheios); `role` só aceita
  `producer`/`vet`; subcoleções limitadas às conhecidas pelo app
- **51 testes automatizados de regras** (`firestore-tests/`) validam cada cenário de acesso
- Auth guard no router — rotas protegidas redirecionam para `/login`; **guarda por papel**
  (vet não abre telas do produtor e vice-versa)
- IDs de documentos gerados com `Random.secure` (20 chars, formato Firestore) — nunca
  `millisecondsSinceEpoch` (previsível e sujeito a colisão)
- Exclusão de conta (LGPD) apaga **todas** as subcoleções privadas e exige login recente
  antes de tocar nos dados (evita estado inconsistente); chamados ficam por auditoria
- Android: `allowBackup=false`; release assinado por `android/key.properties`
  (nunca versionado — ver `android/key.properties.example`)
- Logs de navegação do GoRouter apenas em debug
- `google-services.json` / `GoogleService-Info.plist` / `.env` / `key.properties` nunca
  commitados (`.gitignore`)

### Chaves de API do Firebase (`lib/firebase_options.dart`)

As chaves ali são **identificadores públicos do projeto** (vão dentro do APK de qualquer
forma) — a proteção real são as Security Rules. Ainda assim, no Google Cloud Console
(APIs & Services → Credentials) restrinja cada chave:

| Chave | Restrição recomendada |
|---|---|
| Android | Aplicativo Android: `br.com.bovicare.bovicare` + SHA-1 (debug e release) |
| iOS | Aplicativo iOS: bundle `br.com.bovicare.bovicare` |
| Web | Referenciadores HTTP: domínios do app |

Recomendado também ativar **Firebase App Check** (Play Integrity / App Attest) para
que só builds legítimos falem com Firestore/Auth.

### Mapa de veterinários

Usa `flutter_map` + tiles públicos do **OpenStreetMap** — **não** há Google Maps nem
chave de API. Requisitos atendidos no código: `User-Agent` identificando o app
(obrigatório pela política do OSM; sem ele o servidor responde 403 e o mapa fica cinza),
atribuição ODbL, permissão de localização no Android (`ACCESS_FINE/COARSE_LOCATION`)
e no iOS (`NSLocationWhenInUseUsageDescription`). Se o GPS estiver negado/desligado o
app usa Rio Claro, SP como referência e avisa na tela.

---

## Licença

Projeto acadêmico — TCC. Todos os direitos reservados ao autor.
