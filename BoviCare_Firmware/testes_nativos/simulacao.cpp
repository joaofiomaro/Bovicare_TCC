// =====================================================================
//  BoviCare - simulação física do brete (roda no PC)
//
//  Liga a lógica REAL do firmware (Debounce + Controlador + Portas) a um
//  modelo simples da maquete: cada porta é movida pela corda enrolada no
//  carretel, com velocidade proporcional ao PWM, e as chaves de fim de
//  curso / sensores IR são gerados a partir da posição.
//
//  Modelo: curso de 300 mm; carretel de 16 mm (~50 mm por volta);
//  JGB37-3530 200 RPM com carga ~ 170 RPM -> ~140 mm/s com PWM 255.
//  Passo de simulação: 1 ms (o laço do firmware roda a ~1 kHz).
// =====================================================================
#include <cstdio>
#include <cstring>
#include <functional>
#include "debounce.h"
#include "controlador.h"
#include "protocolo.h"
#include "parametros.h"

static int g_ok = 0, g_falhas = 0;
#define VERIFICA(cond, msg)                                                   \
  do {                                                                        \
    if (cond) g_ok++;                                                         \
    else { g_falhas++; printf("    FALHOU: %s  (linha %d)\n", msg, __LINE__); } \
  } while (0)

const double CURSO_MM = 300.0;
const double VEL_MAX_MM_S = 140.0;   // PWM 255
const int    PWM_MIN_GIRO = 60;      // abaixo disso o motor não vence o atrito

struct PortaFisica {
  double pos = 0;                 // 0 = fechada, CURSO_MM = aberta
  bool cordaPartida = false;
  double travaEm = -1;            // trava ao subir nesta posição (-1 = livre)
};

struct Simulador {
  Controlador ctl;
  Debounce dbFimA[2], dbFimF[2], dbIr[2], dbB1, dbB2, dbPar;
  PortaFisica fis[2];
  bool irBruto[2] = {false, false};
  bool b1 = false, b2 = false, parada = false;
  uint32_t t = 0;
  uint32_t reacaoInicio = 0, reacaoFim = 0;
  int eventosObstaculo = 0;
  std::function<void(Simulador&)> roteiro;

  void brutas(bool fa[2], bool ff[2]) {
    for (int i = 0; i < 2; i++) {
      ff[i] = fis[i].pos <= 2.0;
      fa[i] = fis[i].pos >= CURSO_MM - 2.0;
    }
  }

  void iniciar(double pos1, double pos2) {
    fis[0].pos = pos1;
    fis[1].pos = pos2;
    bool fa[2], ff[2];
    brutas(fa, ff);
    EntradasSistema e;
    for (int i = 0; i < 2; i++) {
      dbFimA[i].configurar(P_DEBOUNCE_FIM_MS, P_DEBOUNCE_FIM_MS, fa[i], t);
      dbFimF[i].configurar(P_DEBOUNCE_FIM_MS, P_DEBOUNCE_FIM_MS, ff[i], t);
      dbIr[i].configurar(P_IR_CONFIRMA_MS, P_IR_LIBERA_MS, false, t);
      e.porta[i].fimAberta = fa[i];
      e.porta[i].fimFechada = ff[i];
    }
    dbB1.configurar(P_DEBOUNCE_BOTAO_MS, P_DEBOUNCE_BOTAO_MS, false, t);
    dbB2.configurar(P_DEBOUNCE_BOTAO_MS, P_DEBOUNCE_BOTAO_MS, false, t);
    dbPar.configurar(P_DEBOUNCE_BOTAO_MS, P_DEBOUNCE_BOTAO_MS, false, t);
    ctl.iniciar(configPortaPadrao(), e, t, true, P_REARME_MS);
  }

  Resultado comando(const char* txt) {
    Comando c;
    interpretarComando(txt, c);
    return ctl.executar(c, Origem::APP, t);
  }

  void passo() {
    t++;
    if (roteiro) roteiro(*this);
    bool fa[2], ff[2];
    brutas(fa, ff);
    EntradasSistema e;
    for (int i = 0; i < 2; i++) {
      dbFimA[i].atualizar(fa[i], t);
      dbFimF[i].atualizar(ff[i], t);
      dbIr[i].atualizar(irBruto[i], t);
      e.porta[i].fimAberta = dbFimA[i].estado();
      e.porta[i].fimFechada = dbFimF[i].estado();
      e.porta[i].obstaculo = dbIr[i].estado();
    }
    dbB1.atualizar(b1, t); dbB2.atualizar(b2, t); dbPar.atualizar(parada, t);
    e.botao1 = dbB1.estado(); e.botao2 = dbB2.estado(); e.botaoParada = dbPar.estado();
    ctl.atualizar(e, t);

    Evento ev;
    while (ctl.proximoEvento(ev)) {
      if (ev.tipo == TipoEvento::OBSTACULO) eventosObstaculo++;
    }

    // Física: 1 ms
    for (int i = 0; i < 2; i++) {
      const Porta& p = ctl.porta(i);
      int pwm = p.pwm();
      double v = (pwm < PWM_MIN_GIRO) ? 0 : VEL_MAX_MM_S * pwm / 255.0;
      PortaFisica& f = fis[i];
      if (p.acao() == AcaoMotor::SUBIR && !f.cordaPartida) {
        if (f.travaEm < 0 || f.pos < f.travaEm) f.pos += v / 1000.0;
      } else if (p.acao() == AcaoMotor::DESCER) {
        f.pos -= v / 1000.0;
      }
      if (f.cordaPartida) f.pos -= 0.5;          // porta cai
      if (f.pos < 0) f.pos = 0;
      if (f.pos > CURSO_MM) f.pos = CURSO_MM;
    }
    // Tempo de reação: IR bruto ativo -> motor 1 freando
    if (reacaoInicio && !reacaoFim && ctl.porta(0).acao() == AcaoMotor::FREAR) reacaoFim = t;
  }

