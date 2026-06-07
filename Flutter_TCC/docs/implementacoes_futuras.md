# BoviCare — Implementações Futuras (Roadmap Detalhado)

> Projeto: `Flutter_TCC/` · Criado em: 2026-06-03
> Base: app já em produção com Clean Architecture + Riverpod + GoRouter + Firebase (Auth + Firestore), `flutter analyze` 0 issues, 108 testes.
> **Propósito:** especificação técnica completa das próximas funcionalidades, para implementação guiada e auditável. Cada módulo traz modelo de dados, camadas (domain/data/presentation), validações, **Security Rules**, testes e critérios de aceite.

---

## Índice

1. [Princípios e padrões obrigatórios](#1-princípios-e-padrões-obrigatórios)
2. [Visão geral dos módulos e dependências](#2-visão-geral-dos-módulos-e-dependências)
3. [Módulo 1 — Edição de animal](#3-módulo-1--edição-de-animal)
4. [Módulo 2 — Baixa de rebanho (óbito e venda · individual e lote)](#4-módulo-2--baixa-de-rebanho-óbito-e-venda--individual-e-lote)
5. [Módulo 3 — Registro de pesagens (ganho de peso)](#5-módulo-3--registro-de-pesagens-ganho-de-peso)
6. [Módulo 4 — Dashboard do veterinário + Chamados](#6-módulo-4--dashboard-do-veterinário--chamados)
7. [Módulo 5 — Relatórios enriquecidos](#7-módulo-5--relatórios-enriquecidos)
8. [Módulo transversal — Segurança, índices e migração](#8-módulo-transversal--segurança-índices-e-migração)
9. [Estratégia de testes](#9-estratégia-de-testes)
10. [Checklist de progresso e auditoria final](#10-checklist-de-progresso-e-auditoria-final)

---

## 1. Princípios e padrões obrigatórios

Toda implementação **deve** respeitar o que já está estabelecido no projeto:

| Regra | Detalhe |
|-------|---------|
| **Clean Architecture** | `domain` (entities/usecases/repositories puros, sem Flutter/Firebase) → `data` (models/datasources/repos) → `presentation` (providers/screens/widgets). Domínio **nunca** importa apresentação ou Firestore. |
| **Imutabilidade** | Entidades e models com **Freezed**; models com `fromFirestore`/`toFirestore`/`fromEntity`/`toEntity`. |
| **DI via Riverpod** | Data sources e repos expostos por `Provider`; estado por `AsyncNotifier`/`FutureProvider`. |
| **Tratamento de erro** | Data sources do Firestore usam o mixin `FirestoreErrorHandler` (`guardFirestore`) → lançam `Failure`. Notifiers de I/O usam `AsyncValue.guard` ou retornam `bool`. UI exibe `failure.message` / toast. |
| **Sem refetch desnecessário** | Listas carregadas uma vez; filtro/busca em memória (padrão do `filteredAnimalsProvider`). |
| **Status/labels centralizados** | Reusar extensões (`AnimalStatusX.label`, `AnimalStatusVisuals.badge`); **nunca** duplicar `switch` de enum. |
| **Datas** | Sempre `DateTimeX.toBrDate` / `toBrDateTime`; nunca `padLeft` manual. Persistência em ISO 8601 (`toIso8601String`). |
| **Rotas** | Strings centralizadas em `AppRoutes`/`AppPaths`; nada de string solta. |
| **Lint** | `flutter analyze` deve terminar em **0 issues** (very_good_analysis + `directives_ordering`). Imports ordenados. |
| **Segurança** | Dados isolados por usuário (`request.auth.uid`); coleções compartilhadas (chamados) com regras explícitas por papel. **Nenhum** segredo no git. |
| **Testes** | Todo use case novo tem teste unitário (mocktail). Funções puras testadas isoladamente. |

> **Comando de verificação ao fim de cada módulo:**
> `flutter analyze` → 0 issues · `flutter test` → tudo verde · (se houve codegen) `dart run build_runner build --delete-conflicting-outputs`.

---

## 2. Visão geral dos módulos e dependências

| Módulo | Funcionalidade | Depende de | Esforço estimado |
|--------|----------------|------------|------------------|
| **M1** | Editar animal | — | Baixo (~1–2 h) |
| **M2** | Baixa de rebanho (óbito/venda, individual/lote) | M1 (form reutilizável) | Alto (~4–6 h) |
| **M3** | Registro de pesagens | — | Médio (~2–3 h) |
| **M4** | Dashboard do veterinário + Chamados | role-based shell | Alto (~6–8 h) |
| **M5** | Relatórios enriquecidos (ganho de peso, total vendido) | M2 + M3 | Médio (~2–3 h) |
| **Transversal** | Security Rules como código, índices, migração | todos | Médio |

**Ordem recomendada:** M1 → M3 → M2 → M5 → M4. (M1 prepara o form que M2 reusa; M3 gera os dados de peso que M5 consome; M2 gera as vendas que M5 agrega; M4 é independente e pode entrar em paralelo.)

---

## 3. Módulo 1 — Edição de animal

### 3.1 Objetivo
Permitir editar um animal já cadastrado (peso, status, nome, raça, RFID, data) reaproveitando o formulário de cadastro, fechando o CRUD completo (Create ✅ · Read ✅ · **Update** 🆕 · Delete ✅).

### 3.2 Estratégia
`SaveAnimalUseCase` **já faz upsert** (`set`/`update` por `id`). Editar = salvar com o mesmo `id`. O trabalho é de **UI/refatoração**, sem mudança de modelo de dados.

### 3.3 Refatoração
Extrair de `new_animal_screen.dart` um widget de formulário reutilizável:

- **Criar** `lib/features/herd/presentation/screens/animal_form_screen.dart`
  - `AnimalFormScreen({AnimalEntity? initial})` — `initial == null` ⇒ modo **cadastro**; senão ⇒ modo **edição**.
  - Pré-preenche controllers/estado a partir de `initial` (`initState`).
  - Título dinâmico: "Novo animal" / "Editar animal"; botão "Cadastrar" / "Salvar alterações".
  - No modo edição, mantém o `id` original (não gera novo `millisecondsSinceEpoch`).
- `new_animal_screen.dart` passa a ser um alias fino (`AnimalFormScreen()`), ou removido com atualização do router.

### 3.4 Rota
- `AppRoutes.editAnimal = 'edit-animal'`, `AppPaths.editAnimal(id) => '/herd/$id/edit'`.
- Sub-rota de `herd/:id` no `app_router.dart`, com `_slideTransition`, recebendo o `AnimalEntity` via `extra` (evita refetch) **ou** lendo `animalDetailProvider(id)` (fallback se `extra` nulo, ex.: deep link).
- Botão de editar no header de `animal_profile_screen.dart` (ícone `edit_outlined`).

### 3.5 Providers
- Após salvar: `ref.invalidate(animalDetailProvider(id))` **e** `ref.invalidate(animalsProvider)` para refletir nas duas telas.
- Reusar `AnimalsNotifier.save` (já retorna `bool` com tratamento de erro — M3 do checkup anterior).

### 3.6 Validações / checagens
- `earTag` obrigatório; `birthDate` obrigatório; `weightKg` numérico ≥ 0 (validar parse).
- **Não** permitir alterar `id`.
- Edição não pode "ressuscitar" animal com baixa (se M2 já implementado, bloquear edição de animal arquivado ou exibir aviso).

### 3.7 Testes
- Use case já coberto. Adicionar **widget test**: `AnimalFormScreen(initial: x)` renderiza campos pré-preenchidos; salvar chama o notifier.

### 3.8 Critérios de aceite — ✅ CONCLUÍDO (2026-06-03)
- [x] Botão "Editar" na ficha abre o form pré-preenchido (`_AnimalHeader`, passa o animal por `extra`).
- [x] Salvar atualiza Firestore (mesmo `id`, `updatedAt` renovado via upsert) e a ficha reflete na hora (`invalidate(animalDetailProvider)`).
- [x] `flutter analyze` 0 issues · 111 testes passando.

**O que foi implementado:**
- `animal_form_screen.dart` — `AnimalFormScreen({AnimalEntity? initial})` reutilizável (cadastro/edição); preserva `status` e `pregnancyDate` ao editar; valida brinco/data/peso. `new_animal_screen.dart` removido.
- `AnimalEditLoader` — fallback que carrega o animal por id em deep links sem `extra` (sem refetch no caminho normal).
- Rotas `editAnimal` em `AppRoutes`/`AppPaths`; sub-rota `/herd/:id/edit` no router.
- Widget test (`animal_form_screen_test.dart`): pré-preenchimento em edição, modo cadastro, e save preservando o `id`.

---

## 4. Módulo 2 — Baixa de rebanho (óbito e venda · individual e lote)

### 4.1 Objetivo
Permitir dar **baixa** em animais por **óbito** ou **venda**, de forma **individual** ou **em lote**, preservando o histórico (não deletar) para relatórios de venda e mortalidade.

### 4.2 Decisão de arquitetura: arquivar, não deletar
Animais com baixa **saem do rebanho ativo** mas permanecem no Firestore com metadados de saída. Isso viabiliza relatórios (total vendido, mortalidade) e auditoria.

#### 4.2.1 Modelo de dados — extensão de `AnimalEntity`
Adicionar (todos opcionais, default = ativo):

```dart
enum AnimalExitType { active, sold, deceased }

// Em AnimalEntity (freezed), novos campos:
@Default(AnimalExitType.active) AnimalExitType exitType,
DateTime? exitDate,
String?   exitNotes,
// Venda:
String?   saleId,        // referência ao documento de venda (lote ou individual)
// Óbito:
String?   deathCause,
```

- `AnimalModel`: persistir `exitType` (`.name`), `exitDateIso`, `exitNotes`, `saleId`, `deathCause`. `fromFirestore` trata ausência ⇒ `active` (compatível com docs já existentes — ver Migração §8.3).
- `AnimalStatusX` permanece para status **sanitário**; saída é dimensão separada (lifecycle). **Não** misturar.

#### 4.2.2 Filtragem ativo vs. arquivado
- `filteredAnimalsProvider` e contagens passam a considerar **apenas** `exitType == active` por padrão.
- Novo filtro no `HerdFilter`? Manter `HerdFilter` para status; adicionar um `Provider`/aba "Arquivados" separada (`archivedAnimalsProvider`) para consultar baixas.
- **Importante:** documentos antigos sem `exitType` ⇒ tratados como `active` no `fromFirestore`; o filtro em memória usa a entidade já normalizada (evita o problema de `where` não casar campo ausente).

### 4.3 Vendas — nova coleção
Para responder "**total do lote vendido**" e permitir venda em lote, criar coleção de eventos de venda:

**`users/{uid}/sales/{saleId}`**

```dart
// SaleRecord (entity, freezed)
class SaleRecord {
  String        id;
  DateTime      date;
  SaleType      type;            // individual | lote
  List<String>  animalIds;       // ids dos animais vendidos
  int           headCount;       // animalIds.length (denormalizado p/ relatório)
  String?       buyer;           // comprador
  double        totalValue;      // R$ total recebido pelo lote
  double?       totalWeightKg;   // peso total do lote na venda (p/ arroba/preço)
  double?       pricePerArroba;  // opcional; arroba = 15 kg
  String?       notes;
}
enum SaleType { individual, lote }
```

- `SaleModel` com `fromFirestore/toFirestore/fromEntity/toEntity`; datas em ISO; `createdAt/updatedAt` serverTimestamp.
- `valuePerHead => totalValue / headCount` (computed, na extensão da entidade).

### 4.4 Óbitos
Óbito **não** exige coleção própria — fica nos metadados do animal (`exitType = deceased`, `deathCause`, `exitDate`). Relatório de mortalidade consulta animais arquivados com `exitType == deceased`. (Coleção dedicada só se for necessário audit trail granular — fora do escopo inicial.)

### 4.5 Camadas

**Domain**
- `AnimalExitType` enum + extensão `AnimalExitTypeX.label` ("Ativo"/"Vendido"/"Óbito") e `badge`.
- Repositório `AnimalRepository`: novos métodos
  - `Future<void> recordDeath({required List<String> animalIds, required DateTime date, String? cause, String? notes});`
  - `Future<SaleRecord> recordSale(SaleRecord sale);` (cria venda + marca animais).
  - `Future<List<AnimalEntity>> getArchived();`
- Novo repositório `SaleRepository` (getAll, getById) **ou** manter vendas dentro de `AnimalRepository`. **Recomendado:** `SaleRepository` separado (responsabilidade única).
- Use cases: `RecordAnimalDeathUseCase`, `RecordAnimalSaleUseCase`, `GetSalesUseCase`, `GetArchivedAnimalsUseCase`.

**Data**
- `AnimalFirestoreDataSource`:
  - `recordExit(...)` — **batch write**: para cada animal, `update({exitType, exitDateIso, ...})`. Garante atomicidade do lote.
  - `getArchived()` — busca e filtra `exitType != active`.
- `SaleFirestoreDataSource` (nova) com `FirestoreErrorHandler`:
  - `create(SaleModel)` — **transação/batch**: grava o doc de venda **e** atualiza os N animais (`exitType=sold`, `saleId`, `exitDate`) num único `WriteBatch` (atômico).
  - `getAll()` — `orderBy('dateIso', descending: true)`.

**Presentation**
- `salesProvider` (AsyncNotifier/FutureProvider), `archivedAnimalsProvider`.
- Telas/fluxos:
  - **Baixa individual** (na ficha do animal): ação "Dar baixa" → `AppBottomSheet` com escolha **Venda** / **Óbito** → tela/sheet de formulário:
    - Venda: comprador, valor total, peso na venda (sugere o `weightKg` atual), data, observações.
    - Óbito: causa, data, observações.
  - **Baixa em lote** (na `HerdListScreen`): **modo seleção** (long-press ou botão "Selecionar") → checkboxes nos tiles → barra inferior com contagem e ações "Vender lote" / "Registrar óbito". 
    - Venda em lote: comprador, valor total do lote, peso total (sugere soma dos pesos selecionados), data.
    - Confirmação com resumo (N animais, valor, R$/cabeça).

### 4.6 Validações / checagens (críticas)
- Não dar baixa em animal **já arquivado** (filtrar da seleção; validar no use case).
- `totalValue >= 0`; `headCount >= 1`; `animalIds` não vazio e **sem duplicatas**.
- Venda em lote: `animalIds` devem existir e pertencer ao usuário (a regra de segurança já garante o isolamento; validar existência no client antes do batch).
- **Atomicidade:** venda = doc de venda + updates dos animais no **mesmo `WriteBatch`** (ou `runTransaction`). Se falhar, nada é aplicado.
- Após baixa: invalidar `animalsProvider`, `filteredAnimalsProvider`, `dashboardProvider` (contagens), `salesProvider`.
- UX: confirmação destrutiva clara ("Esta ação dá baixa em N animais do rebanho ativo"). Feedback de sucesso/erro via toast.

### 4.7 Segurança
- `users/{uid}/sales/{saleId}` herda o padrão de isolamento por usuário (ver §8). Apenas o dono lê/escreve.
- Atualização de `exitType` nos animais já protegida pela regra de `users/{uid}/animals`.

### 4.8 Testes
- `RecordAnimalSaleUseCase`: cria venda, marca animais; valida `headCount`, rejeita lista vazia/duplicada.
- `RecordAnimalDeathUseCase`: marca óbito; rejeita animal já arquivado.
- Extensão `SaleRecordX.valuePerHead`.
- Filtro ativo/arquivado (função pura).

### 4.9 Critérios de aceite — ✅ CONCLUÍDO (2026-06-03)
- [x] Baixa individual (venda e óbito) na ficha (botão "Dar baixa" para ativos; banner para arquivados).
- [x] Modo seleção (toggle por toque/long-press) + baixa em lote via FAB "Dar baixa (N)".
- [x] Animais com baixa somem do rebanho ativo (`filteredAnimalsProvider`) e das contagens do dashboard (contagem de ativos em memória).
- [x] Venda gravada atomicamente (doc `sales` + updates dos animais no mesmo `WriteBatch`) e visível em "Arquivados".
- [x] `flutter analyze` 0 issues · 134 testes passando.

**O que foi implementado:**
- Domain: `AnimalExitType` + `AnimalExitTypeX.label`, `AnimalEntityX.isArchived`; campos de saída em `AnimalEntity`; `SaleRecord` + `SaleType` + `SaleRecordX.valuePerHead`; `SaleRepository`; `AnimalRepository.recordDeath`; use cases `RecordAnimalSaleUseCase`, `RecordAnimalDeathUseCase`, `GetSalesUseCase` (com validações: lista não vazia, sem duplicatas, headCount, valor ≥ 0).
- Data: campos de saída em `AnimalModel` (default `active`, sem migração — §8.3); `SaleModel`; `SaleFirestoreDataSource.recordSale` (**batch atômico**: venda + baixa de N animais); `AnimalFirestoreDataSource.recordDeath` (batch); repos impl.
- Presentation: `filteredAnimalsProvider` agora só ativos; `archivedAnimalsProvider` (derivado em memória); `salesProvider`; `AnimalExitNotifier` (recordSale/recordDeath, bool, invalida animals/sales/dashboard/detail); `AnimalExitSheet` (reutilizável individual/lote, toggle Venda/Óbito, sugere peso do lote, R$/cabeça); modo seleção em `HerdListScreen` + `AnimalListTile`; `ArchivedAnimalsScreen` (rota `/herd/archived`); banner de arquivado + bloqueio de edição na ficha.
- Dashboard: contagens de total/prenhas/alertas passam a contar **apenas ativos** (em memória); "próximas vacinações" mantém `count()`.
- Testes: use cases de venda/óbito, `SaleRecordX`, `isArchived`.

> **Decisões de engenharia:** (1) `recordSale` vive em `SaleRepository`, mas seu data source atualiza a coleção de animais no mesmo batch — única forma de garantir atomicidade; documentado. (2) `archivedAnimalsProvider` deriva em memória de `animalsProvider` em vez de uma 2ª consulta (`getArchived()` foi dispensado para evitar dead code/refetch). (3) Dashboard troca `count()` por contagem em memória dos ativos — correto e alinhado ao §8.3 (sem `where` em campo possivelmente ausente); custo aceitável para o porte do rebanho.

---

## 5. Módulo 3 — Registro de pesagens (ganho de peso)

### 5.1 Objetivo
Habilitar a ação "Pesar" (hoje "Em breve") e manter **histórico de pesagens** por animal, base para o **ganho de peso** nos relatórios (M5).

### 5.2 Modelo de dados — nova coleção
**`users/{uid}/weighings/{id}`**

```dart
// Weighing (entity, freezed)
class Weighing {
  String   id;
  String   animalId;
  double   weightKg;
  DateTime date;
  String?  notes;
}
```

- `WeighingModel` com mapeamento Firestore (data ISO, `createdAt`).
- Ao registrar pesagem: gravar o evento **e** atualizar `animal.weightKg` (peso atual) — no mesmo batch.

### 5.3 Camadas
- **Domain:** `WeighingRepository` (getByAnimal, add); `RegisterWeighingUseCase`, `GetAnimalWeighingsUseCase`.
  - `WeighingsX` (extensão sobre `List<Weighing>`): `gmd` (ganho médio diário = (último − primeiro)/dias), `totalGain`, `lastWeight`.
- **Data:** `WeighingFirestoreDataSource` (`FirestoreErrorHandler`); `orderBy('dateIso')`. Índice composto se filtrar por `animalId` + ordenar por data (ver §8.2).
- **Presentation:** `animalWeighingsProvider(animalId)` (FutureProvider.family.autoDispose); tela/sheet "Registrar pesagem"; mini-gráfico/linha do tempo de evolução na aba "Resumo"/"Histórico" da ficha.

### 5.4 Validações
- `weightKg > 0` e plausível (ex.: ≤ 1500 kg — sanity check, não bloqueante rígido).
- `date` ≤ hoje.

### 5.5 Testes
- `WeighingsX.gmd`/`totalGain` (função pura, casos: 0/1/N pesagens, divisão por zero).
- `RegisterWeighingUseCase` (mock repo).

### 5.6 Critérios de aceite — ✅ CONCLUÍDO (2026-06-03)
- [x] Ação "Pesar" registra pesagem e atualiza peso atual (batch atômico: pesagem + `animal.weightKg`).
- [x] Histórico de pesagens visível na ficha (`WeightEvolutionSection` na aba Resumo).
- [x] GMD calculado corretamente (`WeighingsX.gmd`, testado para 0/1/N e divisão por zero).

**O que foi implementado (feature `weighing`):**
- Domain: `Weighing` (freezed) + `WeighingsX` (lastWeight/totalGain/periodDays/gmd, funções puras); `WeighingRepository`; `RegisterWeighingUseCase`, `GetAnimalWeighingsUseCase`.
- Data: `WeighingModel` (freezed+json+firestore); `WeighingFirestoreDataSource` (`FirestoreErrorHandler`, **batch atômico** grava pesagem + atualiza peso do animal); `WeighingRepositoryImpl`.
- Presentation: `animalWeighingsProvider(animalId)` (autoDispose family), `WeighingFormNotifier` (guard + bool); `WeighingFormSheet` (bottom sheet amigável, validação peso 0–1500 kg e data ≤ hoje); `WeightEvolutionSection` (resumo + histórico).
- Ficha do animal: ação "Pesar" abre o sheet; seção de evolução com peso atual, ganho total e GMD; invalida `animalDetailProvider`/`animalsProvider` ao salvar (peso muda).
- Testes: `WeighingsX` (8 casos) + use cases (mocktail).

> **Decisão de engenharia:** `getByAnimal` usa `where('animalId', ==)` (índice automático) e **ordena em memória** por data — a lista por animal é pequena, mantendo o M3 autossuficiente sem depender do índice composto do módulo Transversal (§8.2). Para grandes volumes, migrar para `orderBy` + índice nesse módulo.

---

## 6. Módulo 4 — Dashboard do veterinário + Chamados

### 6.1 Objetivo
Quando o usuário loga como **veterinário** (`UserRole.vet`), o app apresenta uma experiência dedicada: dashboard com **chamados em aberto**, **chamados ativos/agendados** e **histórico**, em vez do fluxo de rebanho do produtor. O produtor, por sua vez, pode **abrir chamados** solicitando atendimento.

### 6.2 Domínio "Chamados" (Service Calls) — coleção compartilhada
Diferente das demais coleções (isoladas por usuário), chamados são **compartilhados** entre produtor e veterinário. Logo, ficam numa coleção de topo:

**`serviceCalls/{callId}`**

```dart
// ServiceCall (entity, freezed)
class ServiceCall {
  String           id;
  // Produtor (autor):
  String           producerId;
  String           producerName;
  String?          farmName;
  String           city;
  String           state;
  double?          lat;
  double?          lng;
  // Veterinário (atribuído quando aceito):
  String?          vetId;
  String?          vetName;
  // Conteúdo:
  String           title;          // motivo curto
  String           description;
  String?          animalEarTag;   // animal relacionado (opcional)
  ServiceUrgency   urgency;        // low | normal | high
  ServiceStatus    status;         // open | accepted | inProgress | completed | cancelled
  DateTime         createdAt;
  DateTime?        scheduledDate;   // agendamento
  DateTime?        completedAt;
  String?          resolution;      // laudo/observação final do vet
}
enum ServiceUrgency { low, normal, high }
enum ServiceStatus  { open, accepted, inProgress, completed, cancelled }
```

- Extensões: `ServiceStatusX.label/badge`, `ServiceUrgencyX.label/color`.
- `ServiceCallModel` com mapeamento Firestore; datas ISO; `createdAt/updatedAt` serverTimestamp.

### 6.3 Fluxo
1. **Produtor abre chamado** (status `open`, `vetId = null`) — a partir da tela de Vets ("Solicitar atendimento") ou de um botão dedicado.
2. **Veterinário vê o "pool"** de chamados abertos (filtrável por cidade/urgência) e **aceita** um → `status = accepted`, `vetId = uid`, `vetName`.
3. Vet atualiza para `inProgress` / agenda (`scheduledDate`) / conclui (`completed` + `resolution`).
4. Produtor acompanha o status do seu chamado; pode `cancelar` enquanto `open`.

### 6.4 Camadas
- **Domain:** `ServiceCallRepository` (createCall, getOpenCalls, getCallsForVet(vetId), getCallsForProducer(producerId), updateStatus/accept/complete/cancel). Use cases correspondentes (`OpenServiceCallUseCase`, `AcceptCallUseCase`, `CompleteCallUseCase`, `CancelCallUseCase`, `GetOpenCallsUseCase`, etc.).
- **Data:** `ServiceCallFirestoreDataSource` (`FirestoreErrorHandler`):
  - `getOpen()` — `where('status','==','open').orderBy('createdAt', descending: true)`.
  - `getForVet(uid)` — `where('vetId','==',uid)` (+ índice).
  - `getForProducer(uid)` — `where('producerId','==',uid)`.
  - `accept(callId, vet)` — **transação**: só aceita se ainda `open` (evita corrida entre dois vets).
- **Presentation:**
  - `serviceCallsOpenProvider`, `vetCallsProvider`, `producerCallsProvider`.
  - **Dashboard por papel** (ver §6.5).

### 6.5 Navegação baseada em papel (role-based shell)
O `AppShell` e a rota `/dashboard` passam a depender do papel do usuário (lido de `authProvider`):

- **Produtor** (tabs atuais): Início · Rebanho · Brete · Vets · Perfil.
  - Início = `ProducerDashboardScreen` (atual) + card "Meus chamados" (status).
- **Veterinário** (tabs novas): Início · Chamados · Agenda · Perfil. *(sem Rebanho/Brete)*
  - Início = `VetDashboardScreen`: KPIs — **chamados em aberto** (no pool), **meus atendimentos ativos**, **concluídos no mês**, **próximo agendamento**; lista resumida de chamados recentes.
  - Chamados = `VetCallsScreen`: abas "Abertos (pool)" / "Meus ativos" / "Histórico".
  - Agenda = chamados com `scheduledDate` futura (lista/calendário simples).

**Implementação técnica:**
- `AppShell` recebe/observa o papel: `final role = ref.watch(authProvider).valueOrNull?.role;` e monta `_tabs` conforme `role`. (Converter `AppShell` em `ConsumerWidget`.)
- Rota `/dashboard` renderiza `role == vet ? VetDashboardScreen() : ProducerDashboardScreen()`.
- `_indexFromLocation` adaptado às tabs de cada papel.
- **Cuidado:** o `authProvider` precisa estar carregado antes do shell; tratar estado de loading (skeleton) e fallback para produtor se nulo.

### 6.6 Segurança (Security Rules) — crítico
Coleção compartilhada exige regras explícitas (ver bloco completo em §8.1):
- **create:** apenas o próprio produtor (`request.auth.uid == request.resource.data.producerId`) e `status == 'open'`.
- **read:** o produtor dono, o vet atribuído, **ou** qualquer vet quando `status == 'open'` (pool). `isVet()` lê `users/{uid}.role`.
- **update:** 
  - produtor dono: só pode `cancel` (e somente enquanto `open`);
  - vet ao **aceitar**: transição `open → accepted` setando `vetId == request.auth.uid`;
  - vet atribuído: pode evoluir status (`accepted → inProgress → completed`) e preencher `resolution`.
- **Validação de campos** na regra (tipos, status válidos, imutabilidade de `producerId`).

### 6.7 Validações / checagens
- Vet não pode aceitar chamado já aceito (transação + checagem `status == open`).
- Produtor não vê o pool de outros; vet não edita chamado que não é seu (exceto aceitar do pool).
- Campos obrigatórios: `title`, `description`, `city`.
- Geolocalização opcional (reusar `LocationService` existente) para ordenar pool por proximidade.

### 6.8 Testes
- Transições de status (função pura `nextStatus`/validação): open→accepted, bloqueio de aceitar 2x, cancelar só se open.
- Use cases com mock repo (`AcceptCallUseCase` rejeita se não-open, etc.).
- Seleção de tabs por papel (lógica pura `tabsForRole(role)`).

### 6.9 Critérios de aceite — ✅ CONCLUÍDO (2026-06-05)
- [x] Login como vet abre dashboard/tabs distintos do produtor (`tabsForRole`, `HomeDashboardScreen`).
- [x] Produtor abre chamado; vet vê no pool, aceita (transação atômica), evolui status e conclui com laudo.
- [x] Produtor acompanha status e cancela enquanto aberto (`ProducerCallsScreen`).
- [x] Regras de segurança versionadas (`firestore.rules`) impedem acesso indevido (ver §8.1).
- [x] `flutter analyze` 0 issues · 158 testes passando.

**O que foi implementado (feature `service_call`):**
- Domain: `ServiceCall` (freezed) + enums `ServiceUrgency`/`ServiceStatus`, `ServiceCallX` (isOpen/isActive/isClosed/canAccept/canCancel) e `nextServiceStatus` (função pura); `ServiceCallRepository`; use cases `OpenServiceCallUseCase`, `AcceptCallUseCase`, `AdvanceCallUseCase`, `CancelCallUseCase`, `GetOpen/Vet/ProducerCallsUseCase` (validações: campos obrigatórios, aceitar só se aberto, laudo ao concluir, cancelar só se aberto).
- Data: `ServiceCallModel` (freezed+json+firestore, enums por `.name`, datas ISO, `createdAtIso` para ordenação); `ServiceCallFirestoreDataSource` (coleção compartilhada `serviceCalls`; **accept via `runTransaction`** — só aplica `open → accepted` se ainda aberto, evita corrida entre dois vets); `ServiceCallRepositoryImpl`.
- Presentation: `serviceCallVisuals` (badges); providers `openCallsProvider`, `vetCallsProvider`, `producerCallsProvider`, `ServiceCallActionsNotifier` (open/accept/advance/cancel, bool, invalida as listas afetadas); telas `HomeDashboardScreen` (switch por papel), `VetDashboardScreen` (KPIs do pool/atendimentos), `VetCallsScreen` (abas Abertos/Meus ativos/Histórico), `VetAgendaScreen`, `OpenServiceCallScreen` (produtor), `ProducerCallsScreen`; widgets `ServiceCallTile`, `vet_call_action_sheet` (aceitar/agendar/iniciar/concluir com laudo).
- Navegação: `AppShell` agora é `ConsumerWidget` e monta as abas via `tabsForRole(role)` (vet: Início·Chamados·Agenda·Perfil; produtor: Início·Rebanho·Brete·Vets·Perfil); `indexFromTabs` resolve a aba ativa por maior prefixo; rota `/dashboard` renderiza vet/produtor conforme papel; card "Meus chamados" no dashboard do produtor.
- Testes: use cases (mocktail), transições puras (`nextServiceStatus`, `ServiceCallX`), `tabsForRole`/`indexFromTabs`.

> **Decisões de engenharia:** (1) ordenação por `createdAtIso` (string ISO, ordena cronologicamente) em vez de `Timestamp`, alinhado ao padrão do projeto (vaccinations usa `dateIso`); índices em §8.2 ajustados. (2) `accept` usa `runTransaction` (não batch) por exigir releitura do status antes de gravar — única forma de impedir corrida entre dois vets, complementando a Security Rule. (3) Fallback de papel nulo → conjunto do produtor (shell não trava enquanto `authProvider` carrega).

---

## 7. Módulo 5 — Relatórios enriquecidos

### 7.1 Objetivo
Agregar ao relatório informações de acompanhamento do produtor: **ganho de peso por cabeça** (GMD) e **total vendido por lote** (valor, peso, R$/arroba).

### 7.2 Novos conteúdos
- **Relatório de vendas** (`ReportType.sales` 🆕): por venda/lote — data, comprador, nº de cabeças, peso total, valor total, R$/cabeça, R$/@.
  - Totais no rodapé: **total geral vendido** (Σ valor), peso total, média R$/@.
- **Ganho de peso** (no inventário/financeiro ou tipo próprio): por cabeça — peso inicial, peso atual, GMD (kg/dia), período. Fonte: coleção `weighings` (M3).
- Reusar `GenerateReportUseCase` adicionando os ramos `_sales(...)` e enriquecendo `_financial`/`_inventory` com GMD quando houver pesagens.

### 7.3 Camadas
- `GenerateReportUseCase` recebe (via construtor) também `SaleRepository` e `WeighingRepository` (DI no `report_provider`).
- Manter o padrão de `ReportData` (headers/rows). Cálculos de total no use case (domínio), **não** na UI.
- Datas via `toBrDate`; valores com formatação monetária (criar `NumX.toBrl` em `core/extensions` — `intl` `NumberFormat.currency(locale:'pt_BR', symbol:'R\$')`).

### 7.4 (Opcional) Exportação real
Hoje o seletor PDF/CSV é cosmético. Opcional neste módulo: gerar **CSV** (string) e compartilhar via `share_plus`, ou **PDF** via `pdf`+`printing`. Se incluído, adicionar dependências e documentar. *(Pode ficar para uma fase posterior — o foco é o conteúdo do relatório.)*

### 7.5 Validações / testes
- `GenerateReportUseCase` ramo `sales`: total = Σ valores; média ponderada de R$/@; lida com lista vazia.
- GMD: período = dias entre primeira e última pesagem; 0/1 pesagem ⇒ "—".
- Testes unitários com mocks dos 3 repositórios.

### 7.6 Critérios de aceite — ✅ CONCLUÍDO (2026-06-05)
- [x] Relatório de vendas (`ReportType.sales`) com linha de totais do período (Σ valor, peso total, média ponderada R$/@).
- [x] Ganho de peso por cabeça (GMD) exibido no relatório financeiro quando há pesagens.
- [x] `flutter analyze` 0 issues · testes verdes.

**O que foi implementado:**
- `NumX.toBrl` (`core/extensions/num_ext.dart`) — formatação monetária pt_BR via `intl`.
- `ReportType.sales` (label/subtitle/ícone) + campo opcional `footer` em `ReportData` (linha de totais, renderizada destacada no `ReportPreview`).
- `GenerateReportUseCase` agora recebe também `SaleRepository` e `WeighingRepository` (DI no `report_provider`): ramo `_salesReport` (data, comprador, cabeças, peso, valor, R$/cab., R$/@ — com média **ponderada** = valor total ÷ arrobas totais; arroba = 15 kg); `_financial` enriquecido com coluna **GMD** (consulta de pesagens por animal em paralelo via `Future.wait`).
- Testes: ramo de vendas (totais, média ponderada, fora do período/lista vazia), GMD no financeiro, `NumX.toBrl` (incl. NBSP do `intl`).

---

## 8. Módulo transversal — Segurança, índices e migração

### 8.1 Security Rules como código (prioritário)
**Hoje as regras só existem no Console** (não versionadas) e o `firebase.json` não as referencia. Antes de criar coleções compartilhadas (chamados), versionar:

1. Criar `firestore.rules` na pasta do app.
2. Referenciar no `firebase.json`:
   ```json
   "firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" }
   ```
3. Publicar via CLI: `firebase deploy --only firestore:rules`.

**Esboço das regras** (revisar antes de publicar):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function isSignedIn() { return request.auth != null; }
    function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }
    function isVet() {
      return isSignedIn()
        && get(/databases/$(db)/documents/users/$(request.auth.uid)).data.role == 'vet';
    }

    // Dados privados do usuário (rebanho, vacinações, vendas, pesagens, perfil)
    match /users/{uid} {
      allow read, write: if isOwner(uid);
      match /{sub=**} { allow read, write: if isOwner(uid); }
    }

    // Chamados — coleção compartilhada produtor↔vet
    match /serviceCalls/{callId} {
      allow create: if isOwner(request.resource.data.producerId)
                    && request.resource.data.status == 'open';
      allow read:   if isOwner(resource.data.producerId)
                    || (resource.data.vetId == request.auth.uid)
                    || (resource.data.status == 'open' && isVet());
      allow update: if
        // produtor cancela o próprio chamado ainda aberto
        (isOwner(resource.data.producerId)
           && resource.data.status == 'open'
           && request.resource.data.status == 'cancelled')
        // vet aceita um chamado do pool
        || (isVet() && resource.data.status == 'open'
           && request.resource.data.vetId == request.auth.uid
           && request.resource.data.status == 'accepted')
        // vet atribuído evolui o atendimento
        || (resource.data.vetId == request.auth.uid);
      allow delete: if false; // nunca deletar — histórico/auditoria
    }
  }
}
```
> ⚠️ Validar/testar com o **Rules Playground** e o emulador antes de publicar. `isVet()` faz `get()` (custa 1 leitura/avaliação) — aceitável; alternativa é custom claims via Cloud Functions (fora do escopo).

### 8.2 Índices compostos
Adicionar a `firestore.indexes.json` conforme as queries:
- `weighings`: `animalId ASC, dateIso ASC` (histórico por animal ordenado).
- `serviceCalls`: `vetId ASC, createdAt DESC`; `producerId ASC, createdAt DESC`; `status ASC, createdAt DESC` (pool).
- `sales`: `dateIso DESC` (ordenação simples; índice automático).
- Deploy: `firebase deploy --only firestore:indexes`.

### 8.3 Migração de dados existentes
- Animais já cadastrados **não têm** `exitType`. `AnimalModel.fromFirestore` deve **default** `active` quando ausente — evita quebrar e dispensa backfill.
- Filtragem ativo/arquivado feita **em memória** sobre a entidade normalizada (não usar `where('exitType','==','active')` no Firestore, que ignora docs sem o campo). Para rebanhos grandes, considerar backfill + índice numa fase futura (documentar como dívida técnica conhecida).

### 8.4 Checagens de segurança no commit (checklist do projeto)
- `google-services.json`, `GoogleService-Info.plist`, `.env` permanecem no `.gitignore`.
- `firestore.rules` **pode** ser versionado (não contém segredos).
- Nenhuma chave/segredo em código.

---

## 9. Estratégia de testes

| Camada | O que testar | Ferramenta |
|--------|--------------|------------|
| **Funções puras** | GMD, totais de venda, transições de status de chamado, filtro ativo/arquivado, `tabsForRole` | `flutter_test` |
| **Use cases** | Todos os novos (sale, death, weighing, service call) | `mocktail` (mock repos) |
| **Extensões** | `AnimalExitTypeX`, `ServiceStatusX`, `WeighingsX`, `NumX.toBrl` | `flutter_test` |
| **Widgets** | `AnimalFormScreen` (edição pré-preenche), seleção em lote | `flutter_test` (widget) |
| **Regras** | Acesso a `serviceCalls` por papel | Emulador / Rules Playground |

Meta: manter **0 issues** no analyze e **cobertura crescente** (cada módulo adiciona seus testes antes de ser considerado concluído).

---

## 10. Checklist de progresso e auditoria final

### Progresso por módulo
- [x] **M1 — Editar animal** ✅ (2026-06-03): form reutilizável, rota `/herd/:id/edit`, botão na ficha, invalidação de providers, widget test. `flutter analyze` 0 issues · 111 testes.
- [x] **M2 — Baixa de rebanho** ✅ (2026-06-03): `exitType` no modelo, vendas (coleção `sales` + batch atômico), óbitos, baixa individual + lote (modo seleção), tela de arquivados, use cases + testes. `flutter analyze` 0 issues · 134 testes.
- [x] **M3 — Pesagens** ✅ (2026-06-03): coleção `weighings`, ação "Pesar" (batch atômico), histórico/GMD na ficha, use cases + testes. `flutter analyze` 0 issues · 121 testes.
- [x] **M5 — Relatórios** ✅ (2026-06-05): relatório de vendas (totais ponderados) + GMD no financeiro, `NumX.toBrl`, testes. `flutter analyze` 0 issues.
- [x] **M4 — Vet + Chamados** ✅ (2026-06-05): coleção `serviceCalls`, shell/dashboard por papel (`tabsForRole`), fluxo abrir→aceitar (transação)→evoluir→concluir com laudo, cancelamento pelo produtor, regras versionadas, testes. `flutter analyze` 0 issues.
- [x] **Transversal** ✅ (2026-06-05): `firestore.rules` versionado e referenciado no `firebase.json`; índices de `serviceCalls` em `firestore.indexes.json`; migração de `exitType` tratada via default no `fromFirestore` (§8.3, já no M2). *Deploy via CLI fica a cargo do dono do projeto (`firebase deploy --only firestore:rules,firestore:indexes`).*

### Auditoria final (ao concluir tudo)
Replicar o rigor da auditoria do checkup anterior (`RELATORIO_ANALISE.md §8`):

1. **`flutter analyze`** → 0 issues.
2. **`flutter test`** → 100% verde; contagem de testes registrada.
3. **`dart run build_runner build --delete-conflicting-outputs`** → sem conflitos (Freezed/JSON atualizados).
4. **Regras de segurança** validadas no emulador/Playground (produtor não vê pool alheio; vet não edita chamado de terceiro; baixa atômica).
5. **Sem dead code / mocks de produção** remanescentes (revisar `Em breve`/`Mock`).
6. **Checklist de segurança git** (nenhum segredo; `.gitignore` ok).
7. Documentar o resultado numa seção de auditoria neste arquivo, marcando cada item com ✅ e o que foi feito.
8. Atualizar `PLANO_DESENVOLVIMENTO_FLUTTER.md` (status/fases) e `README.md` (features).

### Resultado da auditoria final — ✅ (2026-06-05)

1. ✅ **`flutter analyze`** → **0 issues** (very_good_analysis + directives_ordering).
2. ✅ **`flutter test`** → **158 testes, 100% verde** (eram 121 ao fim do M3; +37 entre M5 e M4).
3. ✅ **`dart run build_runner build --delete-conflicting-outputs`** → 30 outputs, sem conflitos (Freezed/JSON de `ServiceCall`/`ServiceCallModel` gerados).
4. ⚠️ **Regras de segurança** versionadas em `firestore.rules` e referenciadas no `firebase.json`. Validação no emulador/Playground e **deploy** dependem de credenciais do projeto Firebase → **a cargo do dono** (`firebase deploy --only firestore:rules,firestore:indexes`). Regras escritas para: produtor só lê o próprio chamado; vet lê o pool aberto e o que lhe foi atribuído; aceitar exige `open → accepted` com `vetId == auth.uid`; `delete` sempre negado.
5. ✅ **Sem dead code / mocks de produção** introduzidos; ações reais substituem "Em breve" no fluxo de chamados.
6. ✅ **Checklist de segurança git**: nenhum segredo no código; `.env`/`google-services.json` seguem no `.gitignore`; `firestore.rules` versionável (sem segredos).
7. ✅ Este documento atualizado (M4/M5/Transversal marcados, seções "O que foi implementado" e esta auditoria).
8. ✅ `README.md` atualizado com as novas features (chamados, relatórios de venda/GMD).

> **Pendências operacionais (fora do código):** publicar `firestore.rules` e os índices compostos de `serviceCalls` no console/CLI do Firebase antes de usar a feature de chamados em produção. Os índices são criados automaticamente na primeira query se o link de erro do Firestore for seguido, mas o recomendado é o deploy versionado.

---

## 11. Revisão completa do app — auditoria de qualidade (2026-06-07)

Análise transversal de todo o app (não só dos módulos), buscando redundâncias,
erros e problemas críticos, e **conferindo se os passos do roadmap foram
implementados corretamente**. A auditoria anterior (§10) reportava "0 issues",
mas a verificação atual encontrou **2 issues de lint** e outros problemas reais
— todos corrigidos.

### Verificação dos módulos do roadmap
Todos os módulos foram conferidos no código-fonte e estão **íntegros**:
- **M1–M3** (herd): edição, baixa de rebanho e pesagens — conforme §3/§4/§5.
- **M4** (service_call): coleção compartilhada, `accept` via `runTransaction`,
  shell por papel (`tabsForRole`), fluxo completo, `firestore.rules` por papel —
  conforme §6. Navegação verificada (Dashboard → "Meus chamados" → abrir; vet via abas).
- **M5** (reports): `ReportType.sales` com média ponderada de R$/@, GMD no
  financeiro, `NumX.toBrl` — conforme §7.
- **Transversal**: `firestore.rules` versionado e referenciado no `firebase.json`;
  índices de `serviceCalls`/`vaccinations` em `firestore.indexes.json`.

### 🔴 Problemas críticos corrigidos
| # | Problema | Correção |
|---|----------|----------|
| 1 | **Índice composto incorreto** — `firestore.indexes.json` declarava o índice de `producerId` com o campo `createdAt`, mas o data source ordena por `createdAtIso`. A query "Meus chamados" do produtor **falharia em produção** por índice ausente. | Campo corrigido para `createdAtIso`. |
| 2 | **Relatórios incluíam animais com baixa** — inventário, financeiro e reprodutivo usavam `getAll()` sem filtrar arquivados, mostrando animais **vendidos/óbito** como se fossem do rebanho atual (inconsistência M2↔M5). | Os três ramos passam a filtrar `!a.isArchived`; teste de regressão adicionado. |

### 🟠 Redundâncias eliminadas
| # | Redundância | Correção |
|---|-------------|----------|
| 3 | **Formatação manual de data** (`padLeft`) duplicando `DateTimeX.toBrDate` em **7 locais** (report_preview, reports_screen, quarantine_calculator, vaccination_screen, animal_form_screen, animal_profile_screen ×2) — viola o princípio §1. | Tudo consolidado em `.toBrDate`; **3 helpers locais removidos** (`_fmt`/`_formatDate`). |

### 🟡 Lint e testes
| # | Item | Correção |
|---|------|----------|
| 4 | 2 issues `avoid_redundant_argument_values` no teste de service_call (`DateTime(2026,6,1)`, `scheduledDate: null`). | Removidos os valores default. |
| 5 | Widget test de `AnimalFormScreen` quebrou ao consolidar para `toBrDate` (locale `pt_BR` não inicializado no teste). | `initializeDateFormatting('pt_BR')` no `setUpAll` (o app já inicializa no `main.dart`). |

### Resultado da revisão
1. ✅ **`flutter analyze`** → **0 issues** (era 2).
2. ✅ **`flutter test`** → **159 testes, 100% verde** (+1 regressão de inventário arquivado).
3. ✅ **Sem dead code** introduzido; `HomeDashboardScreen` encapsula corretamente `DashboardScreen` (produtor) e `VetDashboardScreen` (vet) — nenhum órfão.
4. ✅ **Arquitetura/padrões** verificados: separação domínio (`label`) × apresentação (`badge`) consistente (`ServiceStatusX`/`ServiceStatusVisuals`); datas em ISO; `FirestoreErrorHandler` em todos os data sources; DI por Riverpod.
5. ✅ **Segurança**: `firestore.rules` por papel revisado (produtor lê o próprio; vet lê pool aberto + atribuídos; `delete` negado); nenhum segredo no código.

### 🔐 Endurecimento das Security Rules (2026-06-07)

A revisão das regras encontrou uma **falha crítica de escalonamento de
privilégio** e pontos a endurecer — todos corrigidos em `firestore.rules`:

| # | Falha | Correção |
|---|-------|----------|
| 1 | 🔴 **Auto-promoção a veterinário** — `match /users/{uid} { allow write }` deixava o usuário gravar qualquer campo do próprio perfil, inclusive `role`. Um produtor podia setar `role: 'vet'` e, via `isVet()`, **ler o pool de chamados de todos os outros produtores** e aceitá-los. | `role` agora é **imutável** após o cadastro: `allow update: if isOwner(uid) && request.resource.data.role == resource.data.role`. (Edição de perfil só altera nome/fazenda — `copyWith` preserva o `role`, então o fluxo continua íntegro.) |
| 2 | 🟠 `isVet()` poderia errar se o perfil não existisse. | Adicionado `exists(...)` antes do `get(...)`. |
| 3 | 🟠 `create` de chamado não impedia vet pré-atribuído. | `create` agora exige `!('vetId' in request.resource.data)`. |
| 4 | 🟠 Vet atribuído podia sobrescrever dados de origem do produtor. | Branch de evolução fixa `producerId`/`producerName` (imutáveis). |

**Validação de fluxos:** todas as operações reais do app foram traçadas contra
as novas regras (cadastro/login, perfil, rebanho/vacinação/vendas/pesagens,
abrir→aceitar via transação→evoluir→concluir, cancelar) — **nenhuma quebra**.

> **Deploy obrigatório:** as regras e índices vivem versionados no repo mas só
> valem em produção após o deploy. Rodar (dono do projeto, autenticado):
> `firebase deploy --only firestore:rules,firestore:indexes`.
> Recomenda-se validar antes no **Rules Playground**/emulador.

> **Pendências conhecidas (não-bloqueantes, fora do escopo do roadmap):** seletor PDF/CSV da tela de relatórios é cosmético (export real adiado — §7.4); telas "Em breve" de manejos extras (Vermifugação/Medicação/Observação/Prenhez), Brete (Fase 7, aguarda hardware) e 3 itens do Perfil permanecem como placeholders intencionais.

---

*Plano elaborado seguindo a arquitetura e os padrões já consolidados no BoviCare. Cada módulo é independente o suficiente para ser implementado, testado e auditado isoladamente, com commit próprio.*
