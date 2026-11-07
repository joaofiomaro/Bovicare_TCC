// =====================================================================
//  BoviCare - testes automáticos da lógica do firmware (rodam no PC)
//
//  Testa os módulos de LÓGICA PURA exatamente como vão para o ESP32:
//  debounce.h, porta.cpp, controlador.cpp e protocolo.cpp.
//  Uso: bash rodar_testes.sh
// =====================================================================
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>
#include "debounce.h"
#include "porta.h"
#include "controlador.h"
#include "protocolo.h"
#include "parametros.h"
#include "limiar.h"

static int g_ok = 0, g_falhas = 0;
#define VERIFICA(cond, msg)                                                  \
  do {                                                                       \
    if (cond) g_ok++;                                                        \
    else { g_falhas++; printf("  FALHOU: %s  (linha %d)\n", msg, __LINE__); } \
  } while (0)

static void secao(const char* nome) { printf("- %s\n", nome); }

// ---------------------------------------------------------------------
// Bancada de UMA porta (entradas manipuladas pelo teste)
// ---------------------------------------------------------------------
struct BancadaPorta {
  Porta p;
  EntradasPorta e;
  uint32_t t;
  explicit BancadaPorta(uint32_t inicio = 1000, bool fechada = true, bool aberta = false,
                        ConfigPorta cfg = configPortaPadrao()) {
    t = inicio;
    e.fimFechada = fechada;
    e.fimAberta = aberta;
    p.iniciar(cfg, e, t);
  }
  void passo(uint32_t ms) {
    for (uint32_t i = 0; i < ms; i++) { t++; p.atualizar(e, t); }
  }
};

// =====================================================================
static void testarDebounce() {
  secao("Debounce");
  Debounce d;
  d.configurar(20, 20, false, 0);
  VERIFICA(!d.estado(), "estado inicial preservado");
  VERIFICA(!d.atualizar(true, 5), "nao muda antes do tempo");
  VERIFICA(!d.atualizar(true, 24), "ainda nao muda com 19 ms");
  VERIFICA(d.atualizar(true, 25), "muda com 20 ms estavel");
  VERIFICA(d.estado(), "estado ativo");

  // Pulso curto (ruído) é rejeitado
  d.configurar(20, 20, false, 100);
  d.atualizar(true, 101);
  d.atualizar(false, 110);
  d.atualizar(false, 140);
  VERIFICA(!d.estado(), "ruido de 9 ms rejeitado");

  // Assimétrico: ativa rápido, libera devagar (sensor IR)
  Debounce ir;
  ir.configurar(P_IR_CONFIRMA_MS, P_IR_LIBERA_MS, false, 0);
  ir.atualizar(true, 1);
  ir.atualizar(true, 1 + P_IR_CONFIRMA_MS);
  VERIFICA(ir.estado(), "IR confirma obstaculo em P_IR_CONFIRMA_MS");
  ir.atualizar(false, 50);
  ir.atualizar(false, 50 + P_IR_LIBERA_MS - 1);
  VERIFICA(ir.estado(), "IR continua ocupado antes de P_IR_LIBERA_MS");
  ir.atualizar(false, 50 + P_IR_LIBERA_MS);
  VERIFICA(!ir.estado(), "IR libera apos P_IR_LIBERA_MS");

  // Virada do millis()
  Debounce w;
  w.configurar(20, 20, false, 0xFFFFFFF0u);
  w.atualizar(true, 0xFFFFFFF5u);
  w.atualizar(true, 0x00000005u);   // 16 ms depois
  VERIFICA(!w.estado(), "virada do millis: ainda nao");
  w.atualizar(true, 0x00000009u);   // 20 ms depois
  VERIFICA(w.estado(), "virada do millis: muda no tempo certo");
}

