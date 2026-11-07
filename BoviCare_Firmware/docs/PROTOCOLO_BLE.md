# BoviCare — Protocolo de comunicação Brete ↔ Aplicativo (BLE)

O brete (ESP32) é um **servidor Bluetooth Low Energy**. O aplicativo conecta, assina as notificações e envia comandos de texto. O mesmo protocolo funciona no **monitor serial** (115200 baud), útil para testes sem o app.

> A segurança **não depende** desta comunicação. Parada por presença, fins de curso, tempos-limite e a parada manual rodam no ESP32 mesmo com o Bluetooth desconectado.

---

## 1. Identificação

| Item | Valor |
|---|---|
| Nome anunciado | `BoviCare-Brete` (alterável em `parametros.h` → `BLE_NOME_DISPOSITIVO`) |
| Serviço | `b0c1ca5e-0001-4b8e-9d3a-6f2e1c7a9d10` (anunciado, use-o como filtro na busca) |
| MTU | O ESP32 aceita até **247**. No Android, peça 247 ao conectar; o iOS negocia sozinho (≈ 185) |

### Características

| Nome | UUID | Propriedades | Conteúdo |
|---|---|---|---|
| **COMANDO** | `b0c1ca5e-0002-4b8e-9d3a-6f2e1c7a9d10` | Write, Write Without Response | Texto UTF-8, até 64 caracteres |
| **ESTADO** | `b0c1ca5e-0003-4b8e-9d3a-6f2e1c7a9d10` | Read, Notify | JSON com o retrato completo do brete |
| **EVENTO** | `b0c1ca5e-0004-4b8e-9d3a-6f2e1c7a9d10` | Notify | Um JSON por evento |

O **ESTADO** é enviado a cada mudança, a cada 2 s e logo após a conexão. Ele também pode ser **lido** a qualquer momento (útil no primeiro carregamento da tela).

---

## 2. Sequência típica

```
App                                   Brete (ESP32)
 │── busca pelo serviço BoviCare ───────►│ anunciando
 │── conecta / pede MTU 247 ────────────►│
 │── assina ESTADO e EVENTO ────────────►│
 │◄──────────── EVENTO {"ev":"INICIO","ver":"1.3.0"}
 │◄──────────── ESTADO {"p1":"FECHADA",...}
 │── COMANDO "#1 ABRIR 1" ──────────────►│ valida e executa
 │◄──────────── EVENTO {"ev":"RESP","cmd":"ABRIR","p":1,"id":1,"res":"OK","orig":"APP"}
 │◄──────────── EVENTO {"ev":"PORTA","p":1,"e":"ABRINDO"}
 │◄──────────── ESTADO {...}
 │◄──────────── EVENTO {"ev":"PORTA","p":1,"e":"ABERTA"}
 │  (animal passa, porta fecha, animal chega à saída)
 │◄──────────── EVENTO {"ev":"RFID","uid":"04A1B2C3"}   → app abre a ficha do animal
```

Recomendação para o app: mande **sempre um `id`** (`#1`, `#2`, …) e aguarde o `RESP` com o mesmo `id`. Se não chegar em ~2 s, considere o comando perdido e consulte o ESTADO.

---

## 3. Comandos (característica COMANDO ou serial)

Texto livre, maiúsculas ou minúsculas. Separadores aceitos: espaço, `:` `=` `,` `;`.
Porta: `1`, `ENTRADA` ou `E` = porta de entrada; `2`, `SAIDA` ou `S` = porta de saída.

| Comando | Efeito | Respostas possíveis (`res`) |
|---|---|---|
| `ABRIR 1` / `ABRIR 2` | Abre a porta | `OK`, `JA_ABERTA`, `INTERTRAVAMENTO`, `EMERGENCIA`, `FALHA`, `NAO_PERMITIDO` |
| `FECHAR 1` / `FECHAR 2` | Fecha a porta | `OK`, `JA_FECHADA`, `OBSTACULO`, `EMERGENCIA`, `FALHA`, `NAO_PERMITIDO` |
| `ALTERNAR 1` / `ALTERNAR 2` | Igual ao botão físico: abre, fecha ou para | idem |
| `PARAR` / `PARAR 1` / `PARAR 2` | Para as duas portas ou uma | `OK` (sempre aceito, inclusive em emergência) |
| `EMERGENCIA` | Parada de emergência pelo app | `OK` |
| `RESET` (ou `REARMAR`) | Rearma a emergência e limpa as falhas | `OK` |
| `STATUS` (ou `ESTADO`) | Força o envio do ESTADO | `OK` |
| `PING` | Teste de comunicação | `OK` |
| `JOG 1 SOBE 300` | Ajuste de bancada (até 1000 ms) | Pelo app sempre `NAO_PERMITIDO` — **só pela serial** |
| `DIAG` / `AJUDA` | Diagnóstico e lista de comandos | Saída só no monitor serial |
| `#17 ABRIR 1` | Qualquer comando com `id` de 1 a 65535 | A resposta traz `"id":17` |

