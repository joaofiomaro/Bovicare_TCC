// =====================================================================
//  BoviCare - Brete automatizado
//  controlador.h  ->  as duas portas, botões, emergência, intertravamento
//                     e fila de eventos                    (LÓGICA PURA)
// =====================================================================
#pragma once
#include "tipos.h"
#include "porta.h"

class Controlador {
 public:
  static const uint8_t CAPACIDADE_EVENTOS = 24;

  void iniciar(const ConfigPorta& cfg, const EntradasSistema& e, uint32_t agora,
               bool intertravamento, uint32_t tempoRearmeMs);

  // Chamada a cada volta do laço: botões, emergência e portas.
  void atualizar(const EntradasSistema& e, uint32_t agora);

  // Executa um comando (app, serial ou botão) e gera o evento RESP.
  Resultado executar(const Comando& c, Origem origem, uint32_t agora);

  // Leitor RFID
  void rfidLido(const char* uid);
  void rfidSaiu();
  void rfidStatus(bool ok);

  // Eventos pendentes (para a serial e o BLE)
  bool proximoEvento(Evento& out);
  uint32_t eventosPerdidos() const { return _perdidos; }

  // Consulta (para o JSON de estado)
  const Porta& porta(uint8_t indice) const { return _porta[indice]; }
  bool emergencia() const { return _emergencia; }
  Origem origemEmergencia() const { return _origemEmergencia; }
  const EntradasSistema& entradas() const { return _e; }
  const char* uidAtual() const { return _uid; }
  bool rfidOk() const { return _rfidOk; }
  bool algumaFalha() const;

  // true quando algo mudou desde a última consulta (estado deve ser enviado)
  bool consumirMudanca() { bool r = _mudou; _mudou = false; return r; }

 private:
  void empilhar(const Evento& ev);
  void ativarEmergencia(Origem origem, uint32_t agora);
  void rearmar(Origem origem, uint32_t agora);
  void tratarBotoes(const EntradasSistema& e, uint32_t agora);
  void coletarSinaisDasPortas();
  Resultado abrirComIntertravamento(uint8_t i, uint32_t agora);
  void eventoResposta(const Comando& c, Origem o, Resultado r);

  Porta _porta[2];
  EntradasSistema _e{};
  bool _intertravamento = true;
  uint32_t _tempoRearme = 3000;

  // Emergência e rearme
  bool     _emergencia = false;
  Origem   _origemEmergencia = Origem::SISTEMA;
  bool     _paradaSoltaDesdeEmergencia = false;
  bool     _contandoRearme = false;
  uint32_t _inicioRearme = 0;

  // Botões: nível anterior e bloqueio de botão pressionado no boot
  bool _antBotao1 = false, _antBotao2 = false, _antParada = false;
  bool _ignorarBotao1 = false, _ignorarBotao2 = false;

  // RFID
  char _uid[UID_MAX_CHARS] = {0};
  bool _rfidOk = false;

  // Fila circular de eventos
  Evento   _fila[CAPACIDADE_EVENTOS];
  uint8_t  _ini = 0, _qtd = 0;
  uint32_t _perdidos = 0;

  bool _mudou = true;
};
