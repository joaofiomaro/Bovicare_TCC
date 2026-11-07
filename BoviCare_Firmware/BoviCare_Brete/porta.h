// =====================================================================
//  BoviCare - Brete automatizado
//  porta.h  ->  máquina de estados de UMA porta guilhotina   (LÓGICA PURA)
//
//  A porta não conhece pinos nem o L298N: recebe as entradas filtradas
//  e decide a ação do motor (acao() + pwm()). Isso permite testar toda
//  a lógica no computador (pasta testes_nativos).
//
//         ABRIR                      fim "aberta"
//  FECHADA ──────► ABRINDO ─────────────────────► ABERTA
//     ▲               │ PARAR                         │ FECHAR
//     │ fim "fechada" ▼                               ▼
//     └────────── FECHANDO ◄──── PARADA ◄──PARAR── FECHANDO
//                     │ obstáculo (IR)
//                     ▼
//                  RECUANDO (freia, pausa e reabre) ──► ABERTA
//  Qualquer estado ──(tempo excedido / chave presa / fim duplo)──► FALHA
// =====================================================================
#pragma once
#include "tipos.h"

ConfigPorta configPortaPadrao();

class Porta {
 public:
  // Define o estado inicial a partir das chaves. Motor sempre parado.
  void iniciar(const ConfigPorta& cfg, const EntradasPorta& e, uint32_t agora);

  // Comandos
  Resultado abrir(uint32_t agora);
  Resultado fechar(uint32_t agora);
  void      parar(uint32_t agora);
  void      limparFalha(uint32_t agora);
  Resultado jog(bool subir, uint32_t duracaoMs, uint32_t agora);

  // Deve ser chamada a cada volta do laço principal
  void atualizar(const EntradasPorta& e, uint32_t agora);

  // Saídas para o driver
  AcaoMotor acao() const { return _acao; }
  uint8_t   pwm() const { return _pwm; }

  // Consulta
  EstadoPorta estado() const { return _estado; }
  FalhaPorta  falha() const { return _falha; }
  const EntradasPorta& entradas() const { return _e; }
  bool emMovimento() const;

  // Sinalizações (cada uma é consumida ao ser lida)
  bool consumirMudancaEstado() { bool r = _flagEstado; _flagEstado = false; return r; }
  bool consumirObstaculo()     { bool r = _flagObstaculo; _flagObstaculo = false; return r; }
  bool consumirFalha()         { bool r = _flagFalha; _flagFalha = false; return r; }

 private:
  enum class Sentido : uint8_t { NENHUM, SUBIR, DESCER };

  void definirEstado(EstadoPorta novo);
  void entrarFalha(FalhaPorta f, uint32_t agora);
  void comandarMotor(Sentido s, uint8_t pwmAlvo, uint32_t agora);
  void ligarMotor(Sentido s, uint8_t pwmAlvo, uint32_t agora);
  void pararMotor(uint32_t agora);
  EstadoPorta estadoPelasChaves() const;
  void atualizarMotor(uint32_t agora);
  void verificarFimPreso(uint32_t agora, bool chaveDePartidaAtiva);

  ConfigPorta   _cfg{};
  EntradasPorta _e{};
  EstadoPorta   _estado = EstadoPorta::PARADA;
  EstadoPorta   _estadoAntesAjuste = EstadoPorta::PARADA;
  FalhaPorta    _falha = FalhaPorta::NENHUMA;

  // Motor
  AcaoMotor _acao = AcaoMotor::PARADO;
  uint8_t   _pwm = 0;
  uint8_t   _pwmAlvo = 0;
  uint32_t  _inicioMotor = 0;      // instante em que o motor arrancou
  uint32_t  _inicioFreio = 0;
  Sentido   _pendente = Sentido::NENHUM;   // sentido a ligar após o freio
  uint8_t   _pwmPendente = 0;

  // Curso
  uint32_t _inicioCurso = 0;          // para o tempo máximo de curso
  bool     _verificarPartida = false; // checar se a chave de partida soltou

  // Recuo após obstáculo
  bool     _recuoAguardando = false;
  uint32_t _inicioPausaRecuo = 0;

  // Ajuste (JOG)
  bool     _jogSobe = true;
  uint32_t _jogDuracao = 0;
  uint32_t _jogInicio = 0;

  // Sinalizações
  bool _flagEstado = false;
  bool _flagObstaculo = false;
  bool _flagFalha = false;
};