Respostas de erro gerais: `INVALIDO` (comando desconhecido ou malformado) e `PORTA_INVALIDA` (porta ausente ou diferente de 1/2).

### Significado dos resultados

| `res` | Significado |
|---|---|
| `OK` | Comando aceito |
| `JA_ABERTA` / `JA_FECHADA` | Nada a fazer: a porta já está na posição |
| `INTERTRAVAMENTO` | A outra porta não está FECHADA; abrir as duas deixaria o animal atravessar |
| `OBSTACULO` | Há algo no feixe do sensor: a porta não começa a fechar |
| `EMERGENCIA` | Sistema em emergência: rearme com `RESET` ou segurando o botão vermelho por 3 s |
| `FALHA` | A porta está em falha (ver ESTADO `f1`/`f2`); corrija a causa e envie `RESET` |
| `NAO_PERMITIDO` | Operação não permitida nesse contexto (ex.: `JOG` pelo app, comando durante o ajuste) |
| `FIM_DE_CURSO` | `JOG` contra uma chave já acionada |

---

## 4. JSON de ESTADO

```json
{"p1":"FECHADA","p2":"ABERTA","f1":"","f2":"","ir":"00","fa":"01","ff":"10",
 "em":0,"bot":"000","rfid":"04A1B2C3","rok":1,"up":5321}
```

| Campo | Tipo | Significado |
|---|---|---|
| `p1`, `p2` | texto | Estado da porta 1 (entrada) e 2 (saída) — ver tabela abaixo |
| `f1`, `f2` | texto | Falha da porta (`""` = sem falha): `TIMEOUT_ABRIR`, `TIMEOUT_FECHAR`, `FIM_DUPLO`, `FIM_PRESO` |
| `ir` | 2 dígitos | Sensor IR das portas 1 e 2: `1` = obstáculo |
| `fa` | 2 dígitos | Fim de curso "aberta" das portas 1 e 2: `1` = acionado |
| `ff` | 2 dígitos | Fim de curso "fechada" das portas 1 e 2: `1` = acionado |
| `em` | 0/1 | Emergência ativa |
| `bot` | 3 dígitos | Botão 1, botão 2 e botão de parada: `1` = pressionado |
| `rfid` | texto | UID da tag presente no brete (`""` = nenhuma) |
| `rok` | 0/1 | Leitor RFID respondendo |
| `up` | número | Segundos desde que o brete ligou |

Tamanho máximo: **164 bytes** (verificado nos testes; limite de projeto 182 bytes, cabe numa notificação com MTU 185).

### Estados de cada porta

| Estado | Significado | Sugestão de exibição no app |
|---|---|---|
| `FECHADA` | Chave "fechada" acionada | Porta fechada (cadeado) |
| `ABRINDO` | Motor subindo a porta | Animação subindo |
| `ABERTA` | Chave "aberta" acionada | Porta aberta |
| `FECHANDO` | Motor descendo a porta | Animação descendo |
| `PARADA` | Parada no meio do curso | Alerta amarelo |
| `RECUANDO` | Obstáculo no fechamento: reabrindo | Alerta "obstáculo detectado" |
| `AJUSTE` | Movimento de manutenção (JOG) | "Em manutenção" |
| `FALHA` | Bloqueada; precisa de `RESET` | Alerta vermelho com o código de `f1`/`f2` |

---

## 5. JSON de EVENTO

Todo evento tem o campo `"ev"`.

| `ev` | Exemplo | Quando |
|---|---|---|
| `INICIO` | `{"ev":"INICIO","ver":"1.3.0"}` | Ao ligar o brete e a cada nova conexão BLE |
| `PORTA` | `{"ev":"PORTA","p":1,"e":"ABERTA"}` | Mudança de estado de uma porta |
| `OBSTACULO` | `{"ev":"OBSTACULO","p":1}` | Parada automática por presença durante o fechamento |
| `FALHA` | `{"ev":"FALHA","p":2,"f":"TIMEOUT_ABRIR"}` | Porta entrou em falha |
| `EMERGENCIA` | `{"ev":"EMERGENCIA","on":1,"orig":"BOTAO"}` | Emergência ligada (`on:1`) ou desligada (`on:0`) |
| `REARME` | `{"ev":"REARME","orig":"APP"}` | Sistema rearmado |
| `RESP` | `{"ev":"RESP","cmd":"ABRIR","p":1,"id":17,"res":"OK","orig":"APP"}` | Resposta a todo comando (app, serial **ou botão físico**) |
| `RFID` | `{"ev":"RFID","uid":"04A1B2C3"}` | Tag detectada no brete — **o app deve abrir a ficha do animal** |
| `RFID_SAIU` | `{"ev":"RFID_SAIU","uid":"04A1B2C3"}` | Tag sem leitura por 1,5 s |
| `RFID_OK` / `RFID_ERRO` | `{"ev":"RFID_ERRO"}` | Leitor respondendo / sem resposta (o firmware tenta reiniciá-lo sozinho) |

