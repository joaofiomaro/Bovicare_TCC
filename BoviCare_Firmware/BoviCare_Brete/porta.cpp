// =====================================================================
//  BoviCare - Brete automatizado
//  porta.cpp  ->  máquina de estados de UMA porta   (LÓGICA PURA)
// =====================================================================
#include "porta.h"
#include "parametros.h"

// Tempo decorrido seguro contra a virada de millis() (49,7 dias)
static inline bool passou(uint32_t agora, uint32_t inicio, uint32_t duracao) {
  return (uint32_t)(agora - inicio) >= duracao;
}

ConfigPorta configPortaPadrao() {
  ConfigPorta c;
  c.tempoMaxCurso = P_TEMPO_MAX_CURSO_MS;
  c.fimPreso = P_FIM_PRESO_MS;
  c.rampa = P_RAMPA_MS;
  c.freio = P_FREIO_MS;
  c.pausaObstaculo = P_PAUSA_OBSTACULO_MS;
  c.jogMax = P_JOG_MAX_MS;
  c.pwmAbrir = P_PWM_ABRIR;
  c.pwmFechar = P_PWM_FECHAR;
  c.pwmPartida = P_PWM_PARTIDA;
  c.pwmJog = P_PWM_JOG;
  c.recuarAposObstaculo = (P_RECUAR_APOS_OBSTACULO != 0);
  return c;
}

// ---------------------------------------------------------------------
// Inicialização: nenhum movimento; estado vem das chaves
// ---------------------------------------------------------------------
void Porta::iniciar(const ConfigPorta& cfg, const EntradasPorta& e, uint32_t agora) {
  (void)agora;
  _cfg = cfg;
  _e = e;
  _acao = AcaoMotor::PARADO;
  _pwm = 0;
  _pwmAlvo = 0;
  _pendente = Sentido::NENHUM;
  _recuoAguardando = false;
  _verificarPartida = false;
  _falha = FalhaPorta::NENHUMA;
  if (e.fimAberta && e.fimFechada) {
    _estado = EstadoPorta::FALHA;
    _falha = FalhaPorta::FIM_DUPLO;
    _flagFalha = true;
  } else {
    _estado = estadoPelasChaves();
  }
  _flagEstado = true;
}

bool Porta::emMovimento() const {
  return _estado == EstadoPorta::ABRINDO || _estado == EstadoPorta::FECHANDO ||
         _estado == EstadoPorta::RECUANDO || _estado == EstadoPorta::AJUSTE;
}

EstadoPorta Porta::estadoPelasChaves() const {
  if (_e.fimFechada) return EstadoPorta::FECHADA;
  if (_e.fimAberta) return EstadoPorta::ABERTA;
  return EstadoPorta::PARADA;
}

void Porta::definirEstado(EstadoPorta novo) {
  if (novo != _estado) {
    _estado = novo;
    _flagEstado = true;
  }
}

// ---------------------------------------------------------------------
// Controle do motor: partida suave, freio dinâmico e inversão segura
// ---------------------------------------------------------------------
void Porta::ligarMotor(Sentido s, uint8_t pwmAlvo, uint32_t agora) {
  _acao = (s == Sentido::SUBIR) ? AcaoMotor::SUBIR : AcaoMotor::DESCER;
  _pwmAlvo = pwmAlvo;
  _pwm = (_cfg.pwmPartida < pwmAlvo) ? _cfg.pwmPartida : pwmAlvo;
  _inicioMotor = agora;
}

void Porta::pararMotor(uint32_t agora) {
  _pendente = Sentido::NENHUM;
  if (_acao == AcaoMotor::SUBIR || _acao == AcaoMotor::DESCER) {
    _acao = AcaoMotor::FREAR;
    _pwm = 255;
    _inicioFreio = agora;
  }
  // Se já estava freando, apenas cancela a partida pendente.
}

void Porta::comandarMotor(Sentido s, uint8_t pwmAlvo, uint32_t agora) {
  Sentido atual = Sentido::NENHUM;
  if (_acao == AcaoMotor::SUBIR) atual = Sentido::SUBIR;
  if (_acao == AcaoMotor::DESCER) atual = Sentido::DESCER;

  if (_acao == AcaoMotor::FREAR) {          // termina o freio e depois liga
    _pendente = s;
    _pwmPendente = pwmAlvo;
    return;
  }
  if (atual != Sentido::NENHUM && atual != s) {   // inversão: freia antes
    pararMotor(agora);
    _pendente = s;
    _pwmPendente = pwmAlvo;
    return;
  }
  if (atual == s) {                          // já está indo nesse sentido
    _pwmAlvo = pwmAlvo;
    return;
  }
  ligarMotor(s, pwmAlvo, agora);
}

