// =====================================================================
//  BoviCare - testes automáticos do firmware do brete 1.5.1 (rodam no PC)
//
//  Compila o PRÓPRIO arquivo BoviCare_Brete_Final.ino, sem nenhuma linha
//  mudada, contra a placa simulada de stubs/ e placa_sim.cpp, e liga as
//  saídas dos motores a um modelo físico simples das duas porteiras:
//  o motor sobe ou desce a porta, a porta aciona as chaves de fim de
//  curso, o animal embaixo da porta corta o sensor IR.
//
//  Cada cenário roda num processo separado (fork), com o firmware recém-
//  -ligado, como se a placa tivesse acabado de receber energia.
//  Uso: bash ../rodar_testes.sh   (ou: g++ ... && ./teste_final amostras.txt)
// =====================================================================
#ifndef FIRMWARE_INO   // outro arquivo só para a checagem de mutantes (rodar_testes.sh --mutantes)
#define FIRMWARE_INO "../../BoviCare_Brete_Final/BoviCare_Brete_Final.ino"
#endif
#include FIRMWARE_INO

#include <sys/wait.h>
#include <unistd.h>
#include <cmath>
#include <random>

static int g_ok = 0, g_falhas = 0, g_achados = 0;
static const char* g_cenario = "";
#define VERIFICA(cond, msg)                                                                 \
  do {                                                                                      \
    if (cond) g_ok++;                                                                       \
    else { g_falhas++; printf("  FALHOU [%s]: %s  (linha %d)\n", g_cenario, msg, __LINE__); } \
  } while (0)
// Comportamento que a 1.5.1 ainda não tem e que fica registrado para a próxima versão
// (ver "Achados" no README). Não conta como falha, mas aparece em toda execução.
#define ACHADO(cond, msg)                                                                  \
  do {                                                                                      \
    if (cond) g_ok++;                                                                       \
    else { g_achados++; printf("  ACHADO [%s]: %s\n", g_cenario, msg); }                     \
  } while (0)

// =====================================================================
//  Modelo físico das porteiras
// =====================================================================
const double CURSO_MM = 300.0;     // curso da porteira da maquete
const double V_SOBE = 115.0;       // mm/s com PWM 255 (abre em ~2,6 s)
const double V_DESCE = 140.0;      // mm/s com PWM 255 (fecha em ~2,1 s)
const double V_ESCORREGA = 20.0;   // mm/s: motor solto, a porta desce com o peso

struct PortaFisica {
  double pos = 0;                  // 0 = fechada, CURSO_MM = aberta
  double v = 0;                    // velocidade no último ms (mm/s)
  bool travada = false;            // não sai do lugar (corda partida, porta presa)
  bool fiacaoInvertida = false;    // motor ligado ao contrário
  int forcaFimA = -1, forcaFimF = -1;   // -1 = segue a posição; 0/1 = fio forçado
};

struct Brete {
  PortaFisica p[2];
  bool animalSob[2] = {false, false};
  bool botao[2] = {false, false};
  bool paradaApertada = false;
  bool escorrega = true;            // false = o atrito segura a porta com o motor solto
  // monitores de segurança (contados a cada ms)
  long msAmbasAbertas = 0;
  double descidaSobreAnimal[2] = {0, 0};   // maior descida da porta com o animal embaixo (mm)
  long msMotorLigadoNaEmergencia = 0;
} B;

static void fisica(uint32_t) {
  for (int i = 0; i < 2; i++) {
    PortaFisica& f = B.p[i];
    int ina = sim::saida[PINO_INA[i]], inb = sim::saida[PINO_INB[i]];
    int d = sim::pwmLigado[PINO_EN[i]] ? sim::duty[PINO_EN[i]] : 0;
    int dir = (ina && !inb) ? +1 : ((inb && !ina) ? -1 : 0);
    if (f.fiacaoInvertida) dir = -dir;
    double v;
    if (dir > 0 && d >= 150) v = V_SOBE * d / 255.0;          // sobe
    else if (dir > 0 && d >= 60) v = 0;                         // força baixa: segura no lugar
    else if (dir < 0 && d >= 60) v = -V_DESCE * d / 255.0;      // desce
    else if (dir == 0 && !ina && !inb && d >= 200) v = 0;       // freio dinâmico
    else v = B.escorrega ? -V_ESCORREGA : 0;                    // solto: escorrega
    if (f.travada) v = 0;
    f.v = v;
    f.pos += v / 1000.0;
    if (f.pos < 0) f.pos = 0;
    if (f.pos > CURSO_MM) f.pos = CURSO_MM;
    bool fimA = f.pos >= CURSO_MM - 2.0, fimF = f.pos <= 2.0;
    if (f.forcaFimA >= 0) fimA = f.forcaFimA;
    if (f.forcaFimF >= 0) fimF = f.forcaFimF;
    sim::nivel[PINO_FIM_ABERTA[i]] = fimA ? HIGH : LOW;      // NF ao GND + pull-up: acionada = ALTO
    sim::nivel[PINO_FIM_FECHADA[i]] = fimF ? HIGH : LOW;
    sim::milivolts[PINO_IR[i]] = B.animalSob[i] ? 300 : 2000;
    sim::nivel[PINO_BOTAO[i]] = B.botao[i] ? HIGH : LOW;      // contato NO com pull-down
    static bool havia[2] = {false, false};
    static double inicio[2] = {0, 0};
    if (B.animalSob[i] && !havia[i]) inicio[i] = f.pos;   // posição quando o animal entrou embaixo
    if (B.animalSob[i] && inicio[i] - f.pos > B.descidaSobreAnimal[i]) B.descidaSobreAnimal[i] = inicio[i] - f.pos;
    havia[i] = B.animalSob[i];
    if (emergencia && (dir < 0 || (dir > 0 && d >= 150))) B.msMotorLigadoNaEmergencia++;
  }
  sim::nivel[PINO_PARADA] = B.paradaApertada ? LOW : HIGH;   // NC ao 3,3 V: apertado ou fio rompido = BAIXO
  if (B.p[0].pos > 5 && B.p[1].pos > 5) B.msAmbasAbertas++;
}

// =====================================================================
//  Ajudantes
// =====================================================================
static size_t g_cursor = 0;   // até onde a saída da serial já foi lida pelo teste
static size_t g_fimAmostras = std::string::npos;   // entradas de lixo depois daqui não vão para as amostras
static size_t g_fimNotificacoes = std::string::npos;

// Checagem simples de JSON bem formado (a completa é a do validar_json.py)
static bool jsonBemFormado(const std::string& j) {
  if (j.size() < 2 || j.front() != '{' || j.back() != '}') return false;
  int aspas = 0;
  for (size_t k = 0; k < j.size(); k++) if (j[k] == '"' && (k == 0 || j[k - 1] != '\\')) aspas++;
  return aspas % 2 == 0;
}

