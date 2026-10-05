# Relatório de Auditoria — APIs, Funcionalidades e Segurança (15/09/2026)

> **Escopo:** app Flutter (`Flutter_TCC/`), regras/índices do Firestore, configs
> nativas Android/iOS/web e o protótipo web da raiz (`index.html`, `js/`, `css/`).
> **Método:** leitura integral do código + `flutter analyze` + `flutter test`
> + revisão das Security Rules com testes de emulador.

---

## 1. Resumo executivo

O projeto **não usa a API do Google Maps** em lugar nenhum: o mapa de veterinários é
`flutter_map` com tiles do **OpenStreetMap**, sem chave. O que fazia o mapa falhar era
um conjunto de omissões em volta dele (User-Agent obrigatório do OSM, permissão de
localização no iOS, `.env` obrigatório no build, emulador sem GPS). Tudo foi corrigido
sem introduzir dependência do Google.

Na segurança, a base já era boa (Firebase Auth, isolamento por `uid`, `role` imutável,
26 testes de regras). Os pontos endurecidos: **validação de schema nas regras**, transições
de status dos chamados, guarda por papel no router, exclusão de conta completa (LGPD),
IDs não previsíveis, assinatura de release e `allowBackup=false`.

| Área | Achados | Corrigidos |
|---|---|---|
| Mapa / localização | 8 | 8 |
| Security Rules (Firestore) | 6 | 6 (+25 testes novos) |
| Auth / conta | 7 | 7 |
| Funcionalidades (bugs) | 6 | 6 |
| Configuração nativa (Android/iOS/web) | 6 | 6 |
| Protótipo web (raiz) | 1 | 1 |

---

## 2. Mapa e localização (prioridade do pedido)

| # | Problema | Correção |
|---|---|---|
| M1 | `TileLayer` sem `userAgentPackageName` — a política do OSM exige User-Agent identificando o app; sem ele o servidor responde **403** e o mapa fica cinza | `userAgentPackageName: 'br.com.bovicare.bovicare'` em `vets_map.dart` |
| M2 | Sem atribuição ODbL (obrigatória pela licença do OSM) | `RichAttributionWidget` com link para o copyright |
| M3 | iOS sem `NSLocationWhenInUseUsageDescription` — o sistema **encerra o app** ao pedir permissão | Chave adicionada ao `Info.plist` |
| M4 | `.env` vazio/ausente: `dotenv.load()` lançava `FileNotFoundError` na inicialização | `dotenv.load(isOptional: true)`; `run.ps1` cria o `.env` a partir do exemplo |
| M5 | `MAPS_TILE_URL` aceitava qualquer string (inclusive `http://`) | `VetsMap.resolveTileUrl` só aceita `https://` com `{z}{x}{y}`; senão usa o padrão |
| M6 | Localização: sem checar serviço desligado, sem última posição conhecida, fallback silencioso (usuário via Rio Claro sem saber por quê) | `LocationService` devolve `UserLocation` com origem (gps / lastKnown / fallback); a tela avisa quando está no fallback e o pull-to-refresh relê o GPS |
| M7 | Enquadramento inicial fixo no usuário: no emulador (posição padrão nos EUA) os vets ficavam fora da tela | `CameraFit.coordinates` com usuário + vets; se o usuário está a >300 km de todos, enquadra só os vets |
| M8 | Provider de vets usava `ref.read` da localização — não recalculava distâncias ao atualizar | `ref.watch(userLocationProvider.future)` |

Também: `<queries>` (tel/mailto/https/whatsapp) no Android e `LSApplicationQueriesSchemes`
no iOS para os botões de contato do veterinário; `CFBundleURLTypes` do Google Sign-In no iOS.

---

## 3. Security Rules (Firestore)

| # | Problema | Correção |
|---|---|---|
| R1 | Perfil aceitava qualquer `role` (ex.: `admin`) e campos arbitrários | `validProfile`: `role ∈ {producer, vet}`, chaves restritas, `name` obrigatório (≤120), `email` string |
| R2 | `email` do perfil era editável (é o identificador de login) | Imutável no `update` |
| R3 | Qualquer subcoleção sob `users/{uid}` era gravável | Limitada a `animals / vaccinations / sales / weighings` |
| R4 | Chamados sem validação de schema (tamanhos, enums, campos extras) | `validCall`: chaves restritas, limites de tamanho, `urgency`/`status` em enum, UF com 2 letras, `lat/lng` numéricos |
| R5 | Produtor podia editar título/descrição junto com o cancelamento; vet podia alterar conteúdo ao aceitar; vet atribuído podia mudar **qualquer** campo (inclusive reabrir concluído) | `affectedKeys().hasOnly(...)` por transição; encerrados imutáveis; concluir exige `resolution` |
| R6 | Acesso a `resource.data.vetId` sem checar existência | `isAssignedVet()` com `'vetId' in resource.data` |

Testes: 26 → **51 casos** em `firestore-tests/`. Rodar com `npm test` (exige Java 11+).

