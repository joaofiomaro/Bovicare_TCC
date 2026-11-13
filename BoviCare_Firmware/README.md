# BoviCare — Firmware do Brete Automatizado (ESP32)

Firmware do brete de contenção do BoviCare (TCC de Engenharia de Computação).
Autores: João Pedro Fiomaro Santos e Leonardo Moreira Trento Pinge. Orientador: Prof. Renato Ferrari da Costa.

O firmware controla as **duas portas guilhotina**: cada uma tem um motor JGB37-3530 que enrola a corda num carretel. Ele **lê o brinco RFID** do animal contido e conversa com o **aplicativo por Bluetooth Low Energy (BLE)**. Toda a segurança roda no próprio ESP32 e não depende do app nem da conexão.

| Documento | Conteúdo |
|---|---|
| `docs/LIGACOES.md` | Mapa de pinos e ligações fio a fio de toda a automação (rev. 1.1: montagem real na caixa, barramentos e mapa da protoboard) |
| `BoviCare_Brete_Final/` | **Firmware para usar no brete (1.5.1), arquivo único e completo**: portas com **chaves de fim de curso** (o tempo de 3 s / 2,2 s estima a posição e é limite de segurança), segura a porta aberta e a recoloca na chave se escorregar, falhas `FIM_DUPLO`, `FIM_PRESO`, `TIMEOUT_ABRIR`, `TIMEOUT_FECHAR` (liberadas com `RESET`), botões, parada (NC), sensores IR, intertravamento, **leitor RFID RC522** e **Bluetooth no protocolo** de `docs/PROTOCOLO_BLE.md`. Ajustes da serial ficam salvos na memória. Precisa da biblioteca **MFRC522** (GithubCommunity). Compila nos cores 2.0.17 e 3.x, sem avisos |
| `BoviCare_Brete/` | Versão modular anterior (1.0.3), dividida em vários arquivos: **depende das 4 chaves de fim de curso** e não tem a função de segurar a porta aberta. Mantida como referência e para os testes nativos; para o brete, use a `BoviCare_Brete_Final` |
| `BoviCare_Teste_COM_Parada/` e `BoviCare_Teste_SEM_Parada/` | Sketches de teste **sem RFID e sem fins de curso** (curso por tempo), motores em PWM máximo: com e sem o botão de parada. Não precisam da biblioteca MFRC522 |
| `docs/PROTOCOLO_BLE.md` | Serviço BLE, comandos, JSON de estado e eventos, exemplo em Flutter |
| `docs/BoviCare_Firmware_Ligacoes.pdf` | Versão para imprimir das ligações, com diagramas |

### Situação da verificação

| Verificação | Resultado |
|---|---|
| Compilação no core ESP32 **3.3.12** (Arduino) | OK, sem avisos — 1.134.662 bytes (36 %), RAM 43.052 bytes (13 %) |
| Compilação no core ESP32 **2.0.17** (Arduino) | OK, sem avisos — 1.151.693 bytes (36 %), RAM 40.676 bytes (12 %) |
| Testes automáticos da **1.5.1** no PC (o próprio `.ino`, placa simulada e modelo físico das porteiras) | **182** verificações OK em 27 cenários, 0 falhas, 4 achados para a próxima versão (seção 8.1) |
| Validação do JSON da 1.5.1 | **3.276** amostras OK (estado com no máximo 244 bytes) |
| Testes da versão modular 1.0.3 (lógica, JSON e simulação) | 163 + 15 + 33 verificações OK (seção 8.2) |
| Teste na placa e na maquete | Feito pela equipe por observação, sem medições (TCC, seção 5.6.3) |

---

## 1. O que o firmware faz