Origens (`orig`): `APP`, `SERIAL`, `BOTAO`, `SISTEMA`.

O UID é o identificador da tag em hexadecimal (4, 7 ou 10 bytes). No app, ele é a chave para encontrar o animal no banco SQLite local (campo "Tag RFID" da ficha do animal).

---

## 6. Exemplo em Flutter (`flutter_blue_plus`)

Trecho mínimo para a tela do Brete. A API do `flutter_blue_plus` muda entre versões: confira a documentação da versão instalada.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

final uuidServico = Guid('b0c1ca5e-0001-4b8e-9d3a-6f2e1c7a9d10');
final uuidComando = Guid('b0c1ca5e-0002-4b8e-9d3a-6f2e1c7a9d10');
final uuidEstado  = Guid('b0c1ca5e-0003-4b8e-9d3a-6f2e1c7a9d10');
final uuidEvento  = Guid('b0c1ca5e-0004-4b8e-9d3a-6f2e1c7a9d10');

class BreteBle {
  BluetoothCharacteristic? _comando;
  int _proximoId = 1;

  Future<void> conectar({
    required void Function(Map<String, dynamic>) aoEstado,
    required void Function(Map<String, dynamic>) aoEvento,
  }) async {
    // 1. Busca só dispositivos com o serviço BoviCare
    await FlutterBluePlus.startScan(
        withServices: [uuidServico], timeout: const Duration(seconds: 8));
    final resultado = await FlutterBluePlus.scanResults
        .expand((lista) => lista)
        .first;
    await FlutterBluePlus.stopScan();
    final brete = resultado.device;

    // 2. Conecta e ajusta o MTU (o iOS negocia sozinho)
    await brete.connect();
    if (Platform.isAndroid) await brete.requestMtu(247);

    // 3. Localiza as características
    final servicos = await brete.discoverServices();
    final s = servicos.firstWhere((x) => x.uuid == uuidServico);
    BluetoothCharacteristic car(Guid u) =>
        s.characteristics.firstWhere((c) => c.uuid == u);
    _comando = car(uuidComando);
    final estado = car(uuidEstado);
    final evento = car(uuidEvento);

    // 4. Assina as notificações
    estado.onValueReceived.listen(
        (v) => aoEstado(jsonDecode(utf8.decode(v)) as Map<String, dynamic>));
    evento.onValueReceived.listen(
        (v) => aoEvento(jsonDecode(utf8.decode(v)) as Map<String, dynamic>));
    await estado.setNotifyValue(true);
    await evento.setNotifyValue(true);

    // 5. Estado inicial
    aoEstado(jsonDecode(utf8.decode(await estado.read())));
  }

  /// Envia um comando com id; a resposta chega como evento RESP com o mesmo id.
  Future<int> enviar(String comando) async {
    final id = _proximoId++;
    await _comando!.write(utf8.encode('#$id $comando'));
    return id;
  }
}

// Uso na tela do brete:
//   ble.enviar('ABRIR 1');
//   aoEvento: if (ev['ev'] == 'RFID') abrirFichaDoAnimal(ev['uid']);
//             if (ev['ev'] == 'OBSTACULO') mostrarAlerta('Obstáculo na porta ${ev['p']}');
```

### Permissões necessárias

- **Android 12+:** `BLUETOOTH_SCAN` e `BLUETOOTH_CONNECT` no `AndroidManifest.xml` (e localização em versões anteriores ao 12).
- **iOS:** `NSBluetoothAlwaysUsageDescription` no `Info.plist`.

---

## 7. Teste sem o aplicativo (nRF Connect)

1. Instale o **nRF Connect** (Android ou iOS) e procure `BoviCare-Brete`.
2. Conecte e abra o serviço `b0c1ca5e-0001-…`.
3. Ative as notificações (ícone de setas) de **ESTADO** (`…0003…`) e **EVENTO** (`…0004…`).
4. Em **COMANDO** (`…0002…`), escreva em formato **texto (UTF-8)**: `PING`.
5. Deve chegar em EVENTO: `{"ev":"RESP","cmd":"PING","p":0,"id":0,"res":"OK","orig":"APP"}`, e o LED da placa fica aceso fixo.

---

## 8. Segurança da comunicação (limitação conhecida)

O protótipo não usa pareamento: qualquer celular próximo com o app pode enviar comandos. Para um produto, adicionar **pareamento com senha (bonding)** ou um **token de sessão** validado pelo firmware. Mesmo sem isso, comandos indevidos não anulam a segurança física: o intertravamento, a parada por presença e a parada manual continuam valendo.