---

## 4. Auth e conta

| # | Problema | Correção |
|---|---|---|
| A1 | `deleteAccount` apagava só `animals` e `vaccinations` — `sales` e `weighings` ficavam órfãos (LGPD) | Apaga as 4 subcoleções |
| A2 | `user.delete()` exige login recente; a checagem vinha **depois** de apagar os dados → conta viva sem perfil | Verifica `lastSignInTime` (≤5 min) **antes**; erro amigável pedindo re-login |
| A3 | Erro na exclusão/edição de perfil não era tratado na UI (exceção não capturada) | Notifier devolve resultado; tela exibe toast |
| A4 | `farmName` não podia ser apagado (campo omitido no update mantinha o antigo) | `FieldValue.delete()` quando nulo; update só de campos editáveis |
| A5 | Cadastro: se a gravação do perfil falhasse, ficava conta órfã no Auth sem `role` | Desfaz o `createUser` e devolve `ServerFailure` |
| A6 | Logout falhava inteiro se o `GoogleSignIn.signOut` lançasse | Google sign-out é melhor-esforço |
| A7 | Texto "30 dias de carência" na exclusão (não existe carência); mensagens brutas de exceção na tela de cadastro; login exigia 8+ chars (Firebase aceita 6) | Textos corrigidos; só `Failure.message` chega à UI; login exige apenas senha preenchida |

Router: `debugLogDiagnostics` só em debug; **guarda por papel** (`authRedirect` recebe
`role`): vet não abre rebanho/brete/vets/relatórios/chamados do produtor; produtor não
abre pool/agenda do vet. +6 testes unitários.

---

## 5. Bugs funcionais

| # | Problema | Correção |
|---|---|---|
| F1 | Dashboard: `pregnantCount / totalAnimals` com 0 animais → `NaN.round()` **lança** e a tela quebra | Guarda de divisão por zero |
| F2 | KPI "Efetivo total" mostrava tendência fixa "+3 este mês" (dado inventado) | Removido |
| F3 | "Atividade recente" era um **mock fixo** (parto da Mimosa etc.) apresentado como dado real | Derivado das últimas vacinações, pesagens e vendas do usuário |
| F4 | Rebanho demo era semeado sempre que a coleção estava vazia: quem removia/dava baixa em todos os animais via 7 fictícios reaparecerem; vets também recebiam | Semeia **uma vez** por produtor (`users/{uid}.demoSeededAt`) |
| F5 | IDs de animal/venda/vacina/pesagem/chamado = `millisecondsSinceEpoch` (previsível e colidia em lote) | `generateId()` — 20 chars aleatórios (`Random.secure`), formato Firestore |
| F6 | Chamado aceitava UF vazia/qualquer texto (regras agora exigem 2 letras) | Validação no formulário |

---

## 6. Configuração nativa

- **Android:** `allowBackup="false"`; `<queries>` para url_launcher; assinatura de release
  via `key.properties` (com aviso quando ausente) — `key.properties.example` adicionado.
- **iOS:** permissão de localização, esquemas de URL (contato + Google Sign-In),
  orientação restrita a retrato (coerente com `main.dart`).
- **Web:** título/descrição/manifest com o nome real do app.

## 7. Protótipo web (raiz)

- `toast.js` montava a mensagem via `innerHTML` → trocado por `textContent` (sem XSS
  caso a mensagem venha de dados externos no futuro). Sem outras APIs ou segredos.

---

## 8. O que NÃO foi alterado (decisões e pendências)

- **Chaves em `lib/firebase_options.dart`:** são identificadores públicos; a proteção
  real são as regras. Ação manual recomendada: restringir cada chave no Google Cloud
  Console (Android por pacote+SHA-1, iOS por bundle, Web por referenciador) e ativar
  **App Check**. Ver README → Segurança.
- **Login com Google cria sempre `producer`** (papel imutável): veterinários devem
  usar o cadastro por e-mail. Um fluxo de escolha de papel pós-OAuth fica como melhoria.
- **Chamados são preservados na exclusão de conta** (regras proíbem `delete`) — auditoria.
- **Listas de chamados não são em tempo real** (`FutureProvider`); trocar por
  `StreamProvider` com `snapshots()` é a evolução natural.
- **Card "Sincronização" do perfil** é decorativo (Firestore sincroniza sozinho).
- **`.env` continua asset obrigatório no build** (limitação do `flutter_dotenv`); o
  `run.ps1` cria o arquivo automaticamente e ele não deve conter segredos.

## 9. Verificação

| Verificação | Resultado |
|---|---|
| `flutter analyze` | ver seção final do commit/PR |
| `flutter test` | ver seção final do commit/PR |
| Testes das regras (emulador) | ver seção final do commit/PR |
| Build Android | **não verificável nesta máquina** (`google-services.json` ausente — está no `.gitignore`); validar com `flutter build apk` após `flutterfire configure` |
