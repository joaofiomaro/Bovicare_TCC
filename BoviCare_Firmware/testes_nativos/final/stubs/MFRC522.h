// Imitação do leitor RC522 (biblioteca MFRC522): o teste põe e tira tags do campo.
#pragma once
#include "Arduino.h"
namespace sim {
extern bool rc522Responde;          // false = fio solto / sem 3,3 V (versão 0x00)
extern bool rc522AntenaLigada;      // false = o chip reiniciou por ruído (TxControl zerado)
extern std::vector<uint8_t> tagNoCampo;   // UID da tag presente (vazio = nenhuma)
extern int rc522Inits;
}
class MFRC522 {
 public:
  enum PCD_Register : uint8_t { TxControlReg = 0x14, VersionReg = 0x37 };
  enum PCD_RxGain : uint8_t { RxGain_max = 0x07 << 4 };
  enum StatusCode : uint8_t { STATUS_OK, STATUS_ERROR, STATUS_COLLISION, STATUS_TIMEOUT };
  struct Uid { byte size = 0; byte uidByte[10] = {0}; byte sak = 0; };
  Uid uid;
  MFRC522(uint8_t, uint8_t) {}
  void PCD_Init() { sim::rc522Inits++; sim::rc522AntenaLigada = false; }
  byte PCD_ReadRegister(PCD_Register r) {
    if (!sim::rc522Responde) return 0x00;
    if (r == VersionReg) return 0x92;
    if (r == TxControlReg) return sim::rc522AntenaLigada ? 0x83 : 0x80;
    return 0;
  }
  void PCD_SetAntennaGain(byte) {}
  void PCD_AntennaOn() { sim::rc522AntenaLigada = true; }
  StatusCode PICC_WakeupA(byte*, byte*) {
    return (sim::rc522Responde && sim::rc522AntenaLigada && !sim::tagNoCampo.empty()) ? STATUS_OK : STATUS_TIMEOUT;
  }
  bool PICC_ReadCardSerial() {
    if (sim::tagNoCampo.empty()) return false;
    uid.size = (byte)sim::tagNoCampo.size();
    for (size_t i = 0; i < sim::tagNoCampo.size() && i < 10; i++) uid.uidByte[i] = sim::tagNoCampo[i];
    return true;
  }
  StatusCode PICC_HaltA() { return STATUS_OK; }
};
