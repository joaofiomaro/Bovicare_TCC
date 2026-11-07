// =====================================================================
//  BoviCare - Brete automatizado
//  leitor_rfid.h  ->  RC522 numa tarefa FreeRTOS separada (núcleo 0)
//
//  A leitura do RC522 leva alguns milissegundos e pode travar com ruído
//  dos motores. Por isso ela roda isolada e só entrega EVENTOS ao laço
//  principal por uma fila: o controle das portas nunca espera o RFID.
// =====================================================================
#pragma once
#include <Arduino.h>
#include "tipos.h"

namespace rfid {

enum class TipoLeitura : uint8_t { CHEGOU, SAIU, LEITOR_OK, LEITOR_ERRO };

struct Leitura {
  TipoLeitura tipo;
  char uid[UID_MAX_CHARS];
};

void iniciar();
bool proxima(Leitura& out);          // não bloqueia
void imprimirDiagnostico(Print& s);

}  // namespace rfid
