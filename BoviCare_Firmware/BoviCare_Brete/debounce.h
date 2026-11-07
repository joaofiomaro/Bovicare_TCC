// =====================================================================
//  BoviCare - Brete automatizado
//  debounce.h  ->  filtro de ruído das entradas digitais   (LÓGICA PURA)
//
//  Tempos independentes para ATIVAR e DESATIVAR. Isso permite, no sensor
//  IR, confirmar um obstáculo em poucos milissegundos (segurança) e só
//  liberar depois de o feixe ficar livre por mais tempo (P_IR_LIBERA_MS).
//  Todas as contas de tempo são seguras contra a virada de millis().
// =====================================================================
#pragma once
#include <stdint.h>

class Debounce {
 public:
  void configurar(uint32_t tempoAtivarMs, uint32_t tempoDesativarMs,
                  bool estadoInicial, uint32_t agora) {
    _tAtivar = tempoAtivarMs;
    _tDesativar = tempoDesativarMs;
    _estavel = estadoInicial;
    _ultimoBruto = estadoInicial;
    _desde = agora;
  }

  // Recebe a leitura bruta. Retorna true quando o estado estável muda.
  bool atualizar(bool bruto, uint32_t agora) {
    if (bruto != _ultimoBruto) {
      _ultimoBruto = bruto;
      _desde = agora;
    }
    if (bruto != _estavel) {
      uint32_t necessario = bruto ? _tAtivar : _tDesativar;
      if ((uint32_t)(agora - _desde) >= necessario) {
        _estavel = bruto;
        return true;
      }
    }
    return false;
  }

  bool estado() const { return _estavel; }
  bool bruto() const { return _ultimoBruto; }

 private:
  uint32_t _tAtivar = 0;
  uint32_t _tDesativar = 0;
  uint32_t _desde = 0;
  bool _estavel = false;
  bool _ultimoBruto = false;
};
