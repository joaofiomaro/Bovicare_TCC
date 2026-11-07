// =====================================================================
//  BoviCare - Brete automatizado
//  config_pinos.h  ->  MAPA DE PINOS DO ESP32 (DevKit 38 pinos, ESP32-WROOM-32)
//
//  Este é o ÚNICO lugar do firmware onde os pinos são definidos.
//  A documentação fio a fio está em docs/LIGACOES.md.
//
//  Porta 1 = porta de ENTRADA   |   Porta 2 = porta de SAÍDA (leitor RFID)
// =====================================================================
#pragma once

// ---------------------------------------------------------------------
// Leitor RFID RC522 (barramento SPI "VSPI")  -  alimentar em 3,3 V!
// ---------------------------------------------------------------------
#define PINO_RFID_SS     21   // SDA/SS do módulo
#define PINO_RFID_SCK    18
#define PINO_RFID_MOSI   23
#define PINO_RFID_MISO   19
#define PINO_RFID_RST    22

// ---------------------------------------------------------------------
// Driver ponte H L298N  (retire os jumpers ENA e ENB do módulo)
// ---------------------------------------------------------------------
#define PINO_M1_EN       13   // ENA  (PWM)  -> motor da porta 1 (OUT1/OUT2)
#define PINO_M1_IN1      14   // IN1
#define PINO_M1_IN2      27   // IN2
#define PINO_M2_IN3      26   // IN3         -> motor da porta 2 (OUT3/OUT4)
#define PINO_M2_IN4      25   // IN4
#define PINO_M2_EN       33   // ENB  (PWM)

// ---------------------------------------------------------------------
// Sensores de presença IR E18-D80NK (um por porta)
// GPIO 34 e 35 são SOMENTE ENTRADA e não têm resistor interno:
// o nível do sinal é dado pelo divisor de tensão (ver LIGACOES.md).
// ---------------------------------------------------------------------
#define PINO_IR_1        34   // porta 1
#define PINO_IR_2        35   // porta 2

// ---------------------------------------------------------------------
// Chaves de fim de curso (contato NF ao GND, pull-up interno do ESP32)
// Repouso = BAIXO.  Acionada ou fio solto = ALTO (falha segura).
// ---------------------------------------------------------------------
#define PINO_FIM_1_ABERTA   16
#define PINO_FIM_1_FECHADA  17
#define PINO_FIM_2_ABERTA    4
#define PINO_FIM_2_FECHADA  32

// ---------------------------------------------------------------------
// Botões (um lado no 3,3 V, outro no GPIO + resistor de 10 kΩ ao GND)
// Botões 1 e 2: contato NO  -> solto = BAIXO, apertado = ALTO.
// Parada:       contato NC  -> solto = ALTO,  apertado = BAIXO.
//   Com o NC, um fio rompido também dá BAIXO = parada (falha segura).
// ---------------------------------------------------------------------
#define PINO_BOTAO_1        36   // alterna a porta 1 (entrada)   - somente entrada
#define PINO_BOTAO_2        39   // alterna a porta 2 (saída)     - somente entrada
#define PINO_BOTAO_PARADA    5   // parada manual (botão com anel, contato NC)

// ---------------------------------------------------------------------
// LED de estado (LED azul da própria placa)
// ---------------------------------------------------------------------
#define PINO_LED             2

// ---------------------------------------------------------------------
// Sentido dos motores: se o carretel girar ao contrário (desenrolando
// quando deveria enrolar), troque o valor para 1. Equivale a inverter
// os dois fios do motor no borne do L298N.
// ---------------------------------------------------------------------
#define INVERTER_MOTOR_1     0
#define INVERTER_MOTOR_2     0

// ---------------------------------------------------------------------
// Lógica elétrica das entradas (não altere sem rever LIGACOES.md)
// ---------------------------------------------------------------------
#define IR_OBSTACULO_EM_NIVEL_BAIXO   1   // E18-D80NK: saída vai a 0 V com obstáculo
// Sensores IR lidos pelo ADC (tensão em mV) em vez de digitalmente.
// 1 = analógico (montagem atual: divisor 2,2 k + 3,3 k, ~1,75 V sem obstáculo)
// 0 = digital   (exige >= ~2,5 V sem obstáculo, ex.: divisor com +10 kΩ)
#define IR_LEITURA_ANALOGICA          1
#define FIM_ACIONADO_EM_NIVEL_ALTO    1   // NF ao GND + pull-up: abriu o contato = ALTO
#define BOTAO_PRESSIONADO_EM_ALTO     1   // botões 1 e 2: NO ao 3,3 V + pull-down
#define PARADA_PRESSIONADA_EM_ALTO    0   // parada: NC ao 3,3 V + pull-down (apertar ABRE o contato)
