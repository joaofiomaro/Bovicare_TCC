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

### 3.8 Critérios de aceite
- [ ] Botão "Editar" na ficha abre o form pré-preenchido.
- [ ] Salvar atualiza Firestore (mesmo `id`, `updatedAt` renovado) e a ficha reflete na hora.
- [ ] `flutter analyze` 0 issues.

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

### 4.9 Critérios de aceite
- [ ] Baixa individual (venda e óbito) funcionando na ficha.
- [ ] Modo seleção + baixa em lote (venda e óbito) na lista.
- [ ] Animais com baixa somem do rebanho ativo e das contagens do dashboard.
- [ ] Venda gravada atomicamente (doc de venda + updates) e visível em "Arquivados"/relatório.
- [ ] `flutter analyze` 0 issues · testes verdes.

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

### 5.6 Critérios de aceite
- [ ] Ação "Pesar" registra pesagem e atualiza peso atual.
- [ ] Histórico de pesagens visível na ficha.
- [ ] GMD calculado corretamente.

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

### 6.9 Critérios de aceite
- [ ] Login como vet abre dashboard/tabs distintos do produtor.
- [ ] Produtor abre chamado; vet vê no pool, aceita, evolui status e conclui com laudo.
- [ ] Produtor acompanha status e cancela enquanto aberto.
- [ ] Regras de segurança publicadas **e versionadas** impedem acesso indevido.
- [ ] `flutter analyze` 0 issues · testes verdes.

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

### 7.6 Critérios de aceite
- [ ] Relatório de vendas com totais corretos do lote.
- [ ] Ganho de peso por cabeça exibido quando há pesagens.
- [ ] `flutter analyze` 0 issues · testes verdes.

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
- [ ] **M1 — Editar animal**: form reutilizável, rota, botão na ficha, invalidação de providers, widget test.
- [ ] **M2 — Baixa de rebanho**: `exitType` no modelo, vendas (coleção + batch atômico), óbitos, baixa individual + lote (modo seleção), aba arquivados, use cases + testes.
- [ ] **M3 — Pesagens**: coleção `weighings`, ação "Pesar", histórico/GMD, use cases + testes.
- [ ] **M4 — Vet + Chamados**: coleção `serviceCalls`, shell/dashboard por papel, fluxo abrir→aceitar→concluir, regras de segurança versionadas, testes.
- [ ] **M5 — Relatórios**: relatório de vendas + ganho de peso, totais, `NumX.toBrl`, testes.
- [ ] **Transversal**: `firestore.rules` versionado e publicado, índices deployados, migração de `exitType` tratada.

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

---

*Plano elaborado seguindo a arquitetura e os padrões já consolidados no BoviCare. Cada módulo é independente o suficiente para ser implementado, testado e auditado isoladamente, com commit próprio.*