static void preparar(double pos1, double pos2) {
  for (int k = 0; k < 40; k++) { sim::nivel[k] = -1; sim::saida[k] = 0; sim::modo[k] = 0; sim::duty[k] = 0; sim::milivolts[k] = 0; }
  B.p[0].pos = pos1;
  B.p[1].pos = pos2;
  sim::aoPassarTempo = fisica;
  sim::agoraMs = 1000;
  fisica(sim::agoraMs);
}

static void ligar(double pos1 = 0, double pos2 = 0) {
  preparar(pos1, pos2);
  setup();
}

static void rodar(uint32_t ms) {
  uint32_t fim = sim::agoraMs + ms;
  while ((int32_t)(fim - sim::agoraMs) > 0) loop();
}

// Roda até a condição valer (ou estourar o prazo). Devolve o tempo gasto em ms, ou -1.
static long rodarAte(const std::function<bool()>& cond, uint32_t prazoMs) {
  uint32_t ini = sim::agoraMs;
  while (sim::agoraMs - ini < prazoMs) {
    loop();
    if (cond()) return (long)(sim::agoraMs - ini);
  }
  return -1;
}

static std::vector<std::string> linhasNovas(const char* prefixo) {
  std::vector<std::string> r;
  const std::string& s = Serial.saidaTexto;
  size_t pos = g_cursor;
  while (pos < s.size()) {
    size_t fim = s.find('\n', pos);
    if (fim == std::string::npos) break;
    std::string l = s.substr(pos, fim - pos);
    if (l.rfind(prefixo, 0) == 0) r.push_back(l.substr(strlen(prefixo)));
    pos = fim + 1;
  }
  return r;
}

static std::string campo(const std::string& json, const char* nome) {
  std::string chave = std::string("\"") + nome + "\":";
  size_t k = json.find(chave);
  if (k == std::string::npos) return "";
  k += chave.size();
  if (json[k] == '"') { size_t f = json.find('"', k + 1); return json.substr(k + 1, f - k - 1); }
  size_t f = json.find_first_of(",}", k);
  return json.substr(k, f - k);
}

static std::vector<std::string> eventos(const char* tipo) {
  std::vector<std::string> r;
  for (auto& j : linhasNovas("EVT ")) if (campo(j, "ev") == tipo) r.push_back(j);
  return r;
}

static void marcar() { g_cursor = Serial.saidaTexto.size(); }

// Comando pelo aplicativo (escrita na característica BLE) ou pela serial.
// Devolve o "res" da resposta RESP.
static std::string enviar(const char* cmd, bool pelaSerial) {
  marcar();
  if (pelaSerial) Serial.digitar(cmd);
  else {
    BLECharacteristic escrita("b0c1ca5e-0002-4b8e-9d3a-6f2e1c7a9d10", BLECharacteristic::PROPERTY_WRITE);
    escrita.valor = cmd;
    static_cast<BLECharacteristicCallbacks*>(&cbComando)->onWrite(&escrita);   // como a pilha BLE chama
  }
  rodar(6);
  auto r = eventos("RESP");
  return r.empty() ? "" : campo(r.back(), "res");
}
static std::string app(const char* cmd) { return enviar(cmd, false); }
static std::string serial(const char* cmd) { return enviar(cmd, true); }

static int dirMotor(int i) {
  int ina = sim::saida[PINO_INA[i]], inb = sim::saida[PINO_INB[i]];
  return (ina && !inb) ? +1 : ((inb && !ina) ? -1 : 0);
}
static bool motorParado(int i) { return dirMotor(i) == 0; }
static Estado est(int i) { return porta[i].estado; }

// =====================================================================
//  Cenários
// =====================================================================
static void cenarioPartida() {
  ligar(0, 0);
  auto ini = linhasNovas("EVT ");
  bool temInicio = false;
  for (auto& j : ini) if (campo(j, "ev") == "INICIO" && campo(j, "ver") == "1.5.1") temInicio = true;
  VERIFICA(temInicio, "evento INICIO com a versão 1.5.1");
  VERIFICA(est(0) == FECHADA && est(1) == FECHADA, "portas fechadas lidas nas chaves");
  VERIFICA(sim::nomeBle == "BoviCare-Brete", "nome Bluetooth");
  VERIFICA(sim::anuncios >= 1, "anúncio Bluetooth ligado");
  VERIFICA(sim::anuncioBle.uuids.size() == 1 && sim::anuncioBle.uuids[0] == BLE_UUID_SERVICO, "anuncia o serviço do BoviCare");
  marcar();
  rodar(3000);
  VERIFICA(motorParado(0) && motorParado(1), "nenhum motor se move ao ligar");
  VERIFICA(B.p[0].pos == 0 && B.p[1].pos == 0, "portas não saem do lugar ao ligar");
  VERIFICA(!eventos("RFID_OK").empty() || rfidOk, "leitor RFID respondeu (RFID_OK)");
  VERIFICA(linhasNovas("EST ").empty(), "estado periódico vai só para o app, não para a serial");
  VERIFICA(carEstado && !carEstado->valor.empty() && campo(carEstado->valor, "p1") == "FECHADA", "estado legível pelo app");
}

static void cenarioPartidaPortasNoMeioEAbertas() {
  B.escorrega = false;   // desligada, a porta ficou parada pelo atrito
  ligar(150, CURSO_MM);
  B.escorrega = true;
  VERIFICA(est(0) == PARADA, "porta 1 sem chave acionada: PARADA (no meio)");
  VERIFICA(est(1) == ABERTA, "porta 2 na chave de cima: ABERTA");
  rodar(2000);
  VERIFICA(dirMotor(0) == +1 && sim::duty[PINO_EN[0]] == SEGURAR_PADRAO, "porta no meio fica segura (força baixa para cima)");
  VERIFICA(std::fabs(B.p[0].pos - 150) < 1, "porta no meio não cai");
  VERIFICA(B.p[1].pos >= CURSO_MM - 2, "porta aberta não cai");
}