void Porta::atualizarMotor(uint32_t agora) {
  if (_acao == AcaoMotor::FREAR) {
    if (passou(agora, _inicioFreio, _cfg.freio)) {
      if (_pendente != Sentido::NENHUM) {
        Sentido s = _pendente;
        _pendente = Sentido::NENHUM;
        ligarMotor(s, _pwmPendente, agora);
      } else {
        _acao = AcaoMotor::PARADO;
        _pwm = 0;
      }
    }
    return;
  }
  if (_acao == AcaoMotor::SUBIR || _acao == AcaoMotor::DESCER) {
    uint32_t decorrido = agora - _inicioMotor;
    if (_cfg.rampa == 0 || decorrido >= _cfg.rampa || _pwmAlvo <= _cfg.pwmPartida) {
      _pwm = _pwmAlvo;
    } else {
      uint32_t delta = (uint32_t)(_pwmAlvo - _cfg.pwmPartida) * decorrido / _cfg.rampa;
      _pwm = (uint8_t)(_cfg.pwmPartida + delta);
    }
  }
}

// ---------------------------------------------------------------------
// Falhas
// ---------------------------------------------------------------------
void Porta::entrarFalha(FalhaPorta f, uint32_t agora) {
  pararMotor(agora);
  _recuoAguardando = false;
  _verificarPartida = false;
  _falha = f;
  definirEstado(EstadoPorta::FALHA);
  _flagFalha = true;
}

void Porta::verificarFimPreso(uint32_t agora, bool chaveDePartidaAtiva) {
  if (!_verificarPartida) return;
  if (!chaveDePartidaAtiva) {          // soltou: tudo certo
    _verificarPartida = false;
    return;
  }
  bool girando = (_acao == AcaoMotor::SUBIR || _acao == AcaoMotor::DESCER);
  if (girando && passou(agora, _inicioMotor, _cfg.fimPreso)) {
    entrarFalha(FalhaPorta::FIM_PRESO, agora);
  }
}

void Porta::limparFalha(uint32_t agora) {
  (void)agora;
  if (_estado != EstadoPorta::FALHA) return;
  if (_e.fimAberta && _e.fimFechada) {   // continua com as duas chaves
    _falha = FalhaPorta::FIM_DUPLO;
    _flagFalha = true;
    return;
  }
  _falha = FalhaPorta::NENHUMA;
  definirEstado(estadoPelasChaves());
}

// ---------------------------------------------------------------------
// Comandos
// ---------------------------------------------------------------------
Resultado Porta::abrir(uint32_t agora) {
  if (_estado == EstadoPorta::FALHA) return Resultado::FALHA;
  if (_estado == EstadoPorta::AJUSTE) return Resultado::NAO_PERMITIDO;
  if (_estado == EstadoPorta::ABRINDO || _estado == EstadoPorta::RECUANDO) return Resultado::OK;
  if (_e.fimAberta) {
    pararMotor(agora);
    definirEstado(EstadoPorta::ABERTA);
    return Resultado::JA_ABERTA;
  }
  _recuoAguardando = false;
  comandarMotor(Sentido::SUBIR, _cfg.pwmAbrir, agora);
  _inicioCurso = agora;
  _verificarPartida = _e.fimFechada;    // a chave "fechada" deve soltar
  definirEstado(EstadoPorta::ABRINDO);
  return Resultado::OK;
}

Resultado Porta::fechar(uint32_t agora) {
  if (_estado == EstadoPorta::FALHA) return Resultado::FALHA;
  if (_estado == EstadoPorta::AJUSTE) return Resultado::NAO_PERMITIDO;
  if (_e.obstaculo) return Resultado::OBSTACULO;      // não começa a fechar
  if (_estado == EstadoPorta::FECHANDO) return Resultado::OK;
  if (_e.fimFechada) {
    pararMotor(agora);
    definirEstado(EstadoPorta::FECHADA);
    return Resultado::JA_FECHADA;
  }
  _recuoAguardando = false;
  comandarMotor(Sentido::DESCER, _cfg.pwmFechar, agora);
  _inicioCurso = agora;
  _verificarPartida = _e.fimAberta;     // a chave "aberta" deve soltar
  definirEstado(EstadoPorta::FECHANDO);
  return Resultado::OK;
}

void Porta::parar(uint32_t agora) {
  _recuoAguardando = false;
  _verificarPartida = false;
  pararMotor(agora);
  if (_estado == EstadoPorta::FALHA) return;
  if (_estado == EstadoPorta::AJUSTE) {
    definirEstado(_estadoAntesAjuste == EstadoPorta::FALHA ? EstadoPorta::FALHA
                                                           : estadoPelasChaves());
    return;
  }
  if (emMovimento()) definirEstado(estadoPelasChaves());
}

