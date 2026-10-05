# Testes das Firestore Security Rules

Testes automatizados das regras de segurança (`../firestore.rules`) rodando
contra o **emulador do Firestore**, com `@firebase/rules-unit-testing` e o
runner nativo do Node (`node --test`).

## Pré-requisitos
- Node.js 18+ e npm
- Java 11+ (o emulador do Firestore é uma aplicação Java)
- Firebase CLI no PATH (`npm i -g firebase-tools`)

## Como rodar
```bash
cd firestore-tests
npm install      # primeira vez
npm test         # sobe o emulador, roda os testes e desliga
```
O script usa `firebase emulators:exec --only firestore` apontando para o
`../firebase.json`, então não toca em nenhum dado de produção.

## O que é coberto (51 casos)
- **Perfil:** dono lê/edita o próprio; não lê alheio; cria só com schema
  válido (`role` ∈ producer/vet, sem campos extras, nome obrigatório);
  **`role` e `email` imutáveis** (impede auto-promoção a veterinário —
  escalonamento de privilégio); `demoSeededAt` gravável pelo dono.
- **Subcoleções** (animals/vaccinations/**sales**/**weighings**): dono
  escreve nas próprias; bloqueado em subcoleção de outro usuário e em
  subcoleções desconhecidas pelo app.
- **Chamados (serviceCalls):** criação só do próprio, aberta, sem vet e sem
  campos de conclusão; schema validado (urgência/UF/título/campos extras);
  leitura pelo dono/vet atribuído/pool aberto (vet); aceitar (open→accepted,
  sem corrida, sem alterar conteúdo, sem se passar por outro vet); evoluir só
  pelo vet atribuído (agendar, concluir com laudo obrigatório); encerrado é
  imutável; produtor cancela só em aberto e só o status; produtor não se
  auto-atribui como vet; `delete` sempre negado.

> Um teste deste conjunto pegou uma falha real: o wildcard recursivo
> `match /{sub=**}` (no rules_version 2) casa **zero ou mais** segmentos e
> portanto também o doc de perfil, anulando a imutabilidade do `role`.
> Corrigido com wildcard de nível único `{collection}/{docId}`.
