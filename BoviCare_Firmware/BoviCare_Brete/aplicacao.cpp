// =====================================================================
//  BoviCare - Brete automatizado
//  aplicacao.cpp  ->  laço principal do firmware
// =====================================================================
#include <Arduino.h>
#include "aplicacao.h"
#include "config_pinos.h"
#include "parametros.h"
#include "tipos.h"
#include "debounce.h"
#include "porta.h"
#include "controlador.h"
#include "protocolo.h"
#include "hardware_brete.h"
#include "leitor_rfid.h"
#include "ble_brete.h"

// ---------------------------------------------------------------------
// Estado global
// ---------------------------------------------------------------------
static Controlador ctl;

static Debounce dbFimAberta[2], dbFimFechada[2], dbIr[2];
static Debounce dbBotao1, dbBotao2, dbParada;

static char     linhaSerial[COMANDO_MAX_CHARS + 1];
static size_t   tamLinhaSerial = 0;
static uint32_t ultimoEstadoBle = 0;
static uint32_t maiorLacoUs = 0;
static uint32_t voltasDoLaco = 0;

// ---------------------------------------------------------------------
// Entradas
// ---------------------------------------------------------------------
static void configurarFiltros(const EntradasBrutas& b, uint32_t agora) {
  for (uint8_t i = 0; i < 2; i++) {
    dbFimAberta[i].configurar(P_DEBOUNCE_FIM_MS, P_DEBOUNCE_FIM_MS, b.fimAberta[i], agora);
    dbFimFechada[i].configurar(P_DEBOUNCE_FIM_MS, P_DEBOUNCE_FIM_MS, b.fimFechada[i], agora);
    // IR: confirma o obstáculo rápido, libera devagar.
    dbIr[i].configurar(P_IR_CONFIRMA_MS, P_IR_LIBERA_MS, b.obstaculo[i], agora);
  }
  dbBotao1.configurar(P_DEBOUNCE_BOTAO_MS, P_DEBOUNCE_BOTAO_MS, b.botao1, agora);
  dbBotao2.configurar(P_DEBOUNCE_BOTAO_MS, P_DEBOUNCE_BOTAO_MS, b.botao2, agora);
  dbParada.configurar(P_DEBOUNCE_BOTAO_MS, P_DEBOUNCE_BOTAO_MS, b.botaoParada, agora);
}

static EntradasSistema lerEntradasFiltradas(uint32_t agora) {
  EntradasBrutas b;
  hw::lerEntradas(b);
  EntradasSistema e;
  for (uint8_t i = 0; i < 2; i++) {
    dbFimAberta[i].atualizar(b.fimAberta[i], agora);
    dbFimFechada[i].atualizar(b.fimFechada[i], agora);
    dbIr[i].atualizar(b.obstaculo[i], agora);
    e.porta[i].fimAberta = dbFimAberta[i].estado();
    e.porta[i].fimFechada = dbFimFechada[i].estado();
    e.porta[i].obstaculo = dbIr[i].estado();
  }
  dbBotao1.atualizar(b.botao1, agora);
  dbBotao2.atualizar(b.botao2, agora);
  dbParada.atualizar(b.botaoParada, agora);
  e.botao1 = dbBotao1.estado();
  e.botao2 = dbBotao2.estado();
  e.botaoParada = dbParada.estado();
  return e;
}

// ---------------------------------------------------------------------
// Saída de mensagens
// ---------------------------------------------------------------------
static void publicarEstado(bool serialTambem) {
  char json[JSON_ESTADO_MAX + 40];
  size_t n = jsonEstado(ctl, millis() / 1000, json, sizeof(json));
  ble::publicarEstado(json, n);
  if (serialTambem) {
    Serial.print("EST ");
    Serial.println(json);
  }
}