// =====================================================================
static void testarPortaBasico() {
  secao("Porta: inicializacao e ciclo abrir/fechar");
  {
    BancadaPorta b(1000, true, false);
    VERIFICA(b.p.estado() == EstadoPorta::FECHADA, "inicia FECHADA pela chave");
    VERIFICA(b.p.acao() == AcaoMotor::PARADO, "motor parado no boot");
  }
  {
    BancadaPorta b(1000, false, true);
    VERIFICA(b.p.estado() == EstadoPorta::ABERTA, "inicia ABERTA pela chave");
  }
  {
    BancadaPorta b(1000, false, false);
    VERIFICA(b.p.estado() == EstadoPorta::PARADA, "sem chave: PARADA");
  }
  {
    BancadaPorta b(1000, true, true);
    VERIFICA(b.p.estado() == EstadoPorta::FALHA, "duas chaves no boot: FALHA");
    VERIFICA(b.p.falha() == FalhaPorta::FIM_DUPLO, "falha FIM_DUPLO");
    VERIFICA(b.p.consumirFalha(), "sinaliza falha no boot");
  }

  BancadaPorta b;
  VERIFICA(b.p.abrir(b.t) == Resultado::OK, "abrir aceito");
  VERIFICA(b.p.estado() == EstadoPorta::ABRINDO, "estado ABRINDO");
  VERIFICA(b.p.acao() == AcaoMotor::SUBIR, "motor SUBIR");
  VERIFICA(b.p.pwm() == P_PWM_PARTIDA, "rampa comeca no PWM de partida");
  b.passo(P_RAMPA_MS / 2);
  VERIFICA(b.p.pwm() > P_PWM_PARTIDA && b.p.pwm() < P_PWM_ABRIR, "rampa intermediaria");
  b.e.fimFechada = false;
  b.passo(P_RAMPA_MS);
  VERIFICA(b.p.pwm() == P_PWM_ABRIR, "rampa chega ao PWM de abrir");
  VERIFICA(b.p.abrir(b.t) == Resultado::OK, "abrir de novo enquanto abre: OK");
  b.e.fimAberta = true;
  b.passo(1);
  VERIFICA(b.p.estado() == EstadoPorta::ABERTA, "chave aberta: ABERTA");
  VERIFICA(b.p.acao() == AcaoMotor::FREAR, "freio dinamico ao chegar");
  b.passo(P_FREIO_MS);
  VERIFICA(b.p.acao() == AcaoMotor::PARADO, "motor solto apos o freio");
  VERIFICA(b.p.pwm() == 0, "PWM zero parado");
  VERIFICA(b.p.abrir(b.t) == Resultado::JA_ABERTA, "abrir com porta aberta: JA_ABERTA");

  VERIFICA(b.p.fechar(b.t) == Resultado::OK, "fechar aceito");
  VERIFICA(b.p.acao() == AcaoMotor::DESCER, "motor DESCER");
  b.passo(P_RAMPA_MS + 5);
  VERIFICA(b.p.pwm() == P_PWM_FECHAR, "PWM de fechar");
  b.e.fimAberta = false;
  b.passo(500);
  b.e.fimFechada = true;
  b.passo(1);
  VERIFICA(b.p.estado() == EstadoPorta::FECHADA, "chave fechada: FECHADA");
  VERIFICA(b.p.fechar(b.t) == Resultado::JA_FECHADA, "JA_FECHADA");
}

// =====================================================================
static void testarObstaculo() {
  secao("Porta: parada automatica por presenca (fail-safe)");
  BancadaPorta b(1000, false, true);
  b.p.fechar(b.t);
  b.passo(50);
  b.e.fimAberta = false;
  b.passo(300);
  b.e.obstaculo = true;
  b.passo(1);
  VERIFICA(b.p.consumirObstaculo(), "sinaliza OBSTACULO");
  VERIFICA(b.p.estado() == EstadoPorta::RECUANDO, "estado RECUANDO");
  VERIFICA(b.p.acao() == AcaoMotor::FREAR, "freia no mesmo ciclo (< 1 ms)");
  b.passo(P_FREIO_MS);
  VERIFICA(b.p.acao() == AcaoMotor::PARADO, "parado durante a pausa");
  b.passo(P_PAUSA_OBSTACULO_MS - P_FREIO_MS - 2);
  VERIFICA(b.p.acao() == AcaoMotor::PARADO, "ainda em pausa");
  b.passo(3);
  VERIFICA(b.p.acao() == AcaoMotor::SUBIR, "reabre apos a pausa");
  b.e.fimAberta = true;
  b.passo(1);
  VERIFICA(b.p.estado() == EstadoPorta::ABERTA, "termina ABERTA");

  VERIFICA(b.p.fechar(b.t) == Resultado::OBSTACULO, "com obstaculo nao comeca a fechar");
  VERIFICA(b.p.acao() != AcaoMotor::DESCER, "motor nao desce");
  b.e.obstaculo = false;
  b.passo(P_FREIO_MS + 5);
  VERIFICA(b.p.fechar(b.t) == Resultado::OK, "feixe livre: fecha");

  // Sem recuo (P_RECUAR_APOS_OBSTACULO = 0)
  ConfigPorta c = configPortaPadrao();
  c.recuarAposObstaculo = false;
  BancadaPorta s(1000, false, true, c);
  s.p.fechar(s.t);
  s.e.fimAberta = false;
  s.passo(200);
  s.e.obstaculo = true;
  s.passo(1);
  VERIFICA(s.p.estado() == EstadoPorta::PARADA, "sem recuo: apenas PARADA");
  s.passo(1000);
  VERIFICA(s.p.acao() == AcaoMotor::PARADO, "sem recuo: motor continua parado");

  // Obstáculo durante a ABERTURA não interrompe (subir é seguro)
  BancadaPorta a;
  a.p.abrir(a.t);
  a.e.fimFechada = false;
  a.passo(100);
  a.e.obstaculo = true;
  a.passo(10);
  VERIFICA(a.p.estado() == EstadoPorta::ABRINDO && a.p.acao() == AcaoMotor::SUBIR,
           "obstaculo na abertura: continua abrindo");
}