| Função | Como funciona |
|---|---|
| Abrir e fechar as portas | Controle por PWM no L298N, com **partida suave** (rampa de 300 ms) e **freio dinâmico** ao parar ou inverter o sentido |
| Fins de curso | Quatro chaves (aberta e fechada em cada porta), ligadas no contato **NF**: um fio solto é lido como "fim de curso atingido" e o motor para (**falha segura**) |
| Parada automática por presença | Um sensor IR E18-D80NK por porta. Se detectar algo **durante o fechamento**, o firmware freia e **reabre** a porta, como um portão automático. Com obstáculo presente, a porta não começa a fechar |
| Parada manual | Botão com anel, redundante aos sensores, ligado no contato **NC** (normalmente fechado): apertar o botão **ou romper o fio** trava o sistema (emergência) até ser rearmado |
| Rearme | Solte o botão de parada e depois **segure-o por 3 s**, ou envie `RESET` pelo app ou pela serial |
| Intertravamento | Uma porta só abre se a outra estiver **FECHADA**, para o animal não atravessar o brete direto |
| Detecção de falhas | Tempo de curso excedido (porta travada), chave de partida que não solta (corda partida, chave presa), as duas chaves da mesma porta acionadas. A porta com falha fica bloqueada até o `RESET` |
| Leitura RFID | O RC522 roda em tarefa própria (núcleo 0). Gera evento quando a tag chega e quando sai (1,5 s sem leitura). Reinicia o leitor sozinho se ele travar por ruído dos motores |
| Botões físicos | Botão 1 alterna a porta de entrada e botão 2 a de saída: abre, fecha, ou para se estiver em movimento |
| App (BLE) | Recebe comandos de texto (`ABRIR 1`, `FECHAR 2`, `PARAR`...). Envia o **estado** em JSON (a cada mudança e a cada 2 s) e os **eventos** (porta, obstáculo, falha, emergência, RFID e a resposta de cada comando). A cada conexão, reenvia o retrato completo |
| Partida segura | Ao ligar, nenhum motor se move. O estado inicial das portas sai das chaves. Um botão pressionado durante o boot é ignorado até ser solto; a parada pressionada no boot entra em emergência |
| Watchdog | Se o laço principal travar por mais de ~5 s, o ESP32 reinicia, com os motores desligados pelos resistores de pull-down de ENA/ENB |
| Diagnóstico | Comando `DIAG` na serial: nível elétrico de cada entrada, ação dos motores, tempo do laço, estado do RFID e do BLE |

### Estados de cada porta

```
                 ABRIR                      fim "aberta"
   FECHADA ───────────────► ABRINDO ─────────────────────► ABERTA
      ▲                        │ PARAR                        │
      │ fim "fechada"          ▼                              │ FECHAR
      │                     PARADA ◄──────── PARAR ───────────┤
      │                                                       ▼
      └──────────────────────────────────────────────────  FECHANDO
                                                              │ obstáculo (IR)
                     RECUANDO (freia, pausa, reabre) ◄────────┘
   Qualquer estado ──(tempo excedido / chave presa / fim duplo)──► FALHA ──RESET──► (estado das chaves)
```

---

## 2. Estrutura do projeto

```
BoviCare_Firmware/
├── BoviCare_Brete/            ← pasta do sketch (abra o .ino no Arduino IDE)
│   ├── BoviCare_Brete.ino     setup() e loop() chamam aplicacao.cpp
│   ├── aplicacao.h / .cpp     laço: entradas → lógica → comandos → motores → mensagens
│   ├── config_pinos.h         MAPA DE PINOS (único lugar onde os pinos são definidos)
│   ├── parametros.h           tempos, PWM, nome e UUIDs do Bluetooth
│   ├── tipos.h                tipos compartilhados                    (lógica pura)
│   ├── porta.h / .cpp         máquina de estados de UMA porta         (lógica pura)
│   ├── controlador.h / .cpp   duas portas, botões, emergência, eventos (lógica pura)
│   ├── protocolo.h / .cpp     comandos de texto e JSON                (lógica pura)
│   ├── debounce.h             filtro das entradas                      (lógica pura)
│   ├── hardware_brete.h/.cpp  pinos, PWM, freio do L298N
│   ├── leitor_rfid.h / .cpp   RC522 numa tarefa FreeRTOS separada
│   └── ble_brete.h / .cpp     servidor BLE (GATT)
├── testes_nativos/            testes automáticos no PC (sem placa)
├── docs/                      LIGACOES.md, PROTOCOLO_BLE.md
└── platformio.ini             para quem usa PlatformIO/VS Code
```

Os módulos de "lógica pura" não usam nenhuma função do Arduino. Por isso são testados no computador, inclusive com uma simulação física das portas (seção 8).

---

## 3. Software necessário

