// =====================================================================
//  BoviCare - Brete automatizado
//  ble_brete.h  ->  servidor Bluetooth Low Energy (GATT) para o app
//
//  Serviço BoviCare com três características:
//    COMANDO (escrita)               texto: "ABRIR 1", "#17 FECHAR 2"...
//    ESTADO  (leitura + notificação) JSON com o retrato do brete
//    EVENTO  (notificação)           JSON de cada evento
//  Detalhes em docs/PROTOCOLO_BLE.md.
// =====================================================================
#pragma once
#include <Arduino.h>

namespace ble {

void iniciar(const char* nome);
void manter();                                   // chamar no laço (reanúncio)
bool conectado();
bool consumirNovaConexao();                      // true uma vez por conexão
bool proximoComando(char* destino, size_t tam);  // não bloqueia
void publicarEstado(const char* json, size_t tam);
void publicarEvento(const char* json, size_t tam);
void imprimirDiagnostico(Print& s);

}  // namespace ble