// =====================================================================
static void testarFalhas() {
  secao("Porta: falhas e tempos-limite");
  {
    BancadaPorta b;
    b.p.abrir(b.t);
    b.e.fimFechada = false;
    b.passo(P_TEMPO_MAX_CURSO_MS - 2);
    VERIFICA(b.p.estado() == EstadoPorta::ABRINDO, "ainda abrindo antes do limite");
    b.passo(3);
    VERIFICA(b.p.estado() == EstadoPorta::FALHA, "tempo excedido: FALHA");
    VERIFICA(b.p.falha() == FalhaPorta::TIMEOUT_ABRIR, "TIMEOUT_ABRIR");
    VERIFICA(b.p.acao() == AcaoMotor::FREAR, "motor freado na falha");
    b.passo(P_FREIO_MS);
    VERIFICA(b.p.acao() == AcaoMotor::PARADO, "motor desligado na falha");
    VERIFICA(b.p.abrir(b.t) == Resultado::FALHA, "porta em falha recusa abrir");
    VERIFICA(b.p.fechar(b.t) == Resultado::FALHA, "porta em falha recusa fechar");
    b.p.limparFalha(b.t);
    VERIFICA(b.p.estado() == EstadoPorta::PARADA, "RESET: estado pelas chaves");
  }
  {
    BancadaPorta b(1000, false, true);
    b.p.fechar(b.t);
    b.e.fimAberta = false;
    b.passo(P_TEMPO_MAX_CURSO_MS + 1);
    VERIFICA(b.p.falha() == FalhaPorta::TIMEOUT_FECHAR, "TIMEOUT_FECHAR");
  }
  {
    BancadaPorta b;               // chave "fechada" não solta: chave presa
    b.p.abrir(b.t);
    b.passo(P_FIM_PRESO_MS - 2);
    VERIFICA(b.p.estado() == EstadoPorta::ABRINDO, "chave presa: ainda dentro do prazo");
    b.passo(3);
    VERIFICA(b.p.falha() == FalhaPorta::FIM_PRESO, "FIM_PRESO");
  }
  {
    BancadaPorta b;               // chave solta a tempo: sem falha
    b.p.abrir(b.t);
    b.passo(P_FIM_PRESO_MS - 100);
    b.e.fimFechada = false;
    b.passo(500);
    VERIFICA(b.p.estado() == EstadoPorta::ABRINDO, "chave soltou a tempo: sem falha");
  }
  {
    BancadaPorta b;
    b.p.abrir(b.t);
    b.e.fimFechada = false;
    b.passo(100);
    b.e.fimAberta = true;
    b.e.fimFechada = true;
    b.passo(1);
    VERIFICA(b.p.falha() == FalhaPorta::FIM_DUPLO, "duas chaves em movimento: FIM_DUPLO");
    b.p.limparFalha(b.t);
    VERIFICA(b.p.estado() == EstadoPorta::FALHA, "RESET com as duas chaves: continua em falha");
  }
  {
    // Virada do millis() durante o curso
    BancadaPorta b(0xFFFFFF00u);
    b.p.abrir(b.t);
    b.e.fimFechada = false;
    b.passo(P_TEMPO_MAX_CURSO_MS - 10);
    VERIFICA(b.p.estado() == EstadoPorta::ABRINDO, "virada do millis: sem falso timeout");
    b.passo(20);
    VERIFICA(b.p.falha() == FalhaPorta::TIMEOUT_ABRIR, "virada do millis: timeout no tempo certo");
  }
}

