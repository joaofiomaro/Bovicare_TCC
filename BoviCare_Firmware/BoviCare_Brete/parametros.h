// =====================================================================
//  BoviCare - Brete automatizado
//  parametros.h  ->  tempos, PWM, comportamento e identificação BLE
//
//  Arquivo de LÓGICA PURA: não inclui Arduino.h (usado também nos
//  testes que rodam no computador).
// =====================================================================
#pragma once

#define FIRMWARE_VERSAO          "1.0.3"

// ---------------------------------------------------------------------
// Tempos do movimento das portas (milissegundos)
// ---------------------------------------------------------------------
#define P_TEMPO_MAX_CURSO_MS     8000   // curso real medido: ~4,5 s abrindo, ~3 s fechando
#define P_FIM_PRESO_MS           1500   // a chave de partida tem de soltar nesse tempo
#define P_RAMPA_MS                300   // partida suave (PWM sobe nesse tempo)
#define P_FREIO_MS                150   // freio dinâmico ao parar ou inverter
#define P_PAUSA_OBSTACULO_MS      300   // pausa antes de reabrir após obstáculo
#define P_JOG_MAX_MS             1000   // limite do movimento de ajuste (JOG)

// ---------------------------------------------------------------------
// Filtros das entradas (milissegundos)
// ---------------------------------------------------------------------
#define P_DEBOUNCE_FIM_MS          20
#define P_DEBOUNCE_BOTAO_MS        30
#define P_IR_CONFIRMA_MS            6   // obstáculo confirmado após esse tempo
#define P_IR_LIBERA_MS            300   // feixe livre por esse tempo libera o fechamento
// Leitura analógica dos IR (IR_LEITURA_ANALOGICA = 1): histerese em mV.
// Medido em 16/10/2026: ~1750 mV livre, ~0 mV com obstáculo.
#define P_IR_LIMIAR_OBSTACULO_MV  700   // abaixo disso: obstáculo
#define P_IR_LIMIAR_LIVRE_MV     1100   // acima disso: livre (entre os dois: mantém)
#define P_REARME_MS              3000   // segurar o botão de parada para rearmar

// ---------------------------------------------------------------------
// PWM dos motores (L298N)  -  duty de 0 a 255
// ---------------------------------------------------------------------
#define P_PWM_FREQ_HZ            1000
#define P_PWM_BITS                  8
#define P_PWM_ABRIR               255   // subir a porta (motor levanta o peso)
#define P_PWM_FECHAR              255   // descer a porta (máximo, ajustado na montagem)
#define P_PWM_PARTIDA             120   // início da rampa
#define P_PWM_JOG                 255   // movimento de ajuste (máximo)

// ---------------------------------------------------------------------
// Comportamento
// ---------------------------------------------------------------------
#define P_RECUAR_APOS_OBSTACULO     1   // 1 = reabre a porta; 0 = apenas para
#define P_INTERTRAVAMENTO           1   // 1 = uma porta só abre com a outra FECHADA

// ---------------------------------------------------------------------
// Comunicação e RFID
// ---------------------------------------------------------------------
#define P_ESTADO_PERIODO_MS      2000   // envio periódico do estado pelo BLE
#define P_RFID_PERIODO_MS          80   // intervalo entre leituras do RC522
#define P_RFID_AUSENCIA_MS       1500   // sem leitura por esse tempo = tag saiu
#define P_RFID_VERIFICA_MS       2000   // checagem de saúde do RC522
#define P_SERIAL_BAUD          115200

// ---------------------------------------------------------------------
// Bluetooth Low Energy
// ---------------------------------------------------------------------
#define BLE_NOME_DISPOSITIVO     "BoviCare-Brete"
#define BLE_UUID_SERVICO         "b0c1ca5e-0001-4b8e-9d3a-6f2e1c7a9d10"
#define BLE_UUID_COMANDO         "b0c1ca5e-0002-4b8e-9d3a-6f2e1c7a9d10"   // escrita
#define BLE_UUID_ESTADO          "b0c1ca5e-0003-4b8e-9d3a-6f2e1c7a9d10"   // leitura + notificação
#define BLE_UUID_EVENTO          "b0c1ca5e-0004-4b8e-9d3a-6f2e1c7a9d10"   // notificação
#define BLE_MTU                   247