| Item | Versão | Onde |
|---|---|---|
| Arduino IDE | 2.x | arduino.cc |
| Placas ESP32 ("esp32 by Espressif Systems") | **2.0.x ou 3.x** (testado em 2.0.17 e 3.3.12) | Gerenciador de Placas |
| Biblioteca **MFRC522** (GithubCommunity / miguelbalboa) | **1.4.12 ou mais nova** | Gerenciador de Bibliotecas |
| Driver USB da placa | CP210x (a placa usada tem o chip CP2102) | site da Silicon Labs |

> **Não use a MFRC522 1.4.11:** ela não compila com o compilador do core ESP32 3.x recente (erro em `MFRC522Extended.cpp`). A 1.4.12 corrige.
> **Não instale a biblioteca "MFRC522v2"**: ela tem outra API. A correta se chama apenas **MFRC522**.
> A biblioteca de Bluetooth já vem com o pacote de placas ESP32. Não instale nenhuma outra biblioteca "BLE".

---

## 4. Como compilar e gravar

### Arduino IDE

1. **Arquivo → Preferências → URLs adicionais**: adicione
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
2. **Ferramentas → Placa → Gerenciador de Placas**: instale **esp32** (Espressif Systems).
3. **Ferramentas → Gerenciar Bibliotecas**: instale **MFRC522** (versão 1.4.12 ou mais nova).
4. Abra `BoviCare_Brete/BoviCare_Brete.ino`. A IDE abre todos os arquivos da pasta em abas, e a pasta precisa continuar com esse nome.
5. Ferramentas:
   - **Placa:** `ESP32 Dev Module` (ou `DOIT ESP32 DEVKIT V1`)
   - **Partition Scheme:** `Huge APP (3MB No OTA/1MB SPIFFS)`. O programa (~1,1 MB) até cabe no esquema padrão, mas com pouca folga.
   - **Upload Speed:** 921600 (se falhar, use 115200)
   - **Porta:** a COM ou ttyUSB da placa
6. Clique em **Carregar**. Se ficar em `Connecting....`, segure o botão **BOOT** da placa até começar a gravar.
7. Abra o **Monitor Serial** em **115200** baud, com o final de linha em **"Nova linha"**. Deve aparecer:

```
================================================
  BoviCare - Brete automatizado  (firmware 1.0.3)
  Digite AJUDA para ver os comandos.
================================================
Bluetooth: anunciando como "BoviCare-Brete"
EVT {"ev":"INICIO","ver":"1.0.3"}
EST {"p1":"FECHADA","p2":"FECHADA",...}
```

### PlatformIO (VS Code)

Abra a pasta `BoviCare_Firmware` e rode `PlatformIO: Upload`, ou na linha de comando:
`pio run -t upload && pio device monitor`. O `platformio.ini` já define a placa, a partição e a biblioteca.

---

## 5. Primeira energização: ordem recomendada

Monte e teste **por etapas**, nesta ordem. Cada etapa só começa quando a anterior passou. O passo a passo das ligações está em `docs/LIGACOES.md`.

| Etapa | O que ligar | Como testar | Resultado esperado |
|---|---|---|---|
| 0 | Nada energizado | Multímetro em continuidade entre os barramentos +12 V, +5 V e GND | **Sem curto.** Jumpers ENA/ENB do L298N **retirados** |
| 1 | Fonte + conversor DC-DC | Medir os barramentos | 12 V e **5,0 a 5,2 V** (antes de ligar o ESP32) |
| 2 | ESP32 no USB | Gravar o firmware e abrir o monitor serial | Cabeçalho aparece. Sem as chaves ligadas, as duas portas entram em `FALHA FIM_DUPLO` e o LED pisca rápido: é o **comportamento fail-safe esperado** (fio solto = fim de curso acionado) |
| 3 | Fins de curso | `DIAG` e depois acionar cada chave com o dedo | Em repouso: `BAIXO`. Acionada: `ALTO`. Em seguida `RESET`: as falhas somem |
| 4 | Botões | `DIAG` / `STATUS` pressionando cada um | `"bot":"100"`, `"010"`, `"001"` |
| 5 | Sensores IR (fazer antes a **medição** da seção 7.2 de LIGACOES.md) | Mão na frente de cada sensor | `"ir":"10"` / `"01"` com a mão, `"00"` sem a mão |
| 6 | RC522 | Ver o evento no boot e aproximar uma tag | `EVT {"ev":"RFID_OK"}` e depois `EVT {"ev":"RFID","uid":"..."}`. **Anote o UID de cada tag** |
| 7 | Bluetooth | App **nRF Connect**: conectar em `BoviCare-Brete`, ligar as notificações de ESTADO e EVENTO e escrever `PING` (texto) em COMANDO | Recebe `{"ev":"RESP","cmd":"PING",...,"res":"OK","orig":"APP"}`; o LED fica aceso fixo |
| 8 | Motores (12 V), **corda ainda solta** | `JOG 1 SOBE 300` e `JOG 2 SOBE 300` | O carretel gira no sentido de **enrolar** a corda. Se girar ao contrário, mude `INVERTER_MOTOR_x` para 1 em `config_pinos.h` (ou inverta os 2 fios no borne) |
| 9 | Corda e portas montadas | `ABRIR 1`, `FECHAR 1`, `ABRIR 2`, `FECHAR 2` | A porta para ao tocar a chave. Anote o tempo do curso (Monitor Serial → mostrar data/hora) |
| 10 | Testes de segurança | Ver a tabela abaixo | Todos os itens OK |