// =====================================================================
static void testarParadaEInversao() {
  secao("Porta: parar, inverter sentido e movimento manual");
  BancadaPorta b;
  b.p.abrir(b.t);
  b.e.fimFechada = false;
  b.passo(400);
  b.p.parar(b.t);
  VERIFICA(b.p.estado() == EstadoPorta::PARADA, "PARAR no meio: PARADA");
  VERIFICA(b.p.acao() == AcaoMotor::FREAR, "PARAR freia");

  b.p.abrir(b.t);
  b.passo(400);
  VERIFICA(b.p.fechar(b.t) == Resultado::OK, "fechar durante a abertura");
  VERIFICA(b.p.acao() == AcaoMotor::FREAR, "inversao: freia primeiro");
  b.passo(P_FREIO_MS - 1);
  VERIFICA(b.p.acao() == AcaoMotor::FREAR, "inversao: ainda freando");
  b.passo(1);
  VERIFICA(b.p.acao() == AcaoMotor::DESCER, "inversao: depois desce");
  VERIFICA(b.p.estado() == EstadoPorta::FECHANDO, "inversao: FECHANDO");

  BancadaPorta m(1000, true, false);
  m.e.fimFechada = false;
  m.passo(1);
  VERIFICA(m.p.estado() == EstadoPorta::PARADA, "porta erguida a mao: PARADA");
  m.e.fimAberta = true;
  m.passo(1);
  VERIFICA(m.p.estado() == EstadoPorta::ABERTA, "erguida ate o fim: ABERTA");
  VERIFICA(m.p.acao() == AcaoMotor::PARADO, "movimento manual nao liga motor");
}

// =====================================================================
static void testarJog() {
  secao("Porta: ajuste (JOG)");
  BancadaPorta b(1000, false, false);
  VERIFICA(b.p.jog(true, 300, b.t) == Resultado::OK, "JOG aceito");
  VERIFICA(b.p.estado() == EstadoPorta::AJUSTE, "estado AJUSTE");
  VERIFICA(b.p.acao() == AcaoMotor::SUBIR, "JOG sobe");
  VERIFICA(b.p.abrir(b.t) == Resultado::NAO_PERMITIDO, "abrir durante o JOG: recusado");
  VERIFICA(b.p.jog(true, 100, b.t) == Resultado::NAO_PERMITIDO, "JOG em andamento: recusado");
  b.passo(300);
  VERIFICA(b.p.estado() == EstadoPorta::PARADA, "JOG termina no tempo");
  VERIFICA(b.p.acao() == AcaoMotor::FREAR, "JOG freia ao terminar");

  b.passo(P_FREIO_MS);
  b.p.jog(true, 60000, b.t);
  b.passo(P_JOG_MAX_MS + 1);
  VERIFICA(b.p.estado() != EstadoPorta::AJUSTE, "JOG limitado a P_JOG_MAX_MS");

  b.passo(P_FREIO_MS);
  b.p.jog(true, 800, b.t);
  b.passo(100);
  b.e.fimAberta = true;
  b.passo(1);
  VERIFICA(b.p.estado() == EstadoPorta::ABERTA, "JOG para no fim de curso");
  VERIFICA(b.p.jog(true, 100, b.t) == Resultado::FIM_DE_CURSO, "JOG contra o fim: recusado");
  b.e.obstaculo = true;
  b.passo(1);
  VERIFICA(b.p.jog(false, 100, b.t) == Resultado::OBSTACULO, "JOG descendo com obstaculo: recusado");
  VERIFICA(b.p.jog(false, 0, b.t) == Resultado::INVALIDO, "JOG de 0 ms: invalido");
}

