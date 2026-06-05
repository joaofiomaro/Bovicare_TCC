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
│   ├── herd/       # Gestão do rebanho (CRUD Firestore)
│   ├── animal/     # Ficha do animal (4 tabs)
│   ├── vaccination/# Registros sanitários (Firestore)
│   ├── brete/      # Painel IoT ESP32 (placeholder)
│   ├── vets/       # Veterinários (in-memory)
│   ├── weighing/   # Pesagens e ganho de peso (GMD)
│   ├── service_call/# Chamados produtor↔vet (coleção compartilhada)
│   ├── reports/    # Relatórios por tipo e período
│   └── profile/    # Perfil + LGPD + configurações
└── shared/
    └── widgets/    # Design system (AppButton, AppCard, AppTextField…)
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
- Publique as Security Rules (arquivo `firestore.rules` na raiz)
- Registre o SHA-1 do debug keystore: `cd android && ./gradlew signingReport`

**4. Crie o `.env`**
```bash
cp .env.example .env
# Edite conforme necessário (MQTT_BROKER_URL, etc.)
```

**5. Deploy dos índices Firestore**
```bash
firebase deploy --only firestore:indexes --project SEU_PROJETO_ID
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
| Rebanho | CRUD completo, filtros, busca live | ✅ |
| Ficha Animal | 4 tabs: resumo, sanitário, reprodução, histórico | ✅ |
| Novo Animal | Formulário com RFID simulado | ✅ |
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
- Dados isolados por `uid` no Firestore
- Security Rules bloqueiam acesso cruzado entre usuários
- `google-services.json` nunca commitado (`.gitignore`)
- Auth guard no router — rotas protegidas redirecionam para `/login`

---

## Licença

Projeto acadêmico — TCC. Todos os direitos reservados ao autor.