### Testes de segurança (para registrar no TCC)

| Teste | Procedimento | Esperado |
|---|---|---|
| Obstáculo no fechamento | `FECHAR 1` e colocar a mão no feixe do IR | Freia (na simulação: 6 ms após o feixe), pausa 0,3 s e **reabre**: `EVT OBSTACULO`, porta `RECUANDO` e depois `ABERTA` |
| Não fecha com obstáculo | Mão no feixe e depois `FECHAR 1` | `"res":"OBSTACULO"`; a porta não se move |
| Parada manual | Botão de parada com a porta em movimento | Para na hora; `EMERGENCIA on:1`; nenhum comando de movimento funciona |
| Fio da parada rompido | Soltar o fio da col. 7 (GPIO 5) com o sistema ligado | Entra em emergência como se o botão fosse apertado (falha segura do contato NC) |
| Rearme | Soltar e segurar o botão vermelho por 3 s | `EMERGENCIA on:0` e `REARME`; volta a operar |
| Intertravamento | Com a porta 1 aberta, `ABRIR 2` | `"res":"INTERTRAVAMENTO"` |
| Corda partida | Soltar a corda do carretel e `ABRIR 1` | Após 1,5 s: `FALHA FIM_PRESO` (a chave "fechada" não soltou); motor desligado |
| Porta travada | Segurar a porta no meio durante a abertura | Após 6 s: `FALHA TIMEOUT_ABRIR`; motor desligado |
| Fio de fim de curso solto | Soltar o fio NF de uma chave | A porta não se move naquele sentido (lê como acionada) ou entra em falha |
| Queda do Bluetooth | Desligar o Bluetooth do celular com a porta fechando e pôr a mão no IR | Reabre igual. **A segurança não depende do app** |

---

## 6. Comandos (serial e app)

Os comandos são texto e aceitam maiúsculas ou minúsculas. Separadores aceitos: espaço, `:` `=` `,` `;`. Na porta, `1`, `ENTRADA` ou `E` indicam a porta de entrada, e `2`, `SAIDA` ou `S` a de saída.

| Comando | Efeito | Observação |
|---|---|---|
| `ABRIR 1` / `ABRIR 2` | Abre a porta | Recusado com a outra porta não fechada (intertravamento) |
| `FECHAR 1` / `FECHAR 2` | Fecha a porta | Recusado com obstáculo no IR |
| `ALTERNAR 1` / `ALTERNAR 2` | Mesmo efeito do botão físico | |
| `PARAR` / `PARAR 1` | Para as duas portas, ou só uma | Sempre aceito, inclusive em emergência |
| `EMERGENCIA` | Parada de emergência pelo app | Trava tudo até o rearme |
| `RESET` | Rearma a emergência e limpa as falhas | |
| `STATUS` | Força o envio do estado | |
| `PING` | Teste de comunicação | |
| `DIAG` | Diagnóstico completo | Saída só no monitor serial |
| `AJUDA` | Lista os comandos | Só no monitor serial |
| `JOG 1 SOBE 300` | Movimento curto de ajuste (máx. 1 s) | **Somente pela serial**; pelo app é recusado (`NAO_PERMITIDO`) |
| `#17 ABRIR 1` | Qualquer comando com um **id** (1 a 65535) | A resposta volta com `"id":17` |