// =====================================================================
// Controlador
// =====================================================================
struct BancadaSistema {
  Controlador c;
  EntradasSistema e;
  uint32_t t = 5000;
  BancadaSistema(bool p1Fechada = true, bool p2Fechada = true, bool paradaNoBoot = false,
                 bool botao1NoBoot = false) {
    e.porta[0].fimFechada = p1Fechada;
    e.porta[0].fimAberta = !p1Fechada;
    e.porta[1].fimFechada = p2Fechada;
    e.porta[1].fimAberta = !p2Fechada;
    e.botaoParada = paradaNoBoot;
    e.botao1 = botao1NoBoot;
    c.iniciar(configPortaPadrao(), e, t, true, P_REARME_MS);
  }
  void passo(uint32_t ms) {
    for (uint32_t i = 0; i < ms; i++) { t++; c.atualizar(e, t); }
  }
  Resultado cmd(const char* txt, Origem o = Origem::APP) {
    Comando k;
    interpretarComando(txt, k);
    return c.executar(k, o, t);
  }
  std::vector<Evento> eventos() {
    std::vector<Evento> v;
    Evento ev;
    while (c.proximoEvento(ev)) v.push_back(ev);
    return v;
  }
};

static bool temEvento(const std::vector<Evento>& v, TipoEvento tipo) {
  for (const Evento& ev : v) if (ev.tipo == tipo) return true;
  return false;
}

static void testarIntertravamento() {
  secao("Controlador: intertravamento das portas");
  BancadaSistema s(true, false);       // porta 2 aberta
  VERIFICA(s.cmd("ABRIR 1") == Resultado::INTERTRAVAMENTO, "porta 2 aberta: nao abre a 1");
  VERIFICA(s.c.porta(0).acao() == AcaoMotor::PARADO, "motor 1 nao liga");
  BancadaSistema t(true, true);
  VERIFICA(t.cmd("ABRIR 1") == Resultado::OK, "as duas fechadas: abre a 1");
  VERIFICA(t.cmd("ABRIR 2") == Resultado::INTERTRAVAMENTO, "porta 1 abrindo: nao abre a 2");
  VERIFICA(t.cmd("FECHAR 2") == Resultado::JA_FECHADA, "fechar e sempre permitido");
}

static void testarEmergencia() {
  secao("Controlador: parada manual, emergencia e rearme");
  BancadaSistema s;
  s.cmd("ABRIR 1");
  s.e.porta[0].fimFechada = false;
  s.passo(200);
  s.eventos();
  s.e.botaoParada = true;           // aperta a parada
  s.passo(1);
  VERIFICA(s.c.emergencia(), "botao: emergencia ativa");
  VERIFICA(s.c.porta(0).acao() == AcaoMotor::FREAR, "motor freia na emergencia");
  auto ev = s.eventos();
  VERIFICA(temEvento(ev, TipoEvento::EMERGENCIA), "evento EMERGENCIA");
  VERIFICA(s.cmd("ABRIR 1") == Resultado::EMERGENCIA, "comando recusado em emergencia");
  VERIFICA(s.cmd("PARAR") == Resultado::OK, "PARAR aceito em emergencia");
  VERIFICA(s.cmd("STATUS") == Resultado::OK, "STATUS aceito em emergencia");

  s.passo(P_REARME_MS + 100);       // segura o MESMO aperto: não rearma
  VERIFICA(s.c.emergencia(), "segurar o mesmo aperto nao rearma");
  s.e.botaoParada = false;
  s.passo(50);
  s.e.botaoParada = true;           // novo aperto
  s.passo(P_REARME_MS - 10);
  VERIFICA(s.c.emergencia(), "menos de 3 s: continua em emergencia");
  s.passo(20);
  VERIFICA(!s.c.emergencia(), "segurar 3 s apos soltar: rearma");
  ev = s.eventos();
  VERIFICA(temEvento(ev, TipoEvento::REARME), "evento REARME");
  s.e.botaoParada = false;
  s.passo(50);
  VERIFICA(!s.c.emergencia(), "soltar apos rearmar nao dispara de novo");

  // Emergência e RESET pelo app
  VERIFICA(s.cmd("EMERGENCIA") == Resultado::OK, "EMERGENCIA pelo app");
  VERIFICA(s.c.emergencia(), "emergencia ativa (app)");
  VERIFICA(s.c.origemEmergencia() == Origem::APP, "origem APP");
  VERIFICA(s.cmd("RESET") == Resultado::OK, "RESET pelo app");
  VERIFICA(!s.c.emergencia(), "RESET rearma");

  // Parada pressionada no boot
  BancadaSistema b(true, true, true);
  VERIFICA(b.c.emergencia(), "parada no boot: emergencia");
  b.e.botaoParada = false;
  b.passo(50);
  b.e.botaoParada = true;
  b.passo(P_REARME_MS + 1);
  VERIFICA(!b.c.emergencia(), "parada no boot: rearme pelo procedimento normal");
}