static void cenarioPartidaComFalhas() {
  preparar(0, 0);
  B.p[0].forcaFimA = 1;   // as duas chaves da porta 1 acionadas
  setup();
  VERIFICA(est(0) == FALHA && !strcmp(porta[0].falha, "FIM_DUPLO"), "FIM_DUPLO detectado na partida");
  bool ev = false;
  for (auto& j : linhasNovas("EVT ")) if (campo(j, "ev") == "FALHA" && campo(j, "f") == "FIM_DUPLO") ev = true;
  VERIFICA(ev, "evento FALHA FIM_DUPLO enviado na partida");
  VERIFICA(app("ABRIR 1") == "FALHA", "porta em falha não abre");
  VERIFICA(app("RESET") == "OK" && est(0) == FALHA, "RESET com as duas chaves ainda acionadas mantém a FALHA");
  B.p[0].forcaFimA = -1;
  rodar(100);
  VERIFICA(app("RESET") == "OK" && est(0) == FECHADA, "RESET depois do conserto volta a FECHADA");
}

static void cenarioPartidaComBotaoApertado() {
  preparar(0, 0);
  B.botao[0] = true;
  setup();
  rodar(500);
  VERIFICA(motorParado(0) && est(0) == FECHADA, "botão apertado na partida é ignorado");
  B.botao[0] = false;
  rodar(100);
  VERIFICA(motorParado(0), "soltar o botão não move a porta");
  B.botao[0] = true;
  rodar(100);
  B.botao[0] = false;
  VERIFICA(est(0) == ABRINDO, "depois de solto, o botão volta a funcionar");
}

static void cenarioPartidaComParadaApertada() {
  preparar(0, 0);
  B.paradaApertada = true;
  setup();
  VERIFICA(emergencia, "parada apertada (ou fio rompido) na partida entra em emergência");
  VERIFICA(app("ABRIR 1") == "EMERGENCIA", "emergência bloqueia os comandos");
  VERIFICA(app("RESET") == "EMERGENCIA", "RESET recusado com a parada ainda apertada");
}

static void cenarioAbrirEFechar() {
  ligar(0, 0);
  VERIFICA(app("ABRIR 1") == "OK", "ABRIR 1 aceito");
  VERIFICA(est(0) == ABRINDO, "porta 1 ABRINDO");
  rodar(50);
  VERIFICA(dirMotor(0) == +1 && sim::duty[PINO_EN[0]] == PWM_ABRIR, "motor 1 sobe com PWM máximo");
  long t = rodarAte([] { return est(0) == ABERTA; }, 6000);
  VERIFICA(t > 0, "porta 1 chega a ABERTA");
  VERIFICA(B.p[0].pos >= CURSO_MM - 2, "parou na chave de cima");
  rodar(400);
  VERIFICA(dirMotor(0) == +1 && sim::duty[PINO_EN[0]] == SEGURAR_PADRAO, "porta aberta fica segura com força baixa");
  VERIFICA(app("ABRIR 1") == "JA_ABERTA", "ABRIR repetido responde JA_ABERTA");
  rodar(10000);
  VERIFICA(B.p[0].pos >= CURSO_MM - 2 && est(0) == ABERTA, "porta aberta continua aberta (10 s)");
  VERIFICA(app("FECHAR 1") == "OK", "FECHAR 1 aceito");
  rodar(200);   // freio de 150 ms antes de inverter o sentido
  VERIFICA(dirMotor(0) == -1, "motor 1 desce (depois do freio)");
  t = rodarAte([] { return est(0) == FECHADA; }, 6000);
  VERIFICA(t > 0 && B.p[0].pos <= 2, "porta 1 chega a FECHADA na chave de baixo");
  rodar(300);
  VERIFICA(motorParado(0) && sim::duty[PINO_EN[0]] == 0, "motor desligado com a porta fechada");
  VERIFICA(app("FECHAR 1") == "JA_FECHADA", "FECHAR repetido responde JA_FECHADA");
  // mesma coisa com a porta 2
  VERIFICA(app("ABRIR SAIDA") == "OK", "ABRIR SAIDA (nome da porta) aceito");
  VERIFICA(rodarAte([] { return est(1) == ABERTA; }, 6000) > 0, "porta 2 abre");
  VERIFICA(app("FECHAR 2") == "OK", "FECHAR 2 aceito");
  VERIFICA(rodarAte([] { return est(1) == FECHADA; }, 6000) > 0, "porta 2 fecha");
}

static void cenarioPararNoMeio() {
  ligar(0, 0);
  app("ABRIR 1");
  rodar(1200);
  VERIFICA(app("PARAR 1") == "OK", "PARAR 1 aceito");
  VERIFICA(est(0) == PARADA, "porta 1 PARADA no meio");
  double p = B.p[0].pos;
  rodar(5000);
  VERIFICA(std::fabs(B.p[0].pos - p) < 3, "porta parada no meio não cai (segura)");
  VERIFICA(app("ALTERNAR 1") == "OK" && est(0) == ABRINDO, "ALTERNAR de PARADA volta a abrir");
  VERIFICA(rodarAte([] { return est(0) == ABERTA; }, 6000) > 0, "e chega a ABERTA");
  VERIFICA(app("ALTERNAR 1") == "OK" && est(0) == FECHANDO, "ALTERNAR de ABERTA fecha");
  rodar(500);
  VERIFICA(app("PARAR") == "OK" && est(0) == PARADA && est(1) == FECHADA, "PARAR sem número para as duas");
}

static void cenarioIntertravamento() {
  ligar(0, 0);
  app("ABRIR 1");
  rodarAte([] { return est(0) == ABERTA; }, 6000);
  VERIFICA(app("ABRIR 2") == "INTERTRAVAMENTO", "porta 2 não abre com a porta 1 aberta");
  rodar(1000);
  VERIFICA(motorParado(1) && B.p[1].pos == 0, "motor 2 nem liga");
  app("FECHAR 1");
  rodar(800);
  VERIFICA(app("ABRIR 2") == "INTERTRAVAMENTO", "porta 2 não abre com a porta 1 fechando");
  app("PARAR 1");
  VERIFICA(app("ABRIR 2") == "INTERTRAVAMENTO", "porta 2 não abre com a porta 1 parada no meio");
  app("FECHAR 1");
  rodarAte([] { return est(0) == FECHADA; }, 6000);
  VERIFICA(app("ABRIR 2") == "OK", "com a porta 1 fechada, a porta 2 abre");
  rodarAte([] { return est(1) == ABERTA; }, 6000);
  VERIFICA(app("ABRIR 1") == "INTERTRAVAMENTO", "e a porta 1 fica travada");
  VERIFICA(B.msAmbasAbertas == 0, "as duas porteiras nunca ficaram abertas ao mesmo tempo");
}

