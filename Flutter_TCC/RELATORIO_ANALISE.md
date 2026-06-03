# Relatório de Análise e Checkup — BoviCare (Flutter_TCC)

> **Data:** 03/06/2026
> **Escopo:** pasta `Flutter_TCC/` (aplicativo migrado do protótipo web)
> **Objetivo:** stress test / análise estática completa, identificação de bugs, redundâncias e padronização.

---

## 1. Resumo executivo

O projeto está **bem arquitetado** (Clean Architecture + Riverpod + GoRouter + Freezed), com 110 arquivos Dart (~9.331 linhas, sem código gerado), 9 features e 64 testes. A organização em camadas (`domain` / `data` / `presentation`) é consistente e o design system (`core/constants` + `shared/widgets`) é maduro.

Porém, o checkup encontrou **2 falhas críticas** que quebram funcionalidades em produção, além de redundâncias e inconsistências que pedem padronização. A boa notícia: quase tudo é de correção barata.

| Severidade | Qtde | Impacto |
|------------|------|---------|
| 🔴 Crítico | 2 | Tela quebrada / provável erro de compilação |
| 🟠 Alto | 4 | Redundância de código, inconsistência de dados, peso de build |
| 🟡 Médio | 4 | Performance, stubs/mocks pendentes, arquitetura |
| 🔵 Baixo | 4 | Limpeza, documentação, cobertura de testes |

> ⚠️ **Limitação da análise:** o Flutter SDK não está disponível no PATH desta máquina, então **não foi possível rodar `flutter analyze` nem `flutter test`**. Toda a análise abaixo é estática (leitura de código). Os itens marcados com **[verificar]** devem ser confirmados rodando `flutter analyze` quando o SDK estiver disponível.

---

## 2. 🔴 Achados críticos

### C1 — O router usa STUBS em vez das telas reais (animal vs herd)

**A falha mais grave do projeto.** Existem **duas implementações** das mesmas telas, com **nomes de classe idênticos**:

| Classe | Stub ("Em desenvolvimento") | Implementação real |
|--------|------------------------------|--------------------|
| `AnimalProfileScreen` | `features/animal/.../animal_profile_screen.dart` — **18 linhas** | `features/herd/.../animal_profile_screen.dart` — **709 linhas** |
| `NewAnimalScreen` | `features/animal/.../new_animal_screen.dart` — **17 linhas** | `features/herd/.../new_animal_screen.dart` — **405 linhas** |

O `app_router.dart` importa as versões da pasta **`animal/`** (os stubs):

```dart
// lib/core/router/app_router.dart:8-9
import '../../features/animal/presentation/screens/animal_profile_screen.dart';
import '../../features/animal/presentation/screens/new_animal_screen.dart';
```

**Consequência:** ao abrir a ficha de um animal ou cadastrar um novo, o usuário vê apenas a tela *"Em desenvolvimento"*. As implementações completas (formulário com `save`, perfil com `animalDetailProvider`, ~1.100 linhas de código real) estão **órfãs / dead code** — não são importadas em lugar nenhum:

```
grep "herd/presentation/screens" → só herd_list_screen é importado.
```

**Correção (trivial, pois os nomes de classe são iguais):**
1. Trocar os 2 imports no router de `features/animal/...` → `features/herd/...`.
2. **Apagar a pasta inteira `lib/features/animal/`** (só contém os 2 stubs).

---

### C2 — `GenerateReportUseCase`: parâmetros nomeados privados + call-site divergente **[verificar]**

```dart
// lib/features/reports/domain/usecases/generate_report_use_case.dart:8-11
const GenerateReportUseCase({
  required this._animals,        // ❌ parâmetro nomeado não pode começar com "_"
  required this._vaccinations,   // ❌
});
```

Em Dart, **parâmetros nomeados não podem começar com underscore** — `required this._animals` é erro de compilação (*"Named parameters can't start with an underscore"*). Pior: o call-site usa nomes **diferentes** dos campos:

```dart
// lib/features/reports/presentation/providers/report_provider.dart:22-25
GenerateReportUseCase(
  animals:      ref.read(animalRepositoryProvider),   // 'animals' ≠ '_animals'
  vaccinations: ref.read(vaccinationRepositoryProvider),
);
```

Como `ReportsScreen` está na árvore de compilação do router, isso provavelmente **impede o build de todo o app**. É o único use case do projeto que usa esse padrão (todos os outros usam construtor posicional `const FooUseCase(this._repo)`).

**Correção:** padronizar para construtor posicional, igual aos demais:
```dart
const GenerateReportUseCase(this._animals, this._vaccinations);
// e no provider:
GenerateReportUseCase(
  ref.read(animalRepositoryProvider),
  ref.read(vaccinationRepositoryProvider),
);
```

---

## 3. 🟠 Redundâncias e inconsistências

### R1 — Mapeamento `AnimalStatus → label` duplicado **e divergente** (3+ lugares)

O mesmo `switch` sobre `AnimalStatus` está copiado em vários arquivos, com **textos inconsistentes**:

