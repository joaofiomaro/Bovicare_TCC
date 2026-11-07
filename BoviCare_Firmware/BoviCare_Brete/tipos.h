// =====================================================================
//  BoviCare - Brete automatizado
//  tipos.h  ->  tipos compartilhados entre os módulos   (LÓGICA PURA)
// =====================================================================
#pragma once
#include <stdint.h>
#include <stddef.h>

// Estado de UMA porta guilhotina
enum class EstadoPorta : uint8_t {
  FECHADA,     // chave "fechada" acionada, motor parado
  ABRINDO,     // motor subindo a porta
  ABERTA,      // chave "aberta" acionada, motor parado
  FECHANDO,    // motor descendo a porta
  PARADA,      // parada no meio do curso
  RECUANDO,    // obstáculo no fechamento: freia, pausa e reabre
  AJUSTE,      // movimento curto de manutenção (JOG, só pela serial)
  FALHA        // bloqueada até RESET
};

enum class FalhaPorta : uint8_t {
  NENHUMA,
  TIMEOUT_ABRIR,    // não chegou ao fim "aberta" no tempo máximo
  TIMEOUT_FECHAR,   // não chegou ao fim "fechada" no tempo máximo
  FIM_DUPLO,        // as duas chaves da mesma porta acionadas
  FIM_PRESO         // a chave de partida não soltou após o motor arrancar
};

// O que o driver deve fazer com o motor
enum class AcaoMotor : uint8_t { PARADO, SUBIR, DESCER, FREAR };

enum class Resultado : uint8_t {
  OK,
  JA_ABERTA,
  JA_FECHADA,
  OBSTACULO,
  FALHA,
  EMERGENCIA,
  INTERTRAVAMENTO,
  NAO_PERMITIDO,
  INVALIDO,
  PORTA_INVALIDA,
  FIM_DE_CURSO
};

enum class TipoComando : uint8_t {
  NENHUM, ABRIR, FECHAR, ALTERNAR, PARAR, EMERGENCIA, RESET,
  STATUS, PING, DIAG, AJUDA, JOG, INVALIDO
};

enum class Origem : uint8_t { BOTAO, APP, SERIAL_USB, SISTEMA };

struct Comando {
  TipoComando tipo = TipoComando::NENHUM;
  int8_t      porta = 0;      // 0 = não informada / ambas, 1, 2, -1 = inválida
  uint16_t    id = 0;         // 0 = sem id
  bool        jogSobe = true;
  uint16_t    jogMs = 0;
};

// Entradas JÁ FILTRADAS de uma porta (true = ativo)
struct EntradasPorta {
  bool fimAberta = false;
  bool fimFechada = false;
  bool obstaculo = false;
};

// Entradas filtradas do sistema inteiro
struct EntradasSistema {
  EntradasPorta porta[2];
  bool botao1 = false;
  bool botao2 = false;
  bool botaoParada = false;
};

// Configuração da máquina de estados de uma porta
struct ConfigPorta {
  uint32_t tempoMaxCurso;
  uint32_t fimPreso;
  uint32_t rampa;
  uint32_t freio;
  uint32_t pausaObstaculo;
  uint32_t jogMax;
  uint8_t  pwmAbrir;
  uint8_t  pwmFechar;
  uint8_t  pwmPartida;
  uint8_t  pwmJog;
  bool     recuarAposObstaculo;
};

enum class TipoEvento : uint8_t {
  INICIO, PORTA, OBSTACULO, FALHA, EMERGENCIA, REARME, RESP,
  RFID, RFID_SAIU, RFID_OK, RFID_ERRO
};

#define UID_MAX_CHARS 21   // 10 bytes em hexadecimal + terminador

struct Evento {
  TipoEvento  tipo = TipoEvento::INICIO;
  uint8_t     porta = 0;                 // 1 ou 2 (0 = não se aplica)
  EstadoPorta estado = EstadoPorta::FECHADA;
  FalhaPorta  falha = FalhaPorta::NENHUMA;
  bool        ligado = false;            // EMERGENCIA on/off
  Origem      origem = Origem::SISTEMA;
  TipoComando cmd = TipoComando::NENHUM;
  Resultado   res = Resultado::OK;
  uint16_t    id = 0;
  char        uid[UID_MAX_CHARS] = {0};
};