Resultado Porta::jog(bool subir, uint32_t duracaoMs, uint32_t agora) {
  if (emMovimento()) return Resultado::NAO_PERMITIDO;
  if (duracaoMs == 0) return Resultado::INVALIDO;
  if (subir && _e.fimAberta) return Resultado::FIM_DE_CURSO;
  if (!subir && _e.fimFechada) return Resultado::FIM_DE_CURSO;
  if (!subir && _e.obstaculo) return Resultado::OBSTACULO;
  if (duracaoMs > _cfg.jogMax) duracaoMs = _cfg.jogMax;
  _estadoAntesAjuste = _estado;
  _jogSobe = subir;
  _jogDuracao = duracaoMs;
  _jogInicio = agora;
  _verificarPartida = false;
  comandarMotor(subir ? Sentido::SUBIR : Sentido::DESCER, _cfg.pwmJog, agora);
  definirEstado(EstadoPorta::AJUSTE);
  return Resultado::OK;
}

// ---------------------------------------------------------------------
// Laço: avalia as entradas e avança a máquina de estados
// ---------------------------------------------------------------------
void Porta::atualizar(const EntradasPorta& e, uint32_t agora) {
  _e = e;

  // As duas chaves acionadas ao mesmo tempo é fisicamente impossível:
  // fio rompido, chave travada ou ligação trocada.
  if (e.fimAberta && e.fimFechada && _estado != EstadoPorta::FALHA) {
    entrarFalha(FalhaPorta::FIM_DUPLO, agora);
  }

  switch (_estado) {
    case EstadoPorta::ABRINDO:
      if (e.fimAberta) {
        pararMotor(agora);
        definirEstado(EstadoPorta::ABERTA);
      } else if (passou(agora, _inicioCurso, _cfg.tempoMaxCurso)) {
        entrarFalha(FalhaPorta::TIMEOUT_ABRIR, agora);
      } else {
        verificarFimPreso(agora, e.fimFechada);
      }
      break;

    case EstadoPorta::RECUANDO:
      if (_recuoAguardando) {
        // Espera o freio terminar e a pausa passar; depois reabre.
        if (_acao == AcaoMotor::PARADO && passou(agora, _inicioPausaRecuo, _cfg.pausaObstaculo)) {
          _recuoAguardando = false;
          ligarMotor(Sentido::SUBIR, _cfg.pwmAbrir, agora);
          _inicioCurso = agora;
        }
      } else if (e.fimAberta) {
        pararMotor(agora);
        definirEstado(EstadoPorta::ABERTA);
      } else if (passou(agora, _inicioCurso, _cfg.tempoMaxCurso)) {
        entrarFalha(FalhaPorta::TIMEOUT_ABRIR, agora);
      }
      break;

    case EstadoPorta::FECHANDO:
      if (e.fimFechada) {
        pararMotor(agora);
        definirEstado(EstadoPorta::FECHADA);
      } else if (e.obstaculo) {
        // PARADA AUTOMÁTICA: decidida aqui, no ESP32, sem depender do app.
        _flagObstaculo = true;
        pararMotor(agora);
        _verificarPartida = false;
        if (_cfg.recuarAposObstaculo) {
          _recuoAguardando = true;
          _inicioPausaRecuo = agora;
          definirEstado(EstadoPorta::RECUANDO);
        } else {
          definirEstado(EstadoPorta::PARADA);
        }
      } else if (passou(agora, _inicioCurso, _cfg.tempoMaxCurso)) {
        entrarFalha(FalhaPorta::TIMEOUT_FECHAR, agora);
      } else {
        verificarFimPreso(agora, e.fimAberta);
      }
      break;

    case EstadoPorta::AJUSTE: {
      bool terminou = passou(agora, _jogInicio, _jogDuracao) ||
                      (_jogSobe && e.fimAberta) ||
                      (!_jogSobe && (e.fimFechada || e.obstaculo));
      if (terminou) {
        pararMotor(agora);
        definirEstado(_estadoAntesAjuste == EstadoPorta::FALHA ? EstadoPorta::FALHA
                                                               : estadoPelasChaves());
      }
      break;
    }

    case EstadoPorta::ABERTA:
    case EstadoPorta::FECHADA:
    case EstadoPorta::PARADA: {
      // Porta movida com a mão ou escorregou: acompanha as chaves.
      EstadoPorta n = estadoPelasChaves();
      if (n != _estado) definirEstado(n);
      break;
    }

    case EstadoPorta::FALHA:
      break;
  }

  atualizarMotor(agora);
}
