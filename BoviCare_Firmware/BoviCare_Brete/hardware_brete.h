// =====================================================================
//  BoviCare - Brete automatizado
//  hardware_brete.h  ->  pinos, leitura das entradas, PWM e L298N
// =====================================================================
#pragma once
#include <Arduino.h>
#include "tipos.h"

// Leituras já convertidas para "ativo" (true) segundo a lógica elétrica
// de cada entrada (ver config_pinos.h e docs/LIGACOES.md).
struct EntradasBrutas {
  bool fimAberta[2];
  bool fimFechada[2];
  bool obstaculo[2];
  bool botao1;
  bool botao2;
  bool botaoParada;
};

namespace hw {
  void iniciar();                                       // motores parados primeiro
  void lerEntradas(EntradasBrutas& b);
  void aplicarMotor(uint8_t indice, AcaoMotor acao, uint8_t pwm);
  void led(bool aceso);
  void imprimirNiveis(Print& saida);                    // diagnóstico (DIAG)
}