static void cenarioObstaculo() {
  ligar(0, 0);
  app("ABRIR 1");
  rodarAte([] { return est(0) == ABERTA; }, 6000);
  B.animalSob[0] = true;
  rodar(50);
  VERIFICA(app("FECHAR 1") == "OBSTACULO", "não começa a fechar com o animal embaixo");
  rodar(500);
  VERIFICA(B.p[0].pos >= CURSO_MM - 2, "porta não desceu");
  B.animalSob[0] = false;
  rodar(50);
  VERIFICA(app("FECHAR 1") == "OK", "sem o animal, fecha");
  rodar(1000);   // desce até a metade do curso
  double antes = B.p[0].pos;
  marcar();
  B.animalSob[0] = true;   // o animal volta para baixo da porta
  long t = rodarAte([] { return dirMotor(0) != -1; }, 1000);
  VERIFICA(t >= 0 && t <= 20, "motor para de descer em até 20 ms depois do sensor IR");
  VERIFICA(antes - B.p[0].pos < 2, "a porta desce menos de 2 mm até o motor parar");
  VERIFICA(!eventos("OBSTACULO").empty(), "evento OBSTACULO enviado ao app");
  rodar(200);   // passou o freio (150 ms), ainda na pausa de 300 ms antes de reabrir
  ACHADO(dirMotor(0) == +1, "na pausa antes de reabrir o motor fica solto e a porta pode escorregar");
  VERIFICA(rodarAte([] { return est(0) == ABERTA; }, 6000) > 0, "porta reabre sozinha (RECUANDO -> ABRINDO -> ABERTA)");
  VERIFICA(B.descidaSobreAnimal[0] < 6, "com o animal embaixo, a porta desce menos de 6 mm no total");
}

static void cenarioEmergenciaPeloBotao() {
  ligar(0, 0);
  app("ABRIR 1");
  rodar(1000);
  marcar();
  B.paradaApertada = true;
  long t = rodarAte([] { return emergencia; }, 500);
  VERIFICA(t >= 0 && t <= 40, "emergência em até 40 ms depois de apertar a parada");
  VERIFICA(dirMotor(0) == 0, "motor freado na emergência");
  auto ev = eventos("EMERGENCIA");
  VERIFICA(!ev.empty() && campo(ev.back(), "on") == "1" && campo(ev.back(), "orig") == "BOTAO", "evento EMERGENCIA do botão");
  VERIFICA(est(0) == PARADA, "porta que estava abrindo fica PARADA");
  double p = B.p[0].pos;
  rodar(3000);
  VERIFICA(std::fabs(B.p[0].pos - p) < 3, "na emergência a porta é segurada, não cai sobre o animal");
  VERIFICA(B.msMotorLigadoNaEmergencia == 0, "nenhum motor movimenta a porta durante a emergência");
  VERIFICA(app("ABRIR 1") == "EMERGENCIA" && app("FECHAR 2") == "EMERGENCIA", "comandos recusados na emergência");
  VERIFICA(app("RESET") == "EMERGENCIA", "RESET recusado com a parada apertada");
  // rearme pelo próprio botão: soltar e depois segurar 3 s
  B.paradaApertada = false;
  rodar(200);
  B.paradaApertada = true;
  rodar(2000);
  VERIFICA(emergencia, "segurar menos de 3 s não rearma");
  marcar();
  rodar(1200);
  VERIFICA(!emergencia, "segurar 3 s rearma");
  VERIFICA(!eventos("REARME").empty(), "evento REARME enviado");
  B.paradaApertada = false;
  rodar(200);
  VERIFICA(!emergencia, "soltar depois do rearme não volta à emergência");
  VERIFICA(app("ABRIR 1") == "OK", "depois do rearme os comandos voltam");
}

static void cenarioEmergenciaPeloApp() {
  ligar(0, 0);
  app("ABRIR 2");
  rodar(800);
  VERIFICA(app("EMERGENCIA") == "OK" && emergencia, "EMERGENCIA pelo app");
  VERIFICA(dirMotor(1) == 0, "motor 2 freado");
  rodar(2000);
  VERIFICA(B.msMotorLigadoNaEmergencia == 0, "nada se move na emergência do app");
  VERIFICA(app("REARMAR") == "OK" && !emergencia, "REARMAR (sinônimo de RESET) libera");
  VERIFICA(app("ABRIR 2") == "OK", "volta a operar");
}

static void cenarioFioDaParadaRompido() {
  ligar(0, 0);
  app("ABRIR 1");
  rodar(500);
  B.paradaApertada = true;   // fio rompido: o GPIO5 também fica em BAIXO
  rodar(100);
  VERIFICA(emergencia && dirMotor(0) == 0, "fio da parada rompido = emergência (falha segura)");
}

static void cenarioFalhaChavePresa() {
  ligar(0, 0);
  B.p[0].travada = true;      // corda partida: o motor gira e a porta não sai da chave de baixo
  VERIFICA(app("ABRIR 1") == "OK", "ABRIR aceito");
  marcar();
  long t = rodarAte([] { return est(0) == FALHA; }, 8000);
  VERIFICA(t > 3900 && t < 4300, "FIM_PRESO depois de 4 s sem a chave de baixo soltar");
  VERIFICA(!strcmp(porta[0].falha, "FIM_PRESO"), "código FIM_PRESO");
  rodar(300);
  VERIFICA(motorParado(0), "motor desligado na falha");
  auto ev = eventos("FALHA");
  VERIFICA(!ev.empty() && campo(ev.back(), "f") == "FIM_PRESO", "evento FALHA FIM_PRESO");
  VERIFICA(app("ABRIR 1") == "FALHA", "porta em falha não aceita ABRIR");
  B.p[0].travada = false;
  VERIFICA(app("RESET") == "OK" && est(0) == FECHADA, "RESET libera a porta");
}

static void cenarioFimDuploEmOperacao() {
  ligar(0, 0);
  app("ABRIR 1");
  rodar(1000);
  B.p[0].forcaFimF = 1;
  B.p[0].forcaFimA = 1;
  rodar(100);
  VERIFICA(est(0) == FALHA && !strcmp(porta[0].falha, "FIM_DUPLO"), "duas chaves acionadas no meio do curso: FIM_DUPLO");
  rodar(300);
  VERIFICA(dirMotor(0) == 0 || sim::duty[PINO_EN[0]] < 150, "motor não força a porta na falha");
}

