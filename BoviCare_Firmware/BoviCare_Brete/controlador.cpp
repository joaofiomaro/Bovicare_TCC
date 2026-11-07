// =====================================================================
//  BoviCare - Brete automatizado
//  controlador.cpp  ->  coordenação das portas            (LÓGICA PURA)
// =====================================================================
#include "controlador.h"
#include "parametros.h"
#include <string.h>

static inline bool passou(uint32_t agora, uint32_t inicio, uint32_t duracao) {
  return (uint32_t)(agora - inicio) >= duracao;
}

// ---------------------------------------------------------------------
// Fila de eventos (circular; se lotar, descarta o mais antigo)
// ---------------------------------------------------------------------
void Controlador::empilhar(const Evento& ev) {
  if (_qtd == CAPACIDADE_EVENTOS) {
    _ini = (uint8_t)((_ini + 1) % CAPACIDADE_EVENTOS);
    _qtd--;
    _perdidos++;
  }
  uint8_t pos = (uint8_t)((_ini + _qtd) % CAPACIDADE_EVENTOS);
  _fila[pos] = ev;
  _qtd++;
}

bool Controlador::proximoEvento(Evento& out) {
  if (_qtd == 0) return false;
  out = _fila[_ini];
  _ini = (uint8_t)((_ini + 1) % CAPACIDADE_EVENTOS);
  _qtd--;
  return true;
}

// ---------------------------------------------------------------------
// Inicialização ("partida segura")
// ---------------------------------------------------------------------
void Controlador::iniciar(const ConfigPorta& cfg, const EntradasSistema& e, uint32_t agora,
                          bool intertravamento, uint32_t tempoRearmeMs) {
  _e = e;
  _intertravamento = intertravamento;
  _tempoRearme = tempoRearmeMs;
  _qtd = 0;
  _ini = 0;
  _perdidos = 0;
  _uid[0] = 0;

  Evento ini;
  ini.tipo = TipoEvento::INICIO;
  empilhar(ini);

  for (uint8_t i = 0; i < 2; i++) {
    _porta[i].iniciar(cfg, e.porta[i], agora);
    _porta[i].consumirMudancaEstado();     // estado inicial vai no "retrato"
  }
  coletarSinaisDasPortas();               // falha já no boot (ex.: fio solto)

  // Botão de porta pressionado no boot: ignora até soltar.
  _antBotao1 = e.botao1;
  _antBotao2 = e.botao2;
  _antParada = e.botaoParada;
  _ignorarBotao1 = e.botao1;
  _ignorarBotao2 = e.botao2;

  // Parada pressionada no boot: entra em emergência.
  _emergencia = false;
  _contandoRearme = false;
  if (e.botaoParada) ativarEmergencia(Origem::BOTAO, agora);
  _mudou = true;
}

bool Controlador::algumaFalha() const {
  return _porta[0].estado() == EstadoPorta::FALHA || _porta[1].estado() == EstadoPorta::FALHA;
}

// ---------------------------------------------------------------------
// Emergência
// ---------------------------------------------------------------------
void Controlador::ativarEmergencia(Origem origem, uint32_t agora) {
  _porta[0].parar(agora);
  _porta[1].parar(agora);
  if (_emergencia) return;
  _emergencia = true;
  _origemEmergencia = origem;
  _contandoRearme = false;
  // Para rearmar pelo botão é preciso soltá-lo e segurar de novo.
  _paradaSoltaDesdeEmergencia = !_e.botaoParada;
  Evento ev;
  ev.tipo = TipoEvento::EMERGENCIA;
  ev.ligado = true;
  ev.origem = origem;
  empilhar(ev);
  _mudou = true;
}

void Controlador::rearmar(Origem origem, uint32_t agora) {
  bool estavaEmEmergencia = _emergencia;
  _emergencia = false;
  _contandoRearme = false;
  _paradaSoltaDesdeEmergencia = false;
  _porta[0].limparFalha(agora);
  _porta[1].limparFalha(agora);
  if (estavaEmEmergencia) {
    Evento ev;
    ev.tipo = TipoEvento::EMERGENCIA;
    ev.ligado = false;
    ev.origem = origem;
    empilhar(ev);
  }
  Evento r;
  r.tipo = TipoEvento::REARME;
  r.origem = origem;
  empilhar(r);
  _mudou = true;
}