  void rodar(uint32_t ms) { for (uint32_t i = 0; i < ms; i++) passo(); }

  bool esperar(EstadoPorta e, int porta, uint32_t maxMs) {
    for (uint32_t i = 0; i < maxMs; i++) {
      if (ctl.porta(porta).estado() == e) return true;
      passo();
    }
    return ctl.porta(porta).estado() == e;
  }
};

// ---------------------------------------------------------------------
static void cenarioManejo() {
  printf("\n[1] Ciclo completo de manejo (entrada -> contencao -> RFID -> saida)\n");
  Simulador s;
  s.iniciar(0, 0);
  uint32_t t0 = s.t;
  VERIFICA(s.comando("ABRIR 1") == Resultado::OK, "abrir porta de entrada");
  VERIFICA(s.esperar(EstadoPorta::ABERTA, 0, 8000), "porta 1 abre");
  uint32_t tAbrir = s.t - t0;
  printf("    porta 1 abriu em %.2f s\n", tAbrir / 1000.0);
  s.irBruto[0] = true; s.rodar(1500); s.irBruto[0] = false;   // animal entra
  VERIFICA(s.comando("FECHAR 1") == Resultado::OBSTACULO, "com o animal sob a porta nao fecha");
  s.rodar(P_IR_LIBERA_MS + 10);
  t0 = s.t;
  VERIFICA(s.comando("FECHAR 1") == Resultado::OK, "fechar entrada (feixe livre)");
  VERIFICA(s.esperar(EstadoPorta::FECHADA, 0, 8000), "porta 1 fecha");
  printf("    porta 1 fechou em %.2f s\n", (s.t - t0) / 1000.0);
  s.ctl.rfidLido("04A1B2C3");
  VERIFICA(!strcmp(s.ctl.uidAtual(), "04A1B2C3"), "animal identificado pelo RFID");
  s.rodar(2000);                                                 // manejo
  VERIFICA(s.comando("ABRIR 2") == Resultado::OK, "abrir saida (entrada fechada)");
  VERIFICA(s.esperar(EstadoPorta::ABERTA, 1, 8000), "porta 2 abre");
  s.irBruto[1] = true; s.rodar(1200); s.irBruto[1] = false;   // animal sai
  s.ctl.rfidSaiu();
  s.rodar(P_IR_LIBERA_MS + 10);
  VERIFICA(s.comando("FECHAR 2") == Resultado::OK, "fechar saida");
  VERIFICA(s.esperar(EstadoPorta::FECHADA, 1, 8000), "porta 2 fecha");
  VERIFICA(!s.ctl.algumaFalha() && !s.ctl.emergencia(), "ciclo sem falhas");
  printf("    ciclo completo em %.1f s, sem falhas\n", s.t / 1000.0);
}

static void cenarioAnimalSobAPorta() {
  printf("\n[2] Animal entra sob a porta durante o fechamento\n");
  Simulador s;
  s.iniciar(CURSO_MM, 0);
  s.comando("FECHAR 1");
  s.rodar(1200);
  double posAoDetectar = s.fis[0].pos;
  s.reacaoInicio = s.t + 1;
  s.roteiro = [](Simulador& x) {
    if (x.t >= x.reacaoInicio && x.t < x.reacaoInicio + 1500) x.irBruto[0] = true;
    else x.irBruto[0] = false;
  };
  s.rodar(5);
  for (int i = 0; i < 100 && !s.reacaoFim; i++) s.passo();
  uint32_t reacao = s.reacaoFim - s.reacaoInicio;
  printf("    feixe interrompido com a porta a %.0f mm; freio em %u ms\n", posAoDetectar, (unsigned)reacao);
  VERIFICA(s.reacaoFim != 0 && reacao <= 50, "freia em ate 50 ms apos o feixe ser interrompido");
  VERIFICA(s.ctl.porta(0).estado() == EstadoPorta::RECUANDO, "estado RECUANDO");
  VERIFICA(s.esperar(EstadoPorta::ABERTA, 0, 8000), "porta reabre ate o fim");
  VERIFICA(s.eventosObstaculo == 1, "um evento OBSTACULO enviado ao app");
  s.roteiro = nullptr;
  s.irBruto[0] = false;
  s.rodar(2000);
  VERIFICA(s.comando("FECHAR 1") == Resultado::OK, "fecha depois do feixe livre");
  VERIFICA(s.esperar(EstadoPorta::FECHADA, 0, 8000), "porta fecha normalmente");
}

