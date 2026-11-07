// =====================================================================
//  BoviCare - Brete automatizado
//  leitor_rfid.cpp  ->  leitura contínua do RC522 (biblioteca MFRC522)
//
//  Estratégia de leitura: a cada P_RFID_PERIODO_MS envia WUPA (acorda
//  também tags em HALT), lê o UID e manda a tag dormir de novo (HLTA).
//  Assim a mesma tag é revista a cada ciclo enquanto estiver no campo:
//    - tag nova            -> CHEGOU
//    - sem leitura 1,5 s   -> SAIU
//  A saúde do leitor é conferida a cada 2 s (registro de versão e antena).
// =====================================================================
#include "leitor_rfid.h"
#include "config_pinos.h"
#include "parametros.h"
#include <SPI.h>
#include <MFRC522.h>

namespace rfid {
namespace {

MFRC522 leitor(PINO_RFID_SS, PINO_RFID_RST);
QueueHandle_t fila = nullptr;

volatile bool     leitorOk = false;
volatile uint8_t  versao = 0;
volatile uint32_t totalLeituras = 0;
volatile uint32_t reinicios = 0;
char uidPresente[UID_MAX_CHARS] = {0};

void enviar(TipoLeitura tipo, const char* uid) {
  Leitura l;
  l.tipo = tipo;
  l.uid[0] = 0;
  if (uid) {
    strncpy(l.uid, uid, UID_MAX_CHARS - 1);
    l.uid[UID_MAX_CHARS - 1] = 0;
  }
  xQueueSend(fila, &l, 0);        // fila cheia: descarta (nunca bloqueia)
}

bool versaoValida(uint8_t v) {
  // 0x91/0x92 = NXP original; 0x88, 0x12, 0xB2 = clones comuns
  return v != 0x00 && v != 0xFF;
}

bool inicializarLeitor() {
  leitor.PCD_Init();
  delay(10);
  uint8_t v = leitor.PCD_ReadRegister(MFRC522::VersionReg);
  versao = v;
  if (!versaoValida(v)) return false;
  leitor.PCD_SetAntennaGain(MFRC522::RxGain_max);
  leitor.PCD_AntennaOn();
  return true;
}

bool leitorSaudavel() {
  uint8_t v = leitor.PCD_ReadRegister(MFRC522::VersionReg);
  if (!versaoValida(v)) return false;
  // Ruído pode reiniciar o chip: antena desligada = registradores perdidos.
  uint8_t tx = leitor.PCD_ReadRegister(MFRC522::TxControlReg);
  return (tx & 0x03) == 0x03;
}

void uidParaTexto(const MFRC522::Uid& u, char* destino) {
  static const char HEX_DIG[] = "0123456789ABCDEF";
  uint8_t n = u.size > 10 ? 10 : u.size;
  for (uint8_t i = 0; i < n; i++) {
    destino[2 * i] = HEX_DIG[u.uidByte[i] >> 4];
    destino[2 * i + 1] = HEX_DIG[u.uidByte[i] & 0x0F];
  }
  destino[2 * n] = 0;
}

void tarefa(void*) {
  SPI.begin(PINO_RFID_SCK, PINO_RFID_MISO, PINO_RFID_MOSI, PINO_RFID_SS);
  uint32_t ultimaTentativa = 0;
  uint32_t ultimaVerificacao = 0;
  uint32_t ultimaLeitura = 0;
  bool presente = false;
  bool erroAvisado = false;
  bool primeiraTentativa = true;

  for (;;) {
    uint32_t agora = millis();

    if (!leitorOk) {
      if (primeiraTentativa || (uint32_t)(agora - ultimaTentativa) >= P_RFID_VERIFICA_MS) {
        primeiraTentativa = false;
        ultimaTentativa = agora;
        if (inicializarLeitor()) {
          leitorOk = true;
          erroAvisado = false;
          ultimaVerificacao = agora;
          enviar(TipoLeitura::LEITOR_OK, nullptr);
        } else if (!erroAvisado) {
          erroAvisado = true;
          enviar(TipoLeitura::LEITOR_ERRO, nullptr);
        }
      }
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }

    // Saúde do leitor
    if ((uint32_t)(agora - ultimaVerificacao) >= P_RFID_VERIFICA_MS) {
      ultimaVerificacao = agora;
      if (!leitorSaudavel()) {
        leitorOk = false;
        reinicios = reinicios + 1;
        if (presente) {
          presente = false;
          enviar(TipoLeitura::SAIU, uidPresente);
          uidPresente[0] = 0;
        }
        enviar(TipoLeitura::LEITOR_ERRO, nullptr);
        erroAvisado = true;
        ultimaTentativa = agora - P_RFID_VERIFICA_MS;   // tenta reiniciar já
        continue;
      }
    }

    // Leitura
    byte atqa[2];
    byte tam = sizeof(atqa);
    MFRC522::StatusCode st = leitor.PICC_WakeupA(atqa, &tam);
    if (st == MFRC522::STATUS_OK || st == MFRC522::STATUS_COLLISION) {
      if (leitor.PICC_ReadCardSerial()) {
        char uid[UID_MAX_CHARS];
        uidParaTexto(leitor.uid, uid);
        leitor.PICC_HaltA();
        ultimaLeitura = agora;
        totalLeituras = totalLeituras + 1;
        if (!presente || strcmp(uid, uidPresente) != 0) {
          if (presente) enviar(TipoLeitura::SAIU, uidPresente);   // trocou de animal
          strncpy(uidPresente, uid, UID_MAX_CHARS);
          presente = true;
          enviar(TipoLeitura::CHEGOU, uidPresente);
        }
      }
    }

    if (presente && (uint32_t)(agora - ultimaLeitura) >= P_RFID_AUSENCIA_MS) {
      presente = false;
      enviar(TipoLeitura::SAIU, uidPresente);
      uidPresente[0] = 0;
    }

    vTaskDelay(pdMS_TO_TICKS(P_RFID_PERIODO_MS));
  }
}

}  // namespace

void iniciar() {
  fila = xQueueCreate(8, sizeof(Leitura));
  // Núcleo 0, prioridade baixa: o laço principal (núcleo 1) nunca espera.
  xTaskCreatePinnedToCore(tarefa, "rfid", 4096, nullptr, 1, nullptr, 0);
}

bool proxima(Leitura& out) {
  if (!fila) return false;
  return xQueueReceive(fila, &out, 0) == pdTRUE;
}

void imprimirDiagnostico(Print& s) {
  s.printf("RFID RC522: %s  (versao 0x%02X)  leituras: %lu  reinicios: %lu  tag: %s\n",
           leitorOk ? "OK" : "SEM RESPOSTA", (unsigned)versao, (unsigned long)totalLeituras,
           (unsigned long)reinicios, uidPresente[0] ? uidPresente : "-");
}

}  // namespace rfid