static void testarBotoes() {
  secao("Controlador: botoes fisicos");
  BancadaSistema s;
  s.e.botao1 = true;
  s.passo(1);
  VERIFICA(s.c.porta(0).estado() == EstadoPorta::ABRINDO, "botao 1: abre a porta 1");
  s.e.botao1 = false;
  s.passo(100);
  s.e.botao1 = true;
  s.passo(1);
  VERIFICA(s.c.porta(0).estado() == EstadoPorta::FECHADA ||
           s.c.porta(0).estado() == EstadoPorta::PARADA, "botao 1 em movimento: para");
  s.e.botao1 = false;
  s.passo(200);

  BancadaSistema a(false, true);       // porta 1 aberta
  a.e.botao1 = true;
  a.passo(1);
  VERIFICA(a.c.porta(0).estado() == EstadoPorta::FECHANDO, "botao 1 com porta aberta: fecha");

  BancadaSistema boot(true, true, false, true);   // botão 1 preso no boot
  boot.passo(100);
  VERIFICA(boot.c.porta(0).estado() == EstadoPorta::FECHADA, "botao pressionado no boot: ignorado");
  boot.e.botao1 = false;
  boot.passo(50);
  boot.e.botao1 = true;
  boot.passo(1);
  VERIFICA(boot.c.porta(0).estado() == EstadoPorta::ABRINDO, "depois de soltar, funciona");

  BancadaSistema em;
  em.cmd("EMERGENCIA");
  em.eventos();
  em.e.botao2 = true;
  em.passo(1);
  auto ev = em.eventos();
  bool respEmerg = false;
  for (auto& x : ev) if (x.tipo == TipoEvento::RESP && x.res == Resultado::EMERGENCIA) respEmerg = true;
  VERIFICA(respEmerg, "botao em emergencia: RESP EMERGENCIA");
  VERIFICA(em.c.porta(1).acao() == AcaoMotor::PARADO, "botao em emergencia: motor parado");
}

static void testarComandosEEventos() {
  secao("Controlador: comandos, respostas e eventos");
  BancadaSistema s;
  auto ev = s.eventos();
  VERIFICA(!ev.empty() && ev[0].tipo == TipoEvento::INICIO, "primeiro evento: INICIO");

  VERIFICA(s.cmd("JOG 1 SOBE 200", Origem::APP) == Resultado::NAO_PERMITIDO, "JOG pelo app: NAO_PERMITIDO");
  VERIFICA(s.cmd("JOG 1 DESCE 200", Origem::SERIAL_USB) == Resultado::FIM_DE_CURSO,
           "JOG pela serial respeita o fim de curso");
  VERIFICA(s.cmd("JOG 1 SOBE 200", Origem::SERIAL_USB) == Resultado::OK, "JOG pela serial aceito");
  s.e.porta[0].fimFechada = false;
  s.passo(200 + P_FREIO_MS);
  s.e.porta[0].fimFechada = true;
  s.passo(1);
  VERIFICA(s.cmd("ABRIR") == Resultado::PORTA_INVALIDA, "ABRIR sem porta");
  VERIFICA(s.cmd("ABRIR 3") == Resultado::PORTA_INVALIDA, "porta 3 invalida");
  VERIFICA(s.cmd("VOAR 1") == Resultado::INVALIDO, "comando desconhecido");
  s.eventos();

  s.cmd("#17 ABRIR 1");
  ev = s.eventos();
  bool achou = false;
  for (auto& x : ev)
    if (x.tipo == TipoEvento::RESP && x.id == 17 && x.cmd == TipoComando::ABRIR &&
        x.res == Resultado::OK && x.porta == 1 && x.origem == Origem::APP) achou = true;
  VERIFICA(achou, "RESP leva id, comando, porta, resultado e origem");
  VERIFICA(temEvento(ev, TipoEvento::PORTA), "evento PORTA (ABRINDO)");

  // Fila cheia: descarta o mais antigo e conta
  BancadaSistema f;
  for (int i = 0; i < 40; i++) f.cmd("PING");
  VERIFICA(f.c.eventosPerdidos() > 0, "fila cheia conta eventos perdidos");
  int n = (int)f.eventos().size();
  VERIFICA(n == Controlador::CAPACIDADE_EVENTOS, "fila guarda a capacidade maxima");

  // RFID
  BancadaSistema r;
  r.eventos();
  r.c.rfidStatus(true);
  r.c.rfidLido("04a1b2c3\"<x>");
  VERIFICA(!strcmp(r.c.uidAtual(), "04A1B2C3"), "UID guardado em hexadecimal (sanitizado)");
  r.c.rfidSaiu();
  VERIFICA(r.c.uidAtual()[0] == 0, "tag saiu: UID limpo");
  ev = r.eventos();
  VERIFICA(ev.size() == 3 && ev[0].tipo == TipoEvento::RFID_OK && ev[1].tipo == TipoEvento::RFID &&
           ev[2].tipo == TipoEvento::RFID_SAIU && !strcmp(ev[2].uid, "04A1B2C3"),
           "eventos RFID_OK, RFID e RFID_SAIU com o UID");
}

