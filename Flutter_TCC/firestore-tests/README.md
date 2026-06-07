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

## O que é coberto (26 casos)
- **Perfil:** dono lê/edita o próprio; não lê alheio; **`role` imutável**
  (impede auto-promoção a veterinário — escalonamento de privilégio).
- **Subcoleções** (animals/vaccinations/**sales**/**weighings**): dono
  escreve nas próprias; bloqueado em subcoleção de outro usuário.
- **Chamados (serviceCalls):** criação só do próprio, aberta e sem vet;
  leitura pelo dono/vet atribuído/pool aberto (vet); aceitar (open→accepted,
  sem corrida); evoluir só pelo vet atribuído; produtor cancela o próprio;
  `delete` sempre negado; dados de origem do produtor imutáveis.

> Um teste deste conjunto pegou uma falha real: o wildcard recursivo
> `match /{sub=**}` (no rules_version 2) casa **zero ou mais** segmentos e
> portanto também o doc de perfil, anulando a imutabilidade do `role`.
> Corrigido com wildcard de nível único `{collection}/{docId}`.