// ---------------------------------------------------------------------
// Botões físicos
// ---------------------------------------------------------------------
void Controlador::tratarBotoes(const EntradasSistema& e, uint32_t agora) {
  // --- Parada manual (redundância dos sensores) ---
  bool subiu = e.botaoParada && !_antParada;
  bool desceu = !e.botaoParada && _antParada;
  if (subiu) {
    if (!_emergencia) {
      ativarEmergencia(Origem::BOTAO, agora);
    } else if (_paradaSoltaDesdeEmergencia) {
      _contandoRearme = true;          // segurar por P_REARME_MS rearma
      _inicioRearme = agora;
    }
  }
  if (desceu && _emergencia) {
    _paradaSoltaDesdeEmergencia = true;
    _contandoRearme = false;
  }
  if (_emergencia && _contandoRearme && e.botaoParada &&
      passou(agora, _inicioRearme, _tempoRearme)) {
    rearmar(Origem::BOTAO, agora);
  }
  _antParada = e.botaoParada;

  // --- Botões das portas (alternam: abre / fecha / para) ---
  bool b1 = e.botao1 && !_antBotao1 && !_ignorarBotao1;
  bool b2 = e.botao2 && !_antBotao2 && !_ignorarBotao2;
  if (!e.botao1) _ignorarBotao1 = false;
  if (!e.botao2) _ignorarBotao2 = false;
  _antBotao1 = e.botao1;
  _antBotao2 = e.botao2;

  if (b1) {
    Comando c;
    c.tipo = TipoComando::ALTERNAR;
    c.porta = 1;
    executar(c, Origem::BOTAO, agora);
  }
  if (b2) {
    Comando c;
    c.tipo = TipoComando::ALTERNAR;
    c.porta = 2;
    executar(c, Origem::BOTAO, agora);
  }
}

// ---------------------------------------------------------------------
// Laço
// ---------------------------------------------------------------------
void Controlador::coletarSinaisDasPortas() {
  for (uint8_t i = 0; i < 2; i++) {
    Porta& p = _porta[i];
    if (p.consumirObstaculo()) {
      Evento ev;
      ev.tipo = TipoEvento::OBSTACULO;
      ev.porta = (uint8_t)(i + 1);
      empilhar(ev);
      _mudou = true;
    }
    if (p.consumirFalha()) {
      Evento ev;
      ev.tipo = TipoEvento::FALHA;
      ev.porta = (uint8_t)(i + 1);
      ev.falha = p.falha();
      empilhar(ev);
      _mudou = true;
    }
    if (p.consumirMudancaEstado()) {
      Evento ev;
      ev.tipo = TipoEvento::PORTA;
      ev.porta = (uint8_t)(i + 1);
      ev.estado = p.estado();
      empilhar(ev);
      _mudou = true;
    }
  }
}

void Controlador::atualizar(const EntradasSistema& e, uint32_t agora) {
  // Mudança em qualquer entrada também atualiza o estado enviado ao app.
  for (uint8_t i = 0; i < 2; i++) {
    if (e.porta[i].obstaculo != _e.porta[i].obstaculo ||
        e.porta[i].fimAberta != _e.porta[i].fimAberta ||
        e.porta[i].fimFechada != _e.porta[i].fimFechada) {
      _mudou = true;
    }
  }
  if (e.botao1 != _e.botao1 || e.botao2 != _e.botao2 || e.botaoParada != _e.botaoParada) {
    _mudou = true;
  }
  _e = e;

  tratarBotoes(e, agora);
  for (uint8_t i = 0; i < 2; i++) _porta[i].atualizar(e.porta[i], agora);
  coletarSinaisDasPortas();
}

// ---------------------------------------------------------------------
// Comandos
// ---------------------------------------------------------------------
Resultado Controlador::abrirComIntertravamento(uint8_t i, uint32_t agora) {
  const Porta& outra = _porta[1 - i];
  // Uma porta só abre com a outra FECHADA: o animal não atravessa direto.
  if (_intertravamento && outra.estado() != EstadoPorta::FECHADA &&
      _porta[i].estado() != EstadoPorta::ABERTA) {
    return Resultado::INTERTRAVAMENTO;
  }
  return _porta[i].abrir(agora);
}