// =====================================================================
// Protocolo
// =====================================================================
static void testarInterpretacao() {
  secao("Protocolo: interpretacao de comandos");
  Comando c;
  VERIFICA(!interpretarComando("", c), "linha vazia");
  VERIFICA(!interpretarComando("   \r\n", c), "so espacos");
  interpretarComando("abrir 1", c);
  VERIFICA(c.tipo == TipoComando::ABRIR && c.porta == 1, "minusculas");
  interpretarComando("FECHAR:2", c);
  VERIFICA(c.tipo == TipoComando::FECHAR && c.porta == 2, "separador ':'");
  interpretarComando("fechar=saida", c);
  VERIFICA(c.tipo == TipoComando::FECHAR && c.porta == 2, "SAIDA por extenso");
  interpretarComando("alternar,E", c);
  VERIFICA(c.tipo == TipoComando::ALTERNAR && c.porta == 1, "E = entrada");
  interpretarComando("#17 ABRIR 1", c);
  VERIFICA(c.id == 17 && c.tipo == TipoComando::ABRIR, "id #17");
  interpretarComando("#0 PING", c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "id 0 invalido");
  interpretarComando("#70000 PING", c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "id acima de 65535 invalido");
  interpretarComando("#5", c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "so o id: invalido");
  interpretarComando("PARAR", c);
  VERIFICA(c.tipo == TipoComando::PARAR && c.porta == 0, "PARAR sem porta = ambas");
  interpretarComando("ABRIR 9", c);
  VERIFICA(c.porta == -1, "porta 9 marcada invalida");
  interpretarComando("jog 2 desce 250", c);
  VERIFICA(c.tipo == TipoComando::JOG && c.porta == 2 && !c.jogSobe && c.jogMs == 250, "JOG completo");
  interpretarComando("JOG 1 SOBE", c);
  VERIFICA(c.tipo == TipoComando::JOG && c.jogSobe && c.jogMs == 300, "JOG com tempo padrao");
  interpretarComando("JOG 1 LADO 100", c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "JOG com sentido invalido");
  interpretarComando("JOG 1 SOBE abc", c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "JOG com tempo invalido");
  interpretarComando("xyz", c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "palavra desconhecida");
  interpretarComando("  ping  \r\n", c);
  VERIFICA(c.tipo == TipoComando::PING, "espacos e fim de linha");
  std::string longo(200, 'A');
  interpretarComando(longo.c_str(), c);
  VERIFICA(c.tipo == TipoComando::INVALIDO, "texto longo nao estoura o buffer");
}