static void publicarEventos() {
  Evento ev;
  char json[JSON_EVENTO_MAX + 20];
  while (ctl.proximoEvento(ev)) {
    size_t n = jsonEvento(ev, json, sizeof(json));
    Serial.print("EVT ");
    Serial.println(json);
    ble::publicarEvento(json, n);
  }
}

static void imprimirAjuda() {
  Serial.println();
  Serial.println("Comandos (serial ou app). Porta: 1/ENTRADA/E ou 2/SAIDA/S");
  Serial.println("  ABRIR 1       FECHAR 2       ALTERNAR 1     PARAR [1|2]");
  Serial.println("  EMERGENCIA    RESET          STATUS         PING");
  Serial.println("  DIAG          AJUDA");
  Serial.println("  JOG 1 SOBE 300 | JOG 2 DESCE 200   (ajuste, so pela serial, max 1000 ms)");
  Serial.println("  #17 ABRIR 1   (qualquer comando com id; a resposta volta com \"id\":17)");
  Serial.println();
}

static void imprimirDiagnostico() {
  Serial.println();
  Serial.println("=========== DIAGNOSTICO BoviCare ===========");
  Serial.printf("Firmware %s   ligado ha %lu s   heap livre: %lu bytes\n", FIRMWARE_VERSAO,
                (unsigned long)(millis() / 1000), (unsigned long)ESP.getFreeHeap());
  hw::imprimirNiveis(Serial);
  for (uint8_t i = 0; i < 2; i++) {
    const Porta& p = ctl.porta(i);
    const EntradasPorta& e = p.entradas();
    Serial.printf("Porta %u: %-9s falha: %-14s fimA:%d fimF:%d IR:%d\n", (unsigned)(i + 1),
                  nomeEstado(p.estado()), p.falha() == FalhaPorta::NENHUMA ? "-" : nomeFalha(p.falha()),
                  e.fimAberta, e.fimFechada, e.obstaculo);
  }
  Serial.printf("Emergencia: %s   eventos perdidos: %lu\n", ctl.emergencia() ? "ATIVA" : "nao",
                (unsigned long)ctl.eventosPerdidos());
  Serial.printf("Laco: maior volta %lu us (desde o ultimo DIAG), voltas: %lu\n",
                (unsigned long)maiorLacoUs, (unsigned long)voltasDoLaco);
  rfid::imprimirDiagnostico(Serial);
  ble::imprimirDiagnostico(Serial);
  Serial.println("============================================");
  maiorLacoUs = 0;
}

// ---------------------------------------------------------------------
// Comandos
// ---------------------------------------------------------------------
static void processarTexto(const char* texto, Origem origem, uint32_t agora) {
  Comando c;
  if (!interpretarComando(texto, c)) return;      // linha vazia
  ctl.executar(c, origem, agora);
  if (origem == Origem::SERIAL_USB) {
    if (c.tipo == TipoComando::AJUDA) imprimirAjuda();
    if (c.tipo == TipoComando::DIAG) imprimirDiagnostico();
  }
  if (c.tipo == TipoComando::STATUS) publicarEstado(true);
}

static void lerSerial(uint32_t agora) {
  while (Serial.available()) {
    char ch = (char)Serial.read();
    if (ch == '\n' || ch == '\r') {
      if (tamLinhaSerial > 0) {
        linhaSerial[tamLinhaSerial] = 0;
        processarTexto(linhaSerial, Origem::SERIAL_USB, agora);
        tamLinhaSerial = 0;
      }
    } else if (tamLinhaSerial < COMANDO_MAX_CHARS) {
      linhaSerial[tamLinhaSerial++] = ch;
    }
  }
}

static void lerBluetooth(uint32_t agora) {
  char texto[COMANDO_MAX_CHARS + 1];
  while (ble::proximoComando(texto, sizeof(texto))) {
    processarTexto(texto, Origem::APP, agora);
  }
}