static void cenarioLimiteDeTempo() {
  ligar(0, 0);
  // padrão de fábrica: sem limite (o motor só para na chave)
  VERIFICA(limiteCursoS == 0, "LIMITE de fábrica = 0 (sem limite)");
  app("ABRIR 1");
  rodar(1000);
  B.p[0].travada = true;     // porta presa no meio do curso
  rodar(20000);
  VERIFICA(est(0) == ABRINDO, "sem LIMITE, a porta presa continua ABRINDO");
  app("PARAR 1");
  B.p[0].travada = false;
  // com LIMITE 10 s
  serial("LIMITE 10");
  VERIFICA(limiteCursoS == 10 && sim::nvs["limite"] == 10, "LIMITE 10 aceito e salvo na memória");
  B.p[0].travada = true;
  app("ABRIR 1");
  marcar();
  long t = rodarAte([] { return est(0) == FALHA; }, 15000);
  VERIFICA(t >= 9900 && t <= 10100, "TIMEOUT_ABRIR depois de 10 s");
  VERIFICA(!strcmp(porta[0].falha, "TIMEOUT_ABRIR"), "código TIMEOUT_ABRIR");
  B.p[0].travada = false;
  VERIFICA(app("ABRIR 1") == "OK" && est(0) == ABRINDO, "TIMEOUT sai com um novo ABRIR, sem RESET");
  VERIFICA(rodarAte([] { return est(0) == ABERTA; }, 6000) > 0, "e a porta termina de abrir");
  // fechar com a porta presa no meio do curso
  app("FECHAR 1");
  rodar(1000);
  B.p[0].travada = true;
  t = rodarAte([] { return est(0) == FALHA; }, 15000);
  VERIFICA(t >= 8900 && t <= 9100 && !strcmp(porta[0].falha, "TIMEOUT_FECHAR"), "TIMEOUT_FECHAR 10 s depois do FECHAR");
  // valores fora da faixa e origem
  marcar();
  serial("LIMITE 200");
  VERIFICA(limiteCursoS == 10, "LIMITE 200 recusado (máximo 120 s)");
  VERIFICA(app("LIMITE 0") == "NAO_PERMITIDO", "LIMITE não pode ser mudado pelo app");
}

static void cenarioSegurarECorrigir() {
  ligar(0, 0);
  app("ABRIR 1");
  rodarAte([] { return est(0) == ABERTA; }, 6000);
  rodar(2000);
  double p = B.p[0].pos;
  rodar(10000);
  VERIFICA(std::fabs(B.p[0].pos - p) < 1 && B.p[0].pos >= CURSO_MM - 2, "com SEGURAR 100 (fábrica) a porta não escorrega");
  // força de segurar fraca demais: a porta escorrega e solta a chave de cima
  serial("SEGURAR 0");   // só freio
  VERIFICA(pwmSegurar == 0 && sim::nvs["segurar"] == 0, "SEGURAR 0 salvo");
  marcar();
  int correcoes = 0;
  bool subindo = false;
  double menor = CURSO_MM;
  for (int k = 0; k < 15000; k += 2) {
    loop();
    if (B.p[0].pos < menor) menor = B.p[0].pos;
    bool s = dirMotor(0) == +1 && sim::duty[PINO_EN[0]] == PWM_ABRIR;
    if (s && !subindo) correcoes++;
    subindo = s;
  }
  VERIFICA(correcoes >= 1, "porta que escorrega é levantada de novo até a chave");
  VERIFICA(menor > CURSO_MM - 20, "a porta nunca escorrega mais de 20 mm");
  VERIFICA(est(0) == ABERTA, "continua ABERTA para o app durante a correção");
  ACHADO(!(dirMotor(0) == +1 && sim::duty[PINO_EN[0]] == PWM_ABRIR),
         "com SEGURAR 0, depois da correção o motor continua ligado em PWM máximo contra o topo");
}

static void cenarioBotoesFisicos() {
  ligar(0, 0);
  auto apertar = [](int i, uint32_t ms) { B.botao[i] = true; rodar(ms); B.botao[i] = false; rodar(60); };
  marcar();
  apertar(0, 100);
  VERIFICA(est(0) == ABRINDO, "botão 1 abre a porta de entrada");
  auto r = eventos("RESP");
  VERIFICA(!r.empty() && campo(r.back(), "orig") == "BOTAO" && campo(r.back(), "cmd") == "ALTERNAR", "resposta com origem BOTAO");
  rodar(500);
  apertar(0, 100);
  VERIFICA(est(0) == PARADA, "botão 1 com a porta em movimento: para");
  apertar(0, 100);
  VERIFICA(est(0) == ABRINDO, "de novo: volta a abrir");
  rodarAte([] { return est(0) == ABERTA; }, 6000);
  apertar(1, 100);
  VERIFICA(est(1) == FECHADA && motorParado(1), "botão 2 respeita o intertravamento");
  apertar(0, 100);
  VERIFICA(est(0) == FECHANDO, "botão 1 com a porta aberta: fecha");
  rodarAte([] { return est(0) == FECHADA; }, 6000);
  // botões 1 e 2 juntos por 2 s = RESET
  B.p[1].travada = true;
  app("ABRIR 2");
  rodarAte([] { return est(1) == FALHA; }, 8000);
  B.p[1].travada = false;
  marcar();
  B.botao[0] = B.botao[1] = true;
  rodar(2200);
  B.botao[0] = B.botao[1] = false;
  rodar(100);
  bool reset = false;
  for (auto& j : eventos("RESP")) if (campo(j, "cmd") == "RESET" && campo(j, "orig") == "BOTAO") reset = true;
  VERIFICA(reset && est(1) == FECHADA, "botões 1 e 2 juntos por 2 s fazem RESET");
  VERIFICA(est(0) == FECHADA, "e o RESET pelos botões não abre nenhuma porta");
}

static void cenarioChaveDesligada() {
  ligar(0, 0);
  serial("CHAVE 1 CIMA DESLIGA");
  VERIFICA(!chaveLigada[0][0] && sim::nvs["ca1"] == 0, "chave de cima da porta 1 desligada e salva");
  serial("CHAVE 1 BAIXO DESLIGA");
  VERIFICA(chaveLigada[0][1], "não deixa desligar as duas chaves da mesma porta");
  app("ABRIR 1");
  long t = rodarAte([] { return est(0) == ABERTA; }, 8000);
  VERIFICA(t >= 2900 && t <= 3100, "sem a chave de cima, abre pelo tempo de curso (3 s)");
  VERIFICA(app("CHAVE 1 CIMA LIGA") == "NAO_PERMITIDO", "CHAVE não pode ser mudada pelo app");
  serial("CHAVE 1 CIMA LIGA");
  VERIFICA(chaveLigada[0][0], "chave religada");
}