Toda saída na serial começa com `EVT ` (evento) ou `EST ` (estado) seguido do JSON. Os formatos estão em `docs/PROTOCOLO_BLE.md`.

---

## 7. LED da placa (GPIO 2)

| LED | Significado |
|---|---|
| Uma piscada curta por segundo | Funcionando, aguardando o app |
| Aceso fixo | App conectado |
| Piscando rápido | **Emergência ativa** ou **porta em falha**; use `STATUS`/`DIAG` |

---

## 8. Testes automáticos (sem placa)

```
cd testes_nativos
bash rodar_testes.sh
```

Exige `g++` (C++17) e `python3`. Os testes compilam com `-Wall -Wextra -Werror` e com os detectores de erro de memória (AddressSanitizer/UBSan).

### 8.1 Firmware do brete (1.5.1)

`testes_nativos/final/teste_final.cpp` compila o **próprio** `BoviCare_Brete_Final.ino`, sem nenhuma linha mudada, contra uma placa ESP32 simulada (`final/stubs/` e `final/placa_sim.cpp`: pinos, tempo, PWM, Serial, memória NVS, filas do FreeRTOS, Bluetooth e RC522). A tarefa do RFID roda numa thread, intercalada com o laço principal pelo relógio simulado. As saídas dos motores movem um **modelo físico** das duas porteiras (curso de 300 mm, sobe a 115 mm/s e desce a 140 mm/s com PWM 255, escorrega a 20 mm/s com o motor solto), que aciona as chaves de fim de curso; o teste põe e tira o animal embaixo de cada porta (sensor IR), aperta botões e a parada, e encosta tags no leitor.

Cada um dos 27 cenários roda num processo separado, com a placa recém-ligada:

| Grupo | O que é conferido |
|---|---|
| Partida | Nenhum motor se move ao ligar; estado inicial lido nas chaves (fechada, aberta, no meio); `FIM_DUPLO` na partida; botão apertado no boot ignorado até soltar; parada apertada (ou fio rompido) no boot entra em emergência |
| Portas | Abrir e fechar pelo app, pelos botões e pela serial; freio antes de inverter; porta aberta ou parada no meio segurada sem cair; `JA_ABERTA`, `JA_FECHADA`, `PARAR`, `ALTERNAR`, `JOG` |
| Segurança | Intertravamento (as duas porteiras nunca abertas juntas); animal embaixo: não começa a fechar e, fechando, o motor para em até 20 ms e a porta reabre; emergência pelo botão, pelo app e por fio rompido, com a porta segurada e os comandos recusados; rearme só depois de soltar e segurar 3 s |
| Falhas | `FIM_PRESO` (corda partida) em 4 s; `FIM_DUPLO` no meio do curso; `LIMITE` de fábrica sem limite e, com `LIMITE 10`, `TIMEOUT_ABRIR` e `TIMEOUT_FECHAR` em 10 s, saindo com um novo comando; `RESET` pelo app e pelos botões 1 e 2 |
| Ajustes | `TEMPO`, `SEGURAR`, `INVERTER`, `CHAVE`, `LIMITE` e `PADRAO` salvos na memória e relidos; valores fora da faixa recusados; comandos só da serial recusados pelo app; `TESTE` e `VARRER` |
| RFID | Evento `RFID` uma vez por animal, `RFID_SAIU` 1,5 s depois de a tag sair, troca de animal, leitor sem resposta (`RFID_ERRO`, avisado uma vez) e de volta, chip reiniciado por ruído e reconfigurado sozinho, filtro do UID |
| Bluetooth | Ao conectar, o app recebe `INICIO`, o animal que está no brete e o estado; estado a cada 2 s; volta a anunciar 0,5 s depois de desconectar |
| Ciclos de manejo | 200 ciclos seguidos com tempos sorteados (entra, fecha, lê o brinco, abre a saída, sai, fecha), 20 deles com o animal voltando embaixo da porta: nenhuma falha, nenhum comando recusado, cada brinco lido uma vez, porteiras nunca abertas juntas |

Todos os JSON emitidos nos cenários (eventos e estado) são gravados e conferidos por `validar_json.py`.

Os números do modelo (velocidade da porta, escorregamento) são **suposições** para o teste, não medidas da maquete. Os testes conferem a lógica do firmware ligada a esse modelo; não substituem o teste na maquete.