static void lerRfid() {
  rfid::Leitura l;
  while (rfid::proxima(l)) {
    switch (l.tipo) {
      case rfid::TipoLeitura::CHEGOU:      ctl.rfidLido(l.uid); break;
      case rfid::TipoLeitura::SAIU:        ctl.rfidSaiu(); break;
      case rfid::TipoLeitura::LEITOR_OK:   ctl.rfidStatus(true); break;
      case rfid::TipoLeitura::LEITOR_ERRO: ctl.rfidStatus(false); break;
    }
  }
}

// ---------------------------------------------------------------------
// LED da placa
//   1 piscada curta por segundo = aguardando o app
//   aceso fixo                  = app conectado
//   piscando rápido             = emergência ou porta em falha
// ---------------------------------------------------------------------
static void atualizarLed(uint32_t agora) {
  bool aceso;
  if (ctl.emergencia() || ctl.algumaFalha()) aceso = (agora / 100) % 2;
  else if (ble::conectado()) aceso = true;
  else aceso = (agora % 1000) < 60;
  hw::led(aceso);
}

// ---------------------------------------------------------------------
// Ponto de entrada (chamado pelo BoviCare_Brete.ino)
// ---------------------------------------------------------------------
void aplicacaoIniciar() {
  hw::iniciar();                     // 1º: motores desligados
  Serial.begin(P_SERIAL_BAUD);
  delay(50);                         // entradas estabilizam

  uint32_t agora = millis();
  EntradasBrutas b;
  hw::lerEntradas(b);
  configurarFiltros(b, agora);
  EntradasSistema e = lerEntradasFiltradas(agora);
  ctl.iniciar(configPortaPadrao(), e, agora, P_INTERTRAVAMENTO != 0, P_REARME_MS);

  Serial.println();
  Serial.println("================================================");
  Serial.printf("  BoviCare - Brete automatizado  (firmware %s)\n", FIRMWARE_VERSAO);
  Serial.println("  Digite AJUDA para ver os comandos.");
  Serial.println("================================================");

  rfid::iniciar();
  ble::iniciar(BLE_NOME_DISPOSITIVO);
  Serial.printf("Bluetooth: anunciando como \"%s\"\n", BLE_NOME_DISPOSITIVO);

  publicarEventos();
  publicarEstado(true);

  // Watchdog: se o laço travar por mais de ~5 s, o ESP32 reinicia
  // (os motores ficam desligados pelos resistores de pull-down do EN).
  enableLoopWDT();
}

void aplicacaoLaco() {
  uint32_t t0 = micros();
  uint32_t agora = millis();

  EntradasSistema e = lerEntradasFiltradas(agora);   // 1
  ctl.atualizar(e, agora);                           // 2
  lerSerial(agora);                                  // 3
  lerBluetooth(agora);
  lerRfid();                                         // 4

  for (uint8_t i = 0; i < 2; i++) {                  // 5
    hw::aplicarMotor(i, ctl.porta(i).acao(), ctl.porta(i).pwm());
  }

  publicarEventos();                                 // 6
  ble::manter();
  bool novaConexao = ble::consumirNovaConexao();
  if (novaConexao) {
    // Retrato completo a cada conexão: estado + animal presente.
    Evento ini;
    ini.tipo = TipoEvento::INICIO;
    char json[JSON_EVENTO_MAX];
    size_t n = jsonEvento(ini, json, sizeof(json));
    ble::publicarEvento(json, n);
    if (ctl.uidAtual()[0]) ctl.rfidLido(ctl.uidAtual());
    publicarEventos();
  }
  bool mudou = ctl.consumirMudanca();
  if (mudou || novaConexao || (uint32_t)(agora - ultimoEstadoBle) >= P_ESTADO_PERIODO_MS) {
    ultimoEstadoBle = agora;
    publicarEstado(mudou);
  }

  atualizarLed(agora);

  uint32_t dur = micros() - t0;
  if (dur > maiorLacoUs) maiorLacoUs = dur;
  voltasDoLaco++;

  delay(1);   // cede 1 ms às outras tarefas; o laço continua com ~1 kHz
}