static void cenarioComandos() {
  ligar(0, 0);
  VERIFICA(app("PING") == "OK", "PING");
  VERIFICA(app("XYZ") == "INVALIDO", "comando desconhecido: INVALIDO");
  VERIFICA(app("ABRIR 3") == "PORTA_INVALIDA", "porta 3 não existe");
  VERIFICA(app("ABRIR") == "PORTA_INVALIDA", "ABRIR sem porta");
  VERIFICA(app("PARAR X") == "PORTA_INVALIDA", "PARAR com porta inválida");
  VERIFICA(app("abrir 1") == "OK", "aceita minúsculas");
  app("PARAR 1");
  marcar();
  BLECharacteristic escrita("x", 0);
  escrita.valor = "#42 FECHAR 1";
  static_cast<BLECharacteristicCallbacks*>(&cbComando)->onWrite(&escrita);
  rodar(6);
  auto r = eventos("RESP");
  VERIFICA(!r.empty() && campo(r.back(), "id") == "42" && campo(r.back(), "p") == "1", "resposta devolve o #id do app");
  VERIFICA(app("#7") == "INVALIDO", "#id sem comando");
  VERIFICA(app("JOG 1 SOBE") == "NAO_PERMITIDO", "JOG só pela serial");
  VERIFICA(app("TEMPO 1000 1000") == "NAO_PERMITIDO", "TEMPO só pela serial");
  VERIFICA(app("ABRIR:1") != "INVALIDO", "aceita ':' como separador");
  // STATUS publica o estado também na serial
  marcar();
  serial("STATUS");
  auto e = linhasNovas("EST ");
  VERIFICA(!e.empty() && campo(e.back(), "p1").size() > 0, "STATUS pela serial imprime o estado");
  // DIAG, AJUDA e TESTE só imprimem
  marcar();
  serial("DIAG");
  VERIFICA(Serial.saidaTexto.find("Porta 1:", g_cursor) != std::string::npos, "DIAG mostra as portas");
  serial("AJUDA");
  VERIFICA(Serial.saidaTexto.find("Comandos (app e serial)", g_cursor) != std::string::npos, "AJUDA lista os comandos");
  // entradas de lixo (ficam fora das amostras de JSON; o resultado é conferido aqui)
  g_fimAmostras = Serial.saidaTexto.size();
  g_fimNotificacoes = sim::notificacoes.size();
  std::string longo(200, 'A');
  VERIFICA(app(longo.c_str()) == "INVALIDO", "comando de 200 caracteres não derruba a placa");
  VERIFICA(app("ABRIR 1") == "OK" || est(0) != FALHA, "depois do lixo, a placa continua aceitando comandos");
  marcar();
  app(longo.c_str());
  auto r1 = eventos("RESP");
  ACHADO(!r1.empty() && jsonBemFormado(linhasNovas("EVT ").back()), "comando desconhecido longo sai cortado na resposta (JSON inválido)");
  marcar();
  app("X\"Y");
  auto r2 = linhasNovas("EVT ");
  ACHADO(!r2.empty() && jsonBemFormado(r2.back()), "comando com aspas é repetido sem escape na resposta (JSON inválido)");
}

static void cenarioJog() {
  ligar(0, 0);
  VERIFICA(serial("JOG 1 SOBE 500") == "OK" && est(0) == AJUSTE, "JOG pela serial: AJUSTE");
  rodar(700);
  VERIFICA(est(0) == FECHADA || est(0) == PARADA, "volta ao estado anterior depois do JOG");
  VERIFICA(B.p[0].pos > 20 && B.p[0].pos < 70, "JOG de 500 ms sobe a porta um pouco");
  VERIFICA(serial("JOG 1 LADO") == "INVALIDO", "JOG com sentido inválido");
  serial("EMERGENCIA");
  VERIFICA(serial("JOG 1 SOBE") == "EMERGENCIA", "JOG bloqueado na emergência");
}

static void cenarioMemoria() {
  ligar(0, 0);
  serial("TEMPO 2500 1800");
  VERIFICA(tempoAbrirMs == 2500 && tempoFecharMs == 1800, "TEMPO aceito");
  VERIFICA(sim::nvs["abrir"] == 2500 && sim::nvs["fechar"] == 1800, "TEMPO salvo na memória");
  serial("TEMPO 50 50");
  VERIFICA(tempoAbrirMs == 2500, "TEMPO fora da faixa recusado");
  // "reinicia" a placa: os valores do código voltam e a memória é lida de novo
  tempoAbrirMs = TEMPO_ABRIR_PADRAO;
  tempoFecharMs = TEMPO_FECHAR_PADRAO;
  carregarAjustes();
  VERIFICA(tempoAbrirMs == 2500 && tempoFecharMs == 1800, "ajustes voltam da memória depois de reiniciar");
  sim::nvs["abrir"] = 999999;   // memória corrompida
  tempoAbrirMs = TEMPO_ABRIR_PADRAO;
  carregarAjustes();
  VERIFICA(tempoAbrirMs == TEMPO_ABRIR_PADRAO, "valor absurdo na memória é ignorado");
  serial("PADRAO");
  VERIFICA(sim::nvs.empty() && tempoAbrirMs == TEMPO_ABRIR_PADRAO && limiteCursoS == LIMITE_PADRAO_S, "PADRAO limpa a memória");
}

static void cenarioMotorInvertido() {
  preparar(0, 0);
  B.p[0].fiacaoInvertida = true;   // motor ligado ao contrário na montagem
  setup();
  app("ABRIR 1");
  rodar(1500);
  VERIFICA(B.p[0].pos == 0, "motor invertido: a porta não sobe (força a chave de baixo)");
  app("PARAR 1");
  serial("RESET");
  serial("INVERTER 1");
  VERIFICA(inverterMotor[0] && sim::nvs["inv1"] == 1, "INVERTER 1 salvo");
  serial("RESET");
  app("ABRIR 1");
  VERIFICA(rodarAte([] { return est(0) == ABERTA; }, 6000) > 0, "com INVERTER a porta abre normalmente");
}

static void cenarioTesteDasChaves() {
  ligar(0, 0);
  sim::nivel[PINO_FIM_ABERTA[0]] = -1;   // fio solto na chave de cima da porta 1
  sim::aoPassarTempo = nullptr;
  marcar();
  serial("TESTE");
  const std::string& s = Serial.saidaTexto;
  size_t k = s.find("Porta 1 CIMA", g_cursor);
  VERIFICA(k != std::string::npos && s.find("ABERTO(1/0)", k) < s.find('\n', k), "TESTE acha o fio solto");
  k = s.find("Porta 1 BAIXO", g_cursor);
  VERIFICA(k != std::string::npos && s.find("3V3", k) < s.find('\n', k), "TESTE vê a chave de baixo em ALTO");
}

static void cenarioVarrer() {
  ligar(0, 0);
  app("ABRIR 1");
  rodar(500);
  bool reiniciou = false;
  try {
    serial("VARRER 5");
  } catch (const Reiniciou&) {
    reiniciou = true;
  }
  VERIFICA(reiniciou && ESP.reinicios == 1, "VARRER reinicia a placa no fim");
  VERIFICA(!sim::pwmLigado[PINO_EN[0]] && !sim::pwmLigado[PINO_EN[1]], "VARRER solta os motores antes de mexer nos pinos");
  VERIFICA(sim::tarefaSuspensa == 1, "VARRER suspende a tarefa do RFID");
}