static void testarJson(FILE* saida) {
  secao("Protocolo: JSON de estado e eventos");
  // Pior caso de tamanho do estado
  BancadaSistema s(false, false);
  s.e.porta[0].obstaculo = s.e.porta[1].obstaculo = true;
  s.e.porta[0].fimFechada = s.e.porta[1].fimFechada = true;   // + aberta: FIM_DUPLO
  s.e.botao1 = s.e.botao2 = s.e.botaoParada = true;
  s.passo(1);
  s.c.rfidStatus(true);
  s.c.rfidLido("0123456789ABCDEF0123");      // UID de 10 bytes
  char buf[400];
  size_t n = jsonEstado(s.c, 4294967295u, buf, sizeof(buf));
  fprintf(saida, "%s\n", buf);
  printf("  estado (pior caso): %zu bytes (limite %d)\n", n, JSON_ESTADO_MAX);
  VERIFICA(n <= JSON_ESTADO_MAX, "estado cabe numa notificacao BLE (MTU 185)");

  BancadaSistema t;
  n = jsonEstado(t.c, 12, buf, sizeof(buf));
  fprintf(saida, "%s\n", buf);
  VERIFICA(strstr(buf, "\"p1\":\"FECHADA\"") != nullptr, "estado contem p1");

  // Truncamento seguro
  char peq[20];
  n = jsonEstado(t.c, 12, peq, sizeof(peq));
  VERIFICA(n == sizeof(peq) - 1 && peq[sizeof(peq) - 1] == 0, "buffer pequeno: trunca com terminador");

  // Um exemplo de cada evento
  Evento ev;
  TipoEvento tipos[] = {TipoEvento::INICIO, TipoEvento::PORTA, TipoEvento::OBSTACULO,
                        TipoEvento::FALHA, TipoEvento::EMERGENCIA, TipoEvento::REARME,
                        TipoEvento::RESP, TipoEvento::RFID, TipoEvento::RFID_SAIU,
                        TipoEvento::RFID_OK, TipoEvento::RFID_ERRO};
  size_t maior = 0;
  for (TipoEvento tp : tipos) {
    ev = Evento();
    ev.tipo = tp;
    ev.porta = 2;
    ev.estado = EstadoPorta::RECUANDO;
    ev.falha = FalhaPorta::TIMEOUT_FECHAR;
    ev.ligado = true;
    ev.origem = Origem::SERIAL_USB;
    ev.cmd = TipoComando::EMERGENCIA;
    ev.res = Resultado::INTERTRAVAMENTO;
    ev.id = 65535;
    strcpy(ev.uid, "0123456789ABCDEF0123");
    n = jsonEvento(ev, buf, sizeof(buf));
    if (n > maior) maior = n;
    fprintf(saida, "%s\n", buf);
  }
  printf("  maior evento: %zu bytes (limite %d)\n", maior, JSON_EVENTO_MAX);
  VERIFICA(maior <= JSON_EVENTO_MAX, "eventos cabem no limite");
}

// =====================================================================
static void testarLimiarIr() {
  secao("Leitura analogica dos sensores IR (histerese)");
  const uint16_t O = P_IR_LIMIAR_OBSTACULO_MV, L = P_IR_LIMIAR_LIVRE_MV;
  VERIFICA(O < L, "limiar de obstaculo abaixo do limiar livre");
  VERIFICA(!irObstaculoPorTensao(1750, true, O, L), "1750 mV (medido sem obstaculo): livre");
  VERIFICA(irObstaculoPorTensao(0, false, O, L), "0 mV: obstaculo");
  VERIFICA(irObstaculoPorTensao(250, false, O, L), "250 mV: obstaculo");
  VERIFICA(irObstaculoPorTensao(900, true, O, L), "zona morta mantem obstaculo");
  VERIFICA(!irObstaculoPorTensao(900, false, O, L), "zona morta mantem livre");
  VERIFICA(irObstaculoPorTensao(O - 1, false, O, L), "logo abaixo do limiar: obstaculo");
  VERIFICA(!irObstaculoPorTensao(L + 1, true, O, L), "logo acima do limiar: livre");
  VERIFICA(!irObstaculoPorTensao(3000, true, O, L), "3000 mV (divisor com 10 k): livre");
  // Ruído de +-150 mV em torno de 1750 nunca vira obstáculo.
  bool e = false;
  for (int k = 0; k < 200; k++) e = irObstaculoPorTensao((uint16_t)(1750 + ((k % 7) - 3) * 50), e, O, L);
  VERIFICA(!e, "ruido em torno de 1750 mV nao gera obstaculo");
}

int main(int argc, char** argv) {
  const char* arqJson = argc > 1 ? argv[1] : "amostras_json.txt";
  FILE* f = fopen(arqJson, "w");
  if (!f) { printf("nao foi possivel criar %s\n", arqJson); return 2; }

  printf("BoviCare - testes da logica do firmware %s\n", FIRMWARE_VERSAO);
  testarDebounce();
  testarLimiarIr();
  testarPortaBasico();
  testarObstaculo();
  testarFalhas();
  testarParadaEInversao();
  testarJog();
  testarIntertravamento();
  testarEmergencia();
  testarBotoes();
  testarComandosEEventos();
  testarInterpretacao();
  testarJson(f);
  fclose(f);

  printf("\nResultado: %d verificacoes OK, %d falhas\n", g_ok, g_falhas);
  return g_falhas == 0 ? 0 : 1;
}
