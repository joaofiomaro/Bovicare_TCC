# Protocolo MQTT do Brete Eletrônico (ESP32 ↔ BoviCare)

Contrato entre o firmware do brete (ESP32) e o app. O app já implementa este
protocolo (`lib/features/brete/`); o firmware precisa seguir os tópicos e
payloads abaixo.

## Conexão

| Item | Valor |
|---|---|
| Broker | Mosquitto (ou similar) na rede da fazenda |
| Transporte do app | WebSocket `ws://IP:9001` (recomendado) ou TCP `mqtt://IP:1883` |
| Configuração no app | `.env` → `MQTT_BROKER_URL`, `BRETE_DEVICE_ID` (padrão `brete-01`), `MQTT_USERNAME`, `MQTT_PASSWORD` |
| Sem broker configurado | O app entra em **modo simulação** (mesmas regras, sem hardware) |
| QoS | 1 (pelo menos uma vez) |

Exemplo de `mosquitto.conf` com WebSocket e autenticação:

```
listener 1883
listener 9001
protocol websockets
allow_anonymous false
password_file /etc/mosquitto/passwd
```

## Tópicos

`{id}` = `BRETE_DEVICE_ID`.

| Tópico | Direção | Retido | Conteúdo |
|---|---|---|---|
| `bovicare/brete/{id}/cmd` | app → ESP32 | não | comando |
| `bovicare/brete/{id}/state` | ESP32 → app | **sim** | estado completo |
| `bovicare/brete/{id}/rfid` | ESP32 → app | não | tag lida |

### Comandos (`cmd`)

```json
{ "cmd": "open", "ts": "2026-03-10T12:00:00.000Z" }
```

| `cmd` | Efeito esperado no firmware |
|---|---|
| `open` | Abre a porteira (ignorar se em emergência) |
| `close` | Fecha a porteira (**não fechar** com sensor IR obstruído) |
| `emergency_stop` | Para o motor imediatamente e trava até `reset` |
| `reset` | Sai da emergência e fecha a porteira |
| `read_rfid` | Faz uma leitura imediata do leitor RFID |

### Estado (`state`, retido)

Publicar sempre que algo mudar e ao conectar (retido, para o app receber o
estado atual ao abrir o painel):

```json
{
  "door": "closed",
  "sensors": { "irTop": false, "irBottom": false, "pedalOpen": false, "pedalClose": false }
}
```

`door`: `open`, `closed`, `opening`, `closing`, `emergency`.
Sensores: `true` = obstruído (IR) ou acionado (pedal).

Recomendado: configurar *Last Will* do ESP32 em `state` com
`{"door":"unknown"}` para o app perceber queda do dispositivo.

### RFID (`rfid`)

```json
{ "tag": "900115000123456" }
```

Também é aceito o código em texto puro. O app aceita 4–32 caracteres
alfanuméricos (ISO 11784/11785 = 15 dígitos) e associa a tag ao animal com o
mesmo RFID no rebanho.

## Regras de segurança

- O **estado exibido vem sempre do ESP32**; o app só pede ações. Se o comando
  não for executado, o painel continua mostrando o estado real.
- Parada de emergência e rearme pedem confirmação no app.
- Use usuário/senha no broker e mantenha-o apenas na rede local. As
  credenciais ficam no `.env`, que vai dentro do APK: use uma conta do broker
  restrita aos tópicos `bovicare/brete/#`.