static void cenarioRfid() {
  ligar(0, 0);
  rodar(500);
  VERIFICA(rfidOk, "leitor pronto");
  marcar();
  sim::tagNoCampo = {0x04, 0xa1, 0xb2, 0xc3};
  rodar(300);
  auto ev = eventos("RFID");
  VERIFICA(ev.size() == 1 && campo(ev[0], "uid") == "04A1B2C3", "tag lida: evento RFID com o UID em hexadecimal");
  VERIFICA(!strcmp(uidAtual, "04A1B2C3"), "UID do animal no estado");
  marcar();
  rodar(5000);
  VERIFICA(eventos("RFID").empty(), "animal parado no brete não gera leituras repetidas");
  marcar();
  sim::tagNoCampo = {0xde, 0xad, 0xbe, 0xef, 0x01, 0x02, 0x03};
  rodar(300);
  VERIFICA(eventos("RFID_SAIU").size() == 1 && eventos("RFID").size() == 1, "troca de animal: SAIU do antigo e RFID do novo");
  VERIFICA(campo(eventos("RFID").back(), "uid") == "DEADBEEF010203", "UID de 7 bytes");
  marcar();
  sim::tagNoCampo.clear();
  long t = rodarAte([] { return uidAtual[0] == 0; }, 4000);
  VERIFICA(t >= 1400 && t <= 1700, "tag some: RFID_SAIU depois de ~1,5 s");
  // leitor desligado (fio solto) e de volta
  marcar();
  sim::rc522Responde = false;
  t = rodarAte([] { return !rfidOk; }, 5000);
  VERIFICA(t > 0 && t <= 2200, "leitor sem resposta: RFID_ERRO em até 2,2 s");
  VERIFICA(campo(carEstado->valor, "rok") == "0", "estado do app mostra o leitor fora");
  rodar(6000);
  VERIFICA(eventos("RFID_ERRO").size() == 1, "o erro é avisado uma vez só");
  sim::rc522Responde = true;
  t = rodarAte([] { return rfidOk; }, 5000);
  VERIFICA(t > 0, "leitor volta sozinho: RFID_OK");
  // ruído dos motores reinicia o chip (antena desligada)
  marcar();
  uint32_t reinicios = rfidReinicios;
  sim::rc522AntenaLigada = false;
  rodar(3000);
  VERIFICA(rfidReinicios == reinicios + 1 && rfidOk, "chip reiniciado por ruído é reconfigurado sozinho");
  VERIFICA(eventos("RFID_ERRO").size() == 1 && eventos("RFID_OK").size() == 1, "avisa o erro e a volta");
  // filtro do UID (só hexadecimal vai para o JSON)
  rfidEnviar(TR_CHEGOU, "ab\"}x9");
  marcar();
  rodar(10);
  VERIFICA(!strcmp(uidAtual, "AB9"), "UID com caracteres estranhos é filtrado antes do JSON");
}

static void cenarioBluetooth() {
  ligar(0, 0);
  sim::tagNoCampo = {0x11, 0x22, 0x33, 0x44};
  rodar(500);
  sim::notificacoes.clear();
  sim::servidorBle->cb->onConnect(nullptr);   // o callback registrado no servidor
  rodar(500);
  bool inicio = false, rfid = false, est = false;
  for (auto& n : sim::notificacoes) {
    if (n.uuid == BLE_UUID_EVENTO && campo(n.valor, "ev") == "INICIO") inicio = true;
    if (n.uuid == BLE_UUID_EVENTO && campo(n.valor, "ev") == "RFID" && campo(n.valor, "uid") == "11223344") rfid = true;
    if (n.uuid == BLE_UUID_ESTADO) est = true;
  }
  VERIFICA(inicio && rfid && est, "ao conectar, o app recebe INICIO, o animal no brete e o estado");
  sim::notificacoes.clear();
  rodar(6100);
  int estados = 0;
  for (auto& n : sim::notificacoes) if (n.uuid == BLE_UUID_ESTADO) estados++;
  VERIFICA(estados >= 3 && estados <= 4, "estado enviado a cada 2 s com o app conectado");
  sim::notificacoes.clear();
  app("ABRIR 1");
  bool resp = false, ev = false;
  for (auto& n : sim::notificacoes) {
    if (campo(n.valor, "ev") == "RESP") resp = true;
    if (campo(n.valor, "ev") == "PORTA" && campo(n.valor, "e") == "ABRINDO") ev = true;
  }
  VERIFICA(resp && ev, "resposta e evento da porta chegam por notificação");
  int anuncios = sim::anuncios;
  sim::servidorBle->cb->onDisconnect(nullptr);
  rodar(300);
  VERIFICA(sim::anuncios == anuncios, "não volta a anunciar antes de 500 ms");
  rodar(400);
  VERIFICA(sim::anuncios == anuncios + 1, "volta a anunciar depois que o app desconecta");
  sim::notificacoes.clear();
  rodar(3000);
  VERIFICA(sim::notificacoes.empty(), "sem app conectado, nada é notificado");
}

