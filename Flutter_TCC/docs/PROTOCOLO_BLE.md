# Protocolo BLE do Brete (ESP32 ↔ BoviCare)

Contrato entre o firmware `BoviCare_Brete_Final` v1.3.0 (ESP32-D0WD-V3) e o app. No app, o
protocolo está em `lib/features/brete/domain/brete_ble_protocol.dart` (funções
puras, com testes) e a conexão em `lib/features/brete/data/ble_brete_gateway.dart`.

## Escolha do meio no app

`.env` → `BRETE_CONEXAO`:

| Valor | Comportamento |
|---|---|
| `ble` (padrão) | Bluetooth LE no Android/iOS. Na web e no desktop cai na simulação |
| `mqtt` | Broker MQTT (`docs/BRETE_MQTT_PROTOCOLO.md`), se `MQTT_BROKER_URL` for válido |
| `simulacao` | Modo demonstração, sem hardware |

## GATT

| Item | Valor |
|---|---|
| Nome anunciado | `BoviCare-Brete` (vem na resposta do scan, não no anúncio principal) |
| Serviço | `b0c1ca5e-0001-4b8e-9d3a-6f2e1c7a9d10` (anunciado; o app filtra o scan por ele) |
| Comando | `…0002…`: escrita / escrita sem resposta (texto ASCII, máx. 64 caracteres, sem quebra de linha) |
| Estado | `…0003…`: leitura + notificação (JSON) |
| Evento | `…0004…`: notificação (JSON) |
| MTU | 247 (pedido pelo app no Android; o iOS negocia sozinho) |

Fluxo do app, nesta ordem:

1. scan de 8 s filtrando pelo UUID do serviço; conecta no de sinal mais forte
   (`autoConnect: false`, timeout de 10 s);
2. Android: `requestMtu(247)` logo após conectar (sem isso as notificações
   chegam cortadas em 20 bytes). No iOS não é chamado;
3. `discoverServices()` e localização das 3 características;
4. notificações ligadas em EVENTO e em ESTADO;
5. leitura única do ESTADO para preencher a tela;
6. `#id STATUS` para confirmar que o firmware responde. Só então os botões
   são liberados;
7. ao desconectar, a tela mostra "Reconectar" (a ESP32 volta a anunciar
   sozinha ~0,5 s depois).

Permissões: o `flutter_blue_plus` pede `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`
(Android 12+) ou localização (Android ≤ 11) em tempo de execução. Se o
Bluetooth estiver desligado, o app pede para ligar (`turnOn()`, só Android).

## Comandos (characteristic de comando)

Texto, com um `#id` (1..65535) que volta na resposta. O app sempre envia o id
e espera o `RESP` correspondente por até 3 s; passado esse tempo, mostra
"Sem resposta do brete". Porta 1 = entrada, porta 2 = saída.

| App | Texto enviado | Observação |
|---|---|---|
| Abrir porta | `#5 ABRIR 1` / `#5 ABRIR 2` | 1 = entrada, 2 = saída |
| Fechar porta | `#6 FECHAR 1` | Recusado se o IR da porta estiver obstruído |
| Parar porta | `#7 PARAR 1` | Botão "Parar" aparece com a porta em movimento |
| Parada de emergência | `#8 EMERGENCIA` | |
| Rearmar | `#9 RESET` | Recusado se o botão físico de parada continuar apertado |
| Confirmar conexão | `#10 STATUS` | Enviado logo após conectar |

O firmware também aceita `ALTERNAR 1|2`, `PARAR` (as duas portas) e `PING`,
que o app hoje não usa. `JOG`, `TEMPO`, `SEGURAR` etc. são só pela serial:
pelo BLE voltam `NAO_PERMITIDO`.

## Estado (characteristic de estado)

Enviado a cada mudança e a cada 2 s:

```json
{"p1":"FECHADA","p2":"ABERTA","f1":"","f2":"","ir":"01","fa":"00","ff":"00",
 "em":0,"bot":"000","rfid":"","rok":0,"up":42}
```