**Checagem dos próprios testes:** cópias do `.ino` com um defeito de propósito (sem intertravamento, sem parada por obstáculo, sensor IR invertido, `FIM_PRESO` de 40 s, rearme em 0,3 s) foram todas reprovadas, com 2 a 21 falhas cada.

#### Achados para a próxima versão

Os testes acharam quatro comportamentos da 1.5.1 que não aparecem com os ajustes de fábrica no uso normal, mas que vale corrigir. Eles aparecem como `ACHADO` em toda execução, sem reprovar a bateria:

1. **Motor solto na pausa antes de reabrir.** Quando o sensor IR vê o animal e a porta para, o motor fica solto nos ~150 ms entre o fim do freio e a reabertura. No modelo, a porta escorrega cerca de 3 mm nesse intervalo.
2. **`SEGURAR 0` com a porta escorregando.** Com a força de segurar em 0, depois de levantar a porta de volta até a chave o motor continua ligado em PWM máximo contra o topo. Com o valor de fábrica (`SEGURAR 100`) isso não acontece.
3. **Comando desconhecido longo.** A resposta repete o comando, e um comando desconhecido de 60 a 64 caracteres (o máximo aceito) não cabe no buffer de 128 bytes: a resposta sai cortada e o JSON chega inválido ao app.
4. **Comando com aspas.** O comando desconhecido é repetido sem escape, e uma aspa no texto quebra o JSON da resposta.

Correção sugerida para os itens 1 e 2, conferida com os testes (os dois achados somem e nada mais quebra):

```cpp
    case RECUANDO:
      if (!m.freando && agora - p.inicioPausa >= PAUSA_OBSTACULO_MS) {
        p.inicioMov = agora;
        mudarEstado(i, ABRINDO);
      } else if (!m.freando && pwmSegurar && (m.dir != +1 || m.pwm != pwmSegurar)) {
        ligarMotor(i, +1, pwmSegurar);   // segura a porta na pausa antes de reabrir
      }
      break;
    ...
    case PARADA:
    case FALHA:
      if (pwmSegurar == 0 && !m.freando && m.dir != 0 && !(p.estado == ABERTA && p.corrigindo)) { frearMotor(i, agora); break; }
```

Para os itens 3 e 4, basta repetir na resposta só letras, números e `_` do comando, até 16 caracteres.

### 8.2 Versão modular anterior (1.0.3)

`testes_nativos/teste_logica.cpp` e `simulacao.cpp` testam os módulos de lógica pura de `BoviCare_Brete/`. Eles cobrem:

- todas as transições das portas, tempos-limite, chave presa, fim duplo e a virada do contador `millis()` (49 dias);
- botões, intertravamento, emergência e rearme, a fila de eventos e o RFID;
- a interpretação dos comandos e o tamanho máximo do JSON (o estado tem no máximo 164 bytes).

A **simulação física** liga a lógica real a um modelo da maquete (curso de 300 mm, carretel de 16 mm, ~140 mm/s com PWM máximo) e mede:

| Cenário | Resultado da simulação |
|---|---|
| Ciclo de manejo completo (entra, contém, lê RFID, sai) | Porta abre em 2,2 s e fecha em 2,9 s; ciclo em 15,6 s, sem falhas |
| Animal sob a porta durante o fechamento | Freio **6 ms** após o feixe ser interrompido; reabre até o fim |
| Corda partida | Detectada em **1,5 s** (`FIM_PRESO`) |
| Porta travada no meio | Detectada em **6,0 s** (`TIMEOUT_ABRIR`) |
| Parada manual durante o fechamento | Porta anda 3 mm após o botão e para |
| Abrir as duas portas | Bloqueado pelo intertravamento |

Esses números são do **modelo**. Na maquete, meça o tempo real do curso (etapa 9) e ajuste `P_TEMPO_MAX_CURSO_MS`.

---

## 9. Ajustes finos (`parametros.h`)

