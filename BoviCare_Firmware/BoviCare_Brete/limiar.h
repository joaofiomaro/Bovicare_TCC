// =====================================================================
//  BoviCare - Brete automatizado
//  limiar.h  ->  leitura analógica dos sensores IR com histerese
//
//  Os sensores do projeto têm um resistor interno de ~10 kΩ para o +5 V.
//  Com o divisor 2,2 kΩ + 3,3 kΩ ao GND, a saída fica em ~1,75 V sem
//  obstáculo e ~0 V com obstáculo: baixo demais para a leitura digital
//  (ALTO >= ~2,5 V), mas bem separado para a leitura analógica (ADC).
//  Função pura, sem Arduino, para poder ser testada no computador.
// =====================================================================
#pragma once
#include <stdint.h>

// true = obstáculo.  Abaixo de limiarObstaculo -> obstáculo; acima de
// limiarLivre -> livre; entre os dois, mantém o estado anterior.
inline bool irObstaculoPorTensao(uint16_t mv, bool obstaculoAnterior,
                                 uint16_t limiarObstaculo, uint16_t limiarLivre) {
  if (mv < limiarObstaculo) return true;
  if (mv > limiarLivre) return false;
  return obstaculoAnterior;
}