| Campo | Uso no app |
|---|---|
| `p1`, `p2` | Porta de entrada/saída. `FECHADA`, `ABERTA`, `PARADA`. `ABRINDO`, `FECHANDO`, `RECUANDO` e `AJUSTE` aparecem como "Em movimento" |
| `ir` | IR da porta 1 e da porta 2 (`1` = obstruído) |
| `bot` | Botão 1, botão 2 e botão de parada (`1` = apertado) |
| `em` | `1` = emergência: o app bloqueia Abrir, Fechar e Parar e mostra "Rearmar" |
| `rok` | `1` = leitor RFID presente. Com `0`, o botão "Ler tag" fica desabilitado |
| `rfid` | Última tag lida. O app só conta quando o valor muda |
| `f1`, `f2`, `fa`, `ff`, `up` | Ignorados pelo app (`fa`/`ff` hoje sempre `"00"`) |

JSON inválido é ignorado e registrado no log; campos faltando ou desconhecidos
não derrubam o app.

## Eventos (characteristic de evento)

| `ev` | Uso no app |
|---|---|
| `RESP` | Resposta ao comando (`id`, `res`). Todo resultado diferente de `OK` vira aviso (tabela abaixo) |
| `INICIO` | `ver` aparece no cabeçalho do painel ("firmware 1.3.0") |
| `OBSTACULO` | Aviso "Obstáculo na porta … — ela vai reabrir" |
| `EMERGENCIA` | Com `on:1` e origem diferente de `APP` (ex.: botão físico), mostra um aviso |
| `RFID` / `RFID_SAIU` | Tag chegou / saiu do leitor (`uid`). A tag aparece no painel e no cadastro do animal |
| `FALHA` | Aviso com o motivo da falha da porta |
| `PORTA`, `REARME` | Não usados (o estado já traz a informação) |

`orig` pode ser `APP`, `SERIAL`, `BOTAO` ou `SISTEMA`. No `RESP`, `id` é 0
quando o comando veio do botão físico e `p` é 0 quando não é comando de porta.

| `res` | Mensagem no app |
|---|---|
| `OK` | (nenhuma) |
| `JA_ABERTA` / `JA_FECHADA` | "A porta já está aberta/fechada." |
| `INTERTRAVAMENTO` | "Feche a outra porta antes de abrir esta." |
| `OBSTACULO` | "Há algo embaixo da porta, não é possível fechar." |
| `EMERGENCIA` | "Emergência ativa, faça o rearme." (no `RESET`: "Solte o botão de parada primeiro.") |
| `NAO_PERMITIDO` | "Comando não permitido agora." |
| `PORTA_INVALIDA` / `INVALIDO` | "Erro interno do app" (e registrado no log) |

## Firmware 1.3.0 (o que está na placa)

O firmware completo está na pasta `BoviCare_Firmware/`, na raiz do projeto
(`BoviCare_Brete_Final/BoviCare_Brete_Final.ino`, com a documentação dele em
`BoviCare_Firmware/docs/`). O app trata as novidades em relação à 1.1:

| Novidade | No app |
|---|---|
| Porta em `FALHA` (`f1`/`f2`: `TIMEOUT_ABRIR`, `TIMEOUT_FECHAR`, `FIM_DUPLO`, `FIM_PRESO`) | Card da porta em vermelho com o motivo; Abrir/Fechar desabilitados |
| `res: FALHA` e evento `{"ev":"FALHA","p":2,"f":"..."}` | Aviso na tela |
| `RESET` também limpa as falhas | "Reiniciar sistema" envia `RESET` com emergência **ou** falha |
| Leitor RC522 automático: `{"ev":"RFID","uid":"04A1B2C3"}` e `RFID_SAIU` | "Ler tag" devolve a tag que está no brete ou espera a próxima (não envia `LER_RFID`, que a 1.3 não tem) |
| `fa`/`ff` com as chaves de fim de curso | Ignorados pelo app |

## Reiniciar sistema (botão na tela do brete)

O firmware não tem comando para reiniciar a placa. O botão faz um reinício
pelo app: `PARAR` (as duas portas), `RESET` se houver emergência ou falha, e
refaz a conexão Bluetooth. Funciona também com o brete desconectado.