| Local | `healthy` | `attention` |
|-------|-----------|-------------|
| `animal_list_tile.dart:105` | `'Ativo'` | `'Vacina'` |
| `animal_profile_screen.dart:204` | `'Ativo'` | `'Alerta'` |
| `generate_report_use_case.dart:163` | `'Saudável'` | `'Alerta'` |

Além do label, o mapeamento `AnimalStatus → BadgeType` e `→ cores` também se repete entre `animal_list_tile` e `animal_profile_screen`.

**Correção:** centralizar numa extensão em `animal_entity.dart` (onde já vive `AnimalEntityX`), como fonte única de verdade:
```dart
extension AnimalStatusX on AnimalStatus {
  String get label => switch (this) {
    AnimalStatus.healthy   => 'Saudável',
    AnimalStatus.pregnant  => 'Prenha',
    AnimalStatus.attention => 'Alerta',
    AnimalStatus.sick      => 'Medicação',
  };
  BadgeType get badge => /* ... */;
}
```
Isso elimina ~4 cópias e remove a divergência de textos.

### R2 — Formatação de data reimplementada no use case de relatórios

`generate_report_use_case.dart:157` tem um `_fmt(DateTime)` manual (`padLeft`...) que **duplica** a extensão já existente `DateTimeX.toBrDate` (`core/extensions/datetime_ext.dart:6`). Trocar `_fmt(d)` por `d.toBrDate`.

### R3 — Hierarquia `Failure` quase inteira sem uso + tratamento de erro inconsistente

`core/errors/failures.dart` define 6 tipos de falha, mas **só `AuthFailure` é usado** (no `auth_firebase_data_source`). `ServerFailure`, `NetworkFailure`, `CacheFailure`, `ValidationFailure` e `UnknownFailure` são **código morto**.

Pior, a inconsistência de arquitetura: os repositórios de `herd`, `vaccination` e `dashboard` **não usam o padrão Failure** — deixam exceptions do Firestore vazarem cruas para a UI (ex.: `AnimalRepositoryImpl` não tem nenhum try/catch). Ou se adota o padrão em todos os repos, ou se remove o que não é usado. Recomendo **padronizar**: mapear erros do Firestore para `ServerFailure`/`NetworkFailure` nos data sources e tratar nos providers.

### R4 — Dependências declaradas e nunca importadas (peso de build)

`grep package:<pkg>` em `lib/` retornou **0 usos** para 7 pacotes do `pubspec.yaml`:

| Pacote | Usos | Observação |
|--------|------|------------|
| `mqtt_client` | 0 | Provavelmente reservado para o "Brete"/IoT (ainda stub) |
| `dio` | 0 | `cloud_firestore` cobre a rede; Dio sobra |
| `connectivity_plus` | 0 | — |
| `image_picker` | 0 | — |
| `permission_handler` | 0 | — |
| `flutter_svg` | 0 | — |
| `lottie` | 0 | `assets/animations/` declarado mas sem uso de Lottie |

**Correção:** remover do `pubspec.yaml` os que não têm roadmap imediato. Se `mqtt_client` for para a feature Brete planejada, deixar com um comentário `# usado na Fase X` — mas hoje só infla o `pubspec.lock` e o tempo de resolução.

---

## 4. 🟡 Pontos médios

### M1 — Busca/filtro do rebanho refaz fetch no Firestore a cada tecla

Em `animals_provider.dart:36-43`, o `build()` do `AnimalsNotifier` faz `ref.watch(herdSearchProvider)` e `ref.watch(herdFilterProvider)`. Como o `build` também chama `GetAnimalsUseCase(repo).call()` (busca no Firestore), **cada caractere digitado na busca invalida o provider e dispara um novo fetch** + estado de loading.

**Correção:** buscar a lista **uma vez** (provider sem watch de busca) e aplicar filtro/busca em memória num `Provider` derivado. O cache offline do Firestore atenua, mas o padrão atual gera rebuilds e flicker desnecessários.

### M2 — Stubs e mocks ainda no caminho de produção

- `brete_screen.dart` (17 linhas) — "Em desenvolvimento" (feature inteira é stub).
- `vaccination_screen.dart:34-35` — `_mockVets` hardcoded; comentário diz que "Fase 8 substituirá pela lista real do VetRepository", mas o `VetRepository` **já existe**. Conectar.
- `dashboard_firestore_data_source.dart:63` — bloco mock "mantido intencionalmente".
- `vet_in_memory_data_source.dart` — fonte de dados em memória (ok para TCC, mas documentar que não é Firestore).

Nada disso é bug, mas convém **mapear explicitamente** o que é mock proposital vs. pendência, para não ir para a banca como "pronto".

### M3 — Tratamento de erro/lo/sucesso não uniforme entre providers

`ReportNotifier` usa `AsyncValue.guard` (ótimo), `AnimalsNotifier` propaga exceptions. Padronizar o uso de `AsyncValue.guard` / `AsyncNotifier` em todos os notifiers que tocam I/O.