void Controlador::eventoResposta(const Comando& c, Origem o, Resultado r) {
  Evento ev;
  ev.tipo = TipoEvento::RESP;
  ev.cmd = c.tipo;
  ev.porta = (c.porta > 0) ? (uint8_t)c.porta : 0;
  ev.id = c.id;
  ev.res = r;
  ev.origem = o;
  empilhar(ev);
}

Resultado Controlador::executar(const Comando& c, Origem origem, uint32_t agora) {
  Resultado r = Resultado::OK;
  bool precisaPorta = (c.tipo == TipoComando::ABRIR || c.tipo == TipoComando::FECHAR ||
                       c.tipo == TipoComando::ALTERNAR || c.tipo == TipoComando::JOG);

  if (c.tipo == TipoComando::INVALIDO || c.tipo == TipoComando::NENHUM) {
    r = Resultado::INVALIDO;
  } else if (c.porta < 0 || c.porta > 2 || (precisaPorta && c.porta == 0)) {
    r = Resultado::PORTA_INVALIDA;
  } else {
    uint8_t i = (c.porta > 0) ? (uint8_t)(c.porta - 1) : 0;
    switch (c.tipo) {
      case TipoComando::STATUS:
        _mudou = true;
        break;
      case TipoComando::PING:
      case TipoComando::DIAG:
      case TipoComando::AJUDA:
        break;
      case TipoComando::PARAR:            // sempre aceito, até em emergência
        if (c.porta == 0) {
          _porta[0].parar(agora);
          _porta[1].parar(agora);
        } else {
          _porta[i].parar(agora);
        }
        break;
      case TipoComando::EMERGENCIA:
        ativarEmergencia(origem, agora);
        break;
      case TipoComando::RESET:
        rearmar(origem, agora);
        break;
      case TipoComando::ABRIR:
        r = _emergencia ? Resultado::EMERGENCIA : abrirComIntertravamento(i, agora);
        break;
      case TipoComando::FECHAR:
        r = _emergencia ? Resultado::EMERGENCIA : _porta[i].fechar(agora);
        break;
      case TipoComando::ALTERNAR: {
        if (_emergencia) { r = Resultado::EMERGENCIA; break; }
        EstadoPorta est = _porta[i].estado();
        if (_porta[i].emMovimento()) {
          _porta[i].parar(agora);
        } else if (est == EstadoPorta::ABERTA) {
          r = _porta[i].fechar(agora);
        } else if (est == EstadoPorta::FALHA) {
          r = Resultado::FALHA;
        } else {                              // FECHADA ou PARADA no meio
          r = abrirComIntertravamento(i, agora);
        }
        break;
      }
      case TipoComando::JOG:
        if (origem != Origem::SERIAL_USB) r = Resultado::NAO_PERMITIDO;
        else if (_emergencia) r = Resultado::EMERGENCIA;
        else r = _porta[i].jog(c.jogSobe, c.jogMs, agora);
        break;
      default:
        r = Resultado::INVALIDO;
        break;
    }
  }
  eventoResposta(c, origem, r);
  coletarSinaisDasPortas();
  return r;
}

// ---------------------------------------------------------------------
// RFID
// ---------------------------------------------------------------------
void Controlador::rfidLido(const char* uid) {
  // Guarda só caracteres hexadecimais (o UID vai direto para o JSON).
  uint8_t n = 0;
  for (const char* p = uid; *p && n < UID_MAX_CHARS - 1; p++) {
    char ch = *p;
    if ((ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'F')) _uid[n++] = ch;
    else if (ch >= 'a' && ch <= 'f') _uid[n++] = (char)(ch - 'a' + 'A');
  }
  _uid[n] = 0;
  Evento ev;
  ev.tipo = TipoEvento::RFID;
  strncpy(ev.uid, _uid, UID_MAX_CHARS);
  empilhar(ev);
  _mudou = true;
}

void Controlador::rfidSaiu() {
  Evento ev;
  ev.tipo = TipoEvento::RFID_SAIU;
  strncpy(ev.uid, _uid, UID_MAX_CHARS);
  empilhar(ev);
  _uid[0] = 0;
  _mudou = true;
}

void Controlador::rfidStatus(bool ok) {
  _rfidOk = ok;
  Evento ev;
  ev.tipo = ok ? TipoEvento::RFID_OK : TipoEvento::RFID_ERRO;
  empilhar(ev);
  _mudou = true;
}