static void cenarioCordaPartida() {
  printf("\n[3] Corda partida (motor gira, porta nao sobe)\n");
  Simulador s;
  s.iniciar(0, 0);
  s.fis[0].cordaPartida = true;
  uint32_t t0 = s.t;
  s.comando("ABRIR 1");
  VERIFICA(s.esperar(EstadoPorta::FALHA, 0, 10000), "entra em FALHA");
  printf("    detectado em %.2f s como %s\n", (s.t - t0) / 1000.0, nomeFalha(s.ctl.porta(0).falha()));
  VERIFICA(s.ctl.porta(0).falha() == FalhaPorta::FIM_PRESO, "falha FIM_PRESO (chave fechada nao soltou)");
  s.rodar(P_FREIO_MS + 5);
  VERIFICA(s.ctl.porta(0).acao() == AcaoMotor::PARADO, "motor desligado");
}

static void cenarioPortaTravada() {
  printf("\n[4] Porta trava no meio do curso ao abrir\n");
  Simulador s;
  s.iniciar(0, 0);
  s.fis[0].travaEm = 150;
  uint32_t t0 = s.t;
  s.comando("ABRIR 1");
  VERIFICA(s.esperar(EstadoPorta::FALHA, 0, 10000), "entra em FALHA");
  printf("    detectado em %.2f s como %s (porta em %.0f mm)\n", (s.t - t0) / 1000.0,
         nomeFalha(s.ctl.porta(0).falha()), s.fis[0].pos);
  VERIFICA(s.ctl.porta(0).falha() == FalhaPorta::TIMEOUT_ABRIR, "falha TIMEOUT_ABRIR");
  VERIFICA(s.comando("ABRIR 1") == Resultado::FALHA, "porta em falha nao aceita comandos");
  s.fis[0].travaEm = -1;
  VERIFICA(s.comando("RESET") == Resultado::OK, "RESET");
  VERIFICA(s.ctl.porta(0).estado() == EstadoPorta::PARADA, "apos RESET: PARADA no meio");
}

static void cenarioEmergencia() {
  printf("\n[5] Parada manual durante o fechamento\n");
  Simulador s;
  s.iniciar(CURSO_MM, 0);
  s.comando("FECHAR 1");
  s.rodar(1000);
  double antes = s.fis[0].pos;
  s.parada = true; s.rodar(200); s.parada = false;
  s.rodar(500);
  double depois = s.fis[0].pos;
  printf("    porta parou em %.0f mm (andou %.1f mm apos o botao)\n", depois, antes - depois);
  VERIFICA(s.ctl.emergencia(), "emergencia ativa");
  VERIFICA(antes - depois < 10.0, "porta para em menos de 1 cm");
  VERIFICA(s.comando("FECHAR 1") == Resultado::EMERGENCIA, "nenhum comando de movimento aceito");
  s.parada = true; s.rodar(P_REARME_MS + 50); s.parada = false; s.rodar(50);
  VERIFICA(!s.ctl.emergencia(), "rearme segurando o botao por 3 s");
  VERIFICA(s.comando("FECHAR 1") == Resultado::OK, "volta a operar");
}

static void cenarioIntertravamento() {
  printf("\n[6] Tentativa de abrir as duas portas\n");
  Simulador s;
  s.iniciar(0, 0);
  s.comando("ABRIR 1");
  s.rodar(500);
  VERIFICA(s.comando("ABRIR 2") == Resultado::INTERTRAVAMENTO, "porta 1 abrindo: porta 2 bloqueada");
  s.esperar(EstadoPorta::ABERTA, 0, 8000);
  VERIFICA(s.comando("ABRIR 2") == Resultado::INTERTRAVAMENTO, "porta 1 aberta: porta 2 bloqueada");
  VERIFICA(s.ctl.porta(1).estado() == EstadoPorta::FECHADA, "porta 2 continua fechada");
}

int main() {
  printf("BoviCare - simulacao fisica do brete (firmware %s)\n", FIRMWARE_VERSAO);
  cenarioManejo();
  cenarioAnimalSobAPorta();
  cenarioCordaPartida();
  cenarioPortaTravada();
  cenarioEmergencia();
  cenarioIntertravamento();
  printf("\nResultado da simulacao: %d verificacoes OK, %d falhas\n", g_ok, g_falhas);
  return g_falhas == 0 ? 0 : 1;
}