// Ciclo completo de manejo, repetido: entra o animal, a porta de entrada
// fecha, o brinco é lido, a porta de saída abre, o animal sai, ela fecha.
static void cenarioCiclosDeManejo() {
  ligar(0, 0);
  rodar(500);
  std::mt19937 rnd(20261113);
  auto entre = [&](int a, int b) { return (uint32_t)std::uniform_int_distribution<int>(a, b)(rnd); };
  const int CICLOS = 200;
  int completos = 0, leituras = 0, falhas = 0, recusas = 0;
  for (int c = 0; c < CICLOS; c++) {
    marcar();
    if (app("ABRIR 1") != "OK") recusas++;
    if (rodarAte([] { return est(0) == ABERTA; }, 8000) < 0) { falhas++; continue; }
    B.animalSob[0] = true;                  // o animal passa embaixo da porta de entrada
    rodar(entre(600, 1500));
    B.animalSob[0] = false;
    rodar(entre(50, 400));
    if (c % 10 == 3) {                      // às vezes o animal volta enquanto a porta desce
      app("FECHAR 1");
      rodar(entre(200, 900));
      B.animalSob[0] = true;
      rodar(entre(300, 800));
      B.animalSob[0] = false;
      rodarAte([] { return est(0) == ABERTA; }, 8000);
      rodar(100);
    }
    if (app("FECHAR 1") != "OK") recusas++;
    if (rodarAte([] { return est(0) == FECHADA; }, 8000) < 0) { falhas++; continue; }
    uint8_t id = (uint8_t)c;
    sim::tagNoCampo = {0xE2, 0x00, (uint8_t)(c >> 8), id};
    rodar(entre(200, 1200));                // manejo: vacina, marcação...
    if (app("ABRIR 2") != "OK") recusas++;
    if (rodarAte([] { return est(1) == ABERTA; }, 8000) < 0) { falhas++; continue; }
    sim::tagNoCampo.clear();
    B.animalSob[1] = true;
    rodar(entre(600, 1500));
    B.animalSob[1] = false;
    rodar(entre(50, 400));
    if (app("FECHAR 2") != "OK") recusas++;
    if (rodarAte([] { return est(1) == FECHADA; }, 8000) < 0) { falhas++; continue; }
    rodar(1700);                            // RFID_SAIU chega 1,5 s depois
    completos++;
  }
  g_cursor = 0;                             // conta as leituras na saída inteira
  std::map<std::string, int> porUid;
  for (auto& j : eventos("RFID")) porUid[campo(j, "uid")]++;
  for (int c = 0; c < CICLOS; c++) {
    char esperado[12];
    snprintf(esperado, sizeof(esperado), "E200%02X%02X", (unsigned)(c >> 8), (unsigned)(uint8_t)c);
    if (porUid[esperado] == 1) leituras++;
  }
  char msg[96];
  snprintf(msg, sizeof(msg), "%d ciclos completos de %d", completos, CICLOS);
  VERIFICA(completos == CICLOS, msg);
  VERIFICA(falhas == 0 && recusas == 0, "nenhum comando recusado e nenhuma porta sem chegar");
  VERIFICA(leituras == CICLOS, "cada animal lido exatamente uma vez");
  VERIFICA(B.msAmbasAbertas == 0, "as porteiras nunca ficaram abertas juntas");
  VERIFICA(B.descidaSobreAnimal[0] < 6 && B.descidaSobreAnimal[1] < 6,
           "com o animal embaixo, nenhuma porta desceu mais de 6 mm");
  VERIFICA(est(0) == FECHADA && est(1) == FECHADA && strlen(porta[0].falha) == 0 && strlen(porta[1].falha) == 0,
           "termina com as duas portas fechadas e sem falha");
}

// =====================================================================
//  Amostras de JSON (validadas por validar_json_final.py)
// =====================================================================
static void salvarAmostras(const char* arquivo) {
  FILE* f = fopen(arquivo, "a");
  if (!f) return;
  const std::string s = Serial.saidaTexto.substr(0, g_fimAmostras);
  size_t pos = 0;
  while (pos < s.size()) {
    size_t fim = s.find('\n', pos);
    if (fim == std::string::npos) break;
    std::string l = s.substr(pos, fim - pos);
    if (l.rfind("EVT ", 0) == 0 || l.rfind("EST ", 0) == 0) fprintf(f, "%s\n", l.substr(4).c_str());
    pos = fim + 1;
  }
  for (size_t k = 0; k < sim::notificacoes.size() && k < g_fimNotificacoes; k++)
    fprintf(f, "%s\n", sim::notificacoes[k].valor.c_str());
  if (carEstado) fprintf(f, "%s\n", carEstado->valor.c_str());
  fclose(f);
}

struct Cenario { const char* nome; void (*f)(); };
static const Cenario CENARIOS[] = {
    {"partida", cenarioPartida},
    {"partida com portas no meio e abertas", cenarioPartidaPortasNoMeioEAbertas},
    {"partida com falha", cenarioPartidaComFalhas},
    {"partida com botao apertado", cenarioPartidaComBotaoApertado},
    {"partida com parada apertada", cenarioPartidaComParadaApertada},
    {"abrir e fechar", cenarioAbrirEFechar},
    {"parar no meio", cenarioPararNoMeio},
    {"intertravamento", cenarioIntertravamento},
    {"obstaculo", cenarioObstaculo},
    {"emergencia pelo botao", cenarioEmergenciaPeloBotao},
    {"emergencia pelo app", cenarioEmergenciaPeloApp},
    {"fio da parada rompido", cenarioFioDaParadaRompido},
    {"falha FIM_PRESO", cenarioFalhaChavePresa},
    {"falha FIM_DUPLO", cenarioFimDuploEmOperacao},
    {"limite de tempo", cenarioLimiteDeTempo},
    {"segurar e corrigir", cenarioSegurarECorrigir},
    {"botoes fisicos", cenarioBotoesFisicos},
    {"chave desligada", cenarioChaveDesligada},
    {"comandos", cenarioComandos},
    {"jog", cenarioJog},
    {"memoria", cenarioMemoria},
    {"motor invertido", cenarioMotorInvertido},
    {"teste das chaves", cenarioTesteDasChaves},
    {"varrer", cenarioVarrer},
    {"rfid", cenarioRfid},
    {"bluetooth", cenarioBluetooth},
    {"ciclos de manejo", cenarioCiclosDeManejo},
};

int main(int argc, char** argv) {
  const char* amostras = argc > 1 ? argv[1] : "amostras_final.txt";
  remove(amostras);
  int ok = 0, falhas = 0, achados = 0, cenariosComFalha = 0;
  for (const Cenario& c : CENARIOS) {
    int canal[2];
    if (pipe(canal) != 0) return 2;
    fflush(stdout);
    pid_t pid = fork();
    if (pid == 0) {
      close(canal[0]);
      g_cenario = c.nome;
      c.f();
      salvarAmostras(amostras);
      int r[3] = {g_ok, g_falhas, g_achados};
      if (write(canal[1], r, sizeof(r)) != (ssize_t)sizeof(r)) _exit(3);
      fflush(stdout);
      _exit(0);
    }
    close(canal[1]);
    int r[3] = {0, 1, 0};
    ssize_t n = read(canal[0], r, sizeof(r));
    close(canal[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    if (n != (ssize_t)sizeof(r) || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
      printf("  FALHOU [%s]: o cenário terminou de forma anormal\n", c.nome);
      r[1] = r[1] ? r[1] : 1;
    }
    printf("- %-38s %3d OK%s\n", c.nome, r[0], r[1] ? "  <-- COM FALHAS" : "");
    achados += r[2];
    ok += r[0];
    falhas += r[1];
    if (r[1]) cenariosComFalha++;
  }
  printf("Firmware 1.5.1: %d verificacoes OK, %d falhas, %d achados para a proxima versao, em %zu cenarios\n", ok,
         falhas, achados, sizeof(CENARIOS) / sizeof(CENARIOS[0]));
  return falhas ? 1 : 0;
}