| Parâmetro | Padrão | Quando mudar |
|---|---|---|
| `P_TEMPO_MAX_CURSO_MS` | 8000 | Curso real ≈ 4,5 s abrindo e ≈ 3 s fechando; use ~1,5–2× o maior tempo |
| `P_FIM_PRESO_MS` | 1500 | Tempo para a chave de partida soltar; aumente se a porta demorar a sair do batente |
| `P_PWM_ABRIR` | 255 | Diminua se a porta bater forte em cima |
| `P_PWM_FECHAR` | 255 | Máximo (ajustado na montagem). Diminua se a porta descer rápido demais |
| `P_PWM_PARTIDA` | 120 | Aumente se o motor "zumbir" sem girar na partida |
| `P_RECUAR_APOS_OBSTACULO` | 1 | 0 = só para (não reabre) |
| `P_INTERTRAVAMENTO` | 1 | 0 = libera abrir as duas portas (só para testes de bancada) |
| `P_IR_LIBERA_MS` | 300 | Tempo que o feixe precisa ficar livre para liberar o fechamento |
| `P_RFID_AUSENCIA_MS` | 1500 | Tempo sem leitura para considerar que a tag saiu |
| `BLE_NOME_DISPOSITIVO` | BoviCare-Brete | Mude se houver mais de um brete por perto |

---

## 10. Limitações conhecidas (declarar no TCC)

1. **Teste no alvo:** o firmware compila sem avisos nos cores ESP32 2.0.17 e 3.3.12 e a lógica foi testada e simulada no PC. O **funcionamento na placa e na maquete** ainda precisa ser validado pela equipe (seção 5).
2. **BLE sem pareamento:** qualquer celular próximo com o app consegue enviar comandos. Para um produto, adicionar pareamento com senha (bonding) ou um token de sessão.
3. **Sensor IR:** na ligação com divisor de tensão (variante A), um fio de sinal rompido é lido como obstáculo (seguro). Na variante de coletor aberto, ele é lido como "livre" e **não é detectado** — por isso o botão de parada manual é a redundância. Num produto, usar sensores com saída de segurança ou duplicados.
4. **Botão de parada sem trava:** a parada já usa o contato NC (fio rompido = emergência), mas o botão volta sozinho ao ser solto. Num produto, usar botão de emergência tipo cogumelo com trava mecânica (norma de segurança de máquinas).
5. **RFID 13,56 MHz (RC522):** serve para a **maquete**. Os brincos eletrônicos de bovinos usam **134,2 kHz (ISO 11784/11785, FDX-B/HDX)**, com alcance de dezenas de centímetros. Para o produto real, troque o leitor por um módulo LF de 134,2 kHz com saída serial. Só o módulo `leitor_rfid` muda: os eventos e o app continuam iguais.
6. **Sem relógio de tempo real:** o firmware não marca data e hora nos eventos. O app registra o horário ao receber.

---

## 11. Relação com os objetivos do TCC

| Objetivo / requisito do projeto | Onde está no firmware |
|---|---|
| Acionamento das portas por botões físicos ou pelo app | `controlador.cpp` (`tratarBotoes`, `executar`) e `ble_brete.cpp` |
| Parada de emergência automática por presença, independente do app | `porta.cpp` (estado `FECHANDO` → `RECUANDO`), executada no laço local |
| Botão manual como redundância | `controlador.cpp` (`ativarEmergencia`, rearme por 3 s) |
| Identificação do animal por RFID no brete | `leitor_rfid.cpp` → evento `RFID` → app abre a ficha do animal |
| Comunicação BLE com o app (comando + confirmação) | `protocolo.cpp`: `RESP` com `id` do comando, estado e eventos |
| Segurança em camadas | Hardware (pull-downs, contato NF, divisor) → firmware (máquina de estados, tempos-limite, watchdog) → app |
| Robustez em campo | Filtros de ruído, reinício automático do RC522, sincronismo ao reconectar |

> **Divergências com documentos anteriores:**
> - A proposta original citava servomotores e PVC. O projeto evoluiu para **motores DC com redução (JGB37-3530) + roldanas e corda**, e estrutura com guia metálica em U. O texto do TCC deve ser atualizado.
> - No Guia de Eletrônica anterior, os botões dos GPIO 36/39 eram "abrir" e "fechar"; agora cada um **alterna uma porta**. Os pinos são os mesmos.
> - Entram **2 resistores de 10 kΩ** a mais (pull-down de ENA/ENB) e a biblioteca passa a ser a MFRC522 **1.4.12**.
> - Com o carretel de 16 mm, o curso de 30 cm leva ~2,2 s (a estimativa antiga de ~1 s considerava uma polia maior).