### M4 — `lib/firebase_options.dart` versionado

Está rastreado no git (`git ls-files`). Para Firebase isso é **tecnicamente aceitável** (a API key do cliente é restringida por Security Rules, não é segredo), mas vale: (a) garantir que as **Firestore Security Rules** estão fechadas, e (b) considerar restrição de API key por app no console. `.env` e `google-services.json` estão corretamente no `.gitignore`. ✅

---

## 5. 🔵 Limpeza e padronização (baixo impacto)

### B1 — `AppRoutes.shell` declarado e nunca usado
`app_routes.dart:10` define `shell` mas nenhuma rota o referencia. Remover.

### B2 — `analysis_options.yaml` desliga várias regras do `very_good_analysis`
Estão desativadas: `lines_longer_than_80_chars`, `public_member_api_docs`, `always_use_package_imports`, `directives_ordering`, `flutter_style_todos`, etc. Para um TCC é aceitável, mas `directives_ordering: false` + `always_use_package_imports: false` é o que permitiu o import errado do **C1** passar despercebido. Reativar ao menos `directives_ordering` ajuda a padronizar imports.

### B3 — Cobertura de testes com lacunas
64 testes, concentrados em `core` (extensions/validators) e alguns use cases/widgets. **Sem testes** para: providers (Riverpod), repositórios, feature `reports` (a do bug C2!), `vets` (cálculo de distância) e o router/redirect de auth. `widget_test.dart` tem só 1 teste (provavelmente o boilerplate). Priorizar teste para `GenerateReportUseCase` e para o redirect de auth.

### B4 — Documentação extensa e potencialmente redundante
Na pasta: `PLANO_DESENVOLVIMENTO_FLUTTER.md` (848 linhas) + `PLANO_FIREBASE.md` (542) + `README.md` (175), além de `DOCUMENTACAO.md` (root) e o app web original (`index.html`, `css/`, `js/`) no diretório pai. Os dois "PLANO_*" são docs de processo (úteis no histórico) — considerar movê-los para uma pasta `docs/` para deixar a raiz do app limpa, mantendo só o `README.md` como entrada.

---

## 6. ✅ Pontos fortes (o que está bom)

- **Clean Architecture** consistente: `domain` (entities/usecases/repositories) → `data` (models/datasources/repos) → `presentation` (providers/screens/widgets).
- **Design system** sólido: `core/constants` (cores, espaçamento, tipografia, sombras, raios, durações) + `shared/widgets` reutilizáveis (`AppButton`, `AppCard`, `AppBadge`, etc.).
- **Freezed + json_serializable** para entidades/models imutáveis.
- **Riverpod** com DI por providers e `AsyncNotifier`.
- **GoRouter** com redirect de auth reativo via `authStateChanges`.
- `main.dart` correto: persistência offline do Firestore, locale pt_BR, orientação travada.
- Boa separação de extensões utilitárias (`datetime_ext`, `string_ext`, `build_context_ext`).
- `.gitignore` cuidadoso com segredos (`.env`, `google-services.json`).

---

## 7. Plano de ação priorizado

| # | Ação | Sev. | Esforço | Resultado |
|---|------|------|---------|-----------|
| 1 | **C1** — Apontar router para `features/herd/` e apagar `features/animal/` | 🔴 | 5 min | Telas reais voltam a funcionar |
| 2 | **C2** — Corrigir construtor de `GenerateReportUseCase` (posicional) | 🔴 | 10 min | App volta a compilar; relatórios funcionam |
| 3 | **R1** — Centralizar `AnimalStatus → label/badge/cor` em extensão | 🟠 | 30 min | -4 cópias, fim da divergência de textos |
| 4 | **R4** — Remover deps não usadas do `pubspec.yaml` | 🟠 | 15 min | Build mais leve |
| 5 | **R3** — Padronizar tratamento de erro (Failure em todos os repos) | 🟠 | 1-2 h | Erros tratados na UI; sem dead code |
| 6 | **R2** — `_fmt` → `toBrDate` no use case de relatórios | 🟠 | 5 min | -1 duplicação |
| 7 | **M1** — Filtro/busca do rebanho em memória | 🟡 | 30 min | Sem refetch por tecla |
| 8 | **M2** — Conectar `vaccination_screen` ao `VetRepository` real | 🟡 | 30 min | Remove mock de produção |
| 9 | **B1/B2/B4** — Limpeza (rota shell, lint, mover docs) | 🔵 | 30 min | Padronização |
| 10 | **B3** — Testes para reports, auth redirect, providers | 🔵 | 2-3 h | Rede de segurança |

> **Recomendação:** começar pelos itens **1 e 2** imediatamente — são os únicos que afetam o app rodando, e juntos levam ~15 min. Depois rodar `flutter analyze` (quando o SDK estiver disponível) para confirmar o C2 e capturar warnings que esta análise estática não cobre.

---

*Relatório gerado por análise estática do código-fonte. Recomenda-se validação com `flutter analyze`, `flutter test` e `dart run build_runner build` após aplicar as correções.*
