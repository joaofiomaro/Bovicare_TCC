// =====================================================================
//  BoviCare - TESTE DE BANCADA COM PARADA (sem RFID e sem fins de curso)
//
//  Serve para testar a montagem antes de ter tudo instalado:
//    - motores (L298N), sentido de giro e freio;
//    - botões 1 e 2 (alternam abrir / fechar / parar a porta);
//    - botão de parada (contato NC) com rearme;
//    - sensores IR (leitura analógica em mV) e a reabertura automática.
//
//  NÃO precisa da biblioteca MFRC522 e NÃO usa as chaves de fim de curso:
//  o curso da porta é controlado por TEMPO: 3 s para abrir e 2,2 s para
//  fechar (comando TEMPO). Com a porta aberta (ou parada no meio), o motor
//  fica SEGURANDO com uma força baixa para ela não descer com o peso
//  (comando SEGURAR). Ao ligar, as
//  duas portas são consideradas FECHADAS (posição 0).
//
//  ATENÇÃO: sem as chaves, nada impede o motor de forçar contra o batente.
//  Comece com a CORDA SOLTA e com um tempo de curso curto; só depois
//  monte a corda e ajuste o TEMPO medindo o curso real.
//
//  Placa: ESP32 Dev Module · Monitor Serial 115200, final de linha "Nova linha".
//  Os pinos são os mesmos do firmware principal (docs/LIGACOES.md).
// =====================================================================
#include <Arduino.h>

#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  #define LEDC_V3 1
#else
  #define LEDC_V3 0
#endif

// ---------------------------------------------------------------------
// Pinos (iguais ao firmware principal)
// ---------------------------------------------------------------------
const uint8_t PINO_EN[2]     = {13, 33};   // ENA, ENB (PWM)
const uint8_t PINO_INA[2]    = {14, 26};   // IN1, IN3
const uint8_t PINO_INB[2]    = {27, 25};   // IN2, IN4
const uint8_t PINO_IR[2]     = {34, 35};   // sensores IR (analógico)
const uint8_t PINO_BOTAO[2]  = {36, 39};   // botão 1 (SP), botão 2 (SN) - contato NO
const uint8_t PINO_PARADA    = 5;          // botão de parada - contato NC
const uint8_t PINO_LED       = 2;

// ---------------------------------------------------------------------
// Parâmetros
// ---------------------------------------------------------------------
uint32_t tempoAbrirMs  = 3000;             // fechada -> aberta (ajuste com TEMPO <abrir> <fechar>)
uint32_t tempoFecharMs = 2200;             // aberta -> fechada
const uint8_t  PWM_ABRIR = 255;             // máximo
const uint8_t  PWM_FECHAR = 255;            // máximo também na descida
const uint8_t  PWM_JOG = 255;
// Força para SEGURAR a porta aberta (ou parada no meio) contra o próprio peso.
// Use o MENOR valor que segura (ajuste com SEGURAR <0-255>). 0 = só o freio.
uint8_t pwmSegurar = 100;
const uint32_t PWM_FREQ = 1000;
const uint8_t  PWM_BITS = 8;
const uint32_t FREIO_MS = 150;             // freio dinâmico ao parar
const uint32_t PAUSA_OBSTACULO_MS = 300;   // pausa antes de reabrir
const uint32_t DEBOUNCE_MS = 30;
const uint32_t REARME_MS = 3000;           // segurar a parada para rearmar
const uint16_t IR_OBSTACULO_MV = 700;      // abaixo: obstáculo
const uint16_t IR_LIVRE_MV = 1100;         // acima: livre
const bool     INTERTRAVAMENTO = true;     // só abre se a outra porta estiver fechada
// Botão de parada DESLIGADO para testar sem ele. Quando a ligação NC estiver
// conferida, troque para true e grave de novo.
const bool     USAR_BOTAO_PARADA = true;    // versão COM botão de parada (emergência)
bool inverterMotor[2] = {false, false};    // troque com o comando INVERTER <n>

// ---------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------
enum Estado : uint8_t { FECHADA, ABRINDO, ABERTA, FECHANDO, PARADA, RECUANDO, AJUSTE };
const char* NOME_ESTADO[] = {"FECHADA", "ABRINDO", "ABERTA", "FECHANDO", "PARADA", "RECUANDO", "AJUSTE"};

struct Motor {
  int8_t dir = 0;          // +1 sobe (abre), -1 desce (fecha), 0 parado
  uint8_t pwm = 0;
  bool freando = false;
  uint32_t inicioFreio = 0;
};

struct Porta {
  Estado estado = FECHADA;
  float pos = 0.0f;        // posição estimada: 0 = fechada, 1 = aberta
  uint32_t ultimaConta = 0;
  uint32_t inicioPausa = 0;
  int8_t jogDir = 0;
  uint32_t jogFim = 0;
  Estado antesJog = FECHADA;   // o JOG é ajuste: ao terminar, volta ao estado anterior
};

struct Debounce {
  bool estavel = false, bruto = false;
  uint32_t desde = 0;
  bool atualizar(bool leitura, uint32_t agora) {   // true quando o estado estável muda
    if (leitura != bruto) { bruto = leitura; desde = agora; }
    if (bruto != estavel && agora - desde >= DEBOUNCE_MS) { estavel = bruto; return true; }
    return false;
  }
};

Motor motor[2];
Porta porta[2];
Debounce dbBotao[2], dbParada;
bool obstaculo[2] = {true, true};          // começa em "obstáculo" (seguro)
uint16_t irMv[2] = {0, 0};
uint8_t irContagem[2] = {0, 0};
bool ignorarBotao[2] = {false, false};     // botão apertado no boot: ignora até soltar
bool emergencia = false;
bool paradaSoltaDesdeEmergencia = false;
uint32_t inicioRearme = 0;
bool contandoRearme = false;
bool monitorIr = false;
uint32_t ultimoMonitor = 0;

// ---------------------------------------------------------------------
// Motores
// ---------------------------------------------------------------------
void pwmIniciar(uint8_t i) {
#if LEDC_V3
  ledcAttach(PINO_EN[i], PWM_FREQ, PWM_BITS);
#else
  ledcSetup(i, PWM_FREQ, PWM_BITS);
  ledcAttachPin(PINO_EN[i], i);
#endif
}

void pwmEscrever(uint8_t i, uint8_t duty) {
#if LEDC_V3
  ledcWrite(PINO_EN[i], duty);
#else
  ledcWrite(i, duty);
#endif
}

void ligarMotor(uint8_t i, int8_t dir, uint8_t pwm) {
  bool a = dir > 0, b = dir < 0;
  if (inverterMotor[i]) { bool t = a; a = b; b = t; }
  pwmEscrever(i, 0);
  digitalWrite(PINO_INA[i], a ? HIGH : LOW);
  digitalWrite(PINO_INB[i], b ? HIGH : LOW);
  pwmEscrever(i, pwm);
  motor[i].dir = dir;
  motor[i].pwm = pwm;
}

void frearMotor(uint8_t i, uint32_t agora) {
  if (motor[i].dir == 0 && !motor[i].freando) return;
  digitalWrite(PINO_INA[i], LOW);
  digitalWrite(PINO_INB[i], LOW);
  pwmEscrever(i, 255);                     // terminais em curto: freio dinâmico
  motor[i].dir = 0;
  motor[i].freando = true;
  motor[i].inicioFreio = agora;
}

void atualizarMotor(uint8_t i, uint32_t agora) {
  if (motor[i].freando && agora - motor[i].inicioFreio >= FREIO_MS) {
    pwmEscrever(i, 0);
    motor[i].freando = false;
  }
}

// ---------------------------------------------------------------------
// Portas
// ---------------------------------------------------------------------
void mudarEstado(uint8_t i, Estado e) {
  if (porta[i].estado == e) return;
  porta[i].estado = e;
  Serial.printf("[porta %u] %s  (posicao %d%%)\n", (unsigned)(i + 1), NOME_ESTADO[e],
                (int)(porta[i].pos * 100.0f + 0.5f));
}

bool emMovimento(uint8_t i) {
  Estado e = porta[i].estado;
  return e == ABRINDO || e == FECHANDO || e == RECUANDO || e == AJUSTE;
}

void parar(uint8_t i, uint32_t agora) {
  frearMotor(i, agora);
  Estado e = porta[i].estado;
  if (e == FECHADA || e == ABERTA) return;
  if (e == AJUSTE) { mudarEstado(i, porta[i].antesJog); return; }
  if (porta[i].pos <= 0.0f) mudarEstado(i, FECHADA);
  else if (porta[i].pos >= 1.0f) mudarEstado(i, ABERTA);
  else mudarEstado(i, PARADA);
}

bool abrir(uint8_t i) {
  if (emergencia) { Serial.println("  recusado: EMERGENCIA ativa (RESET ou segure a parada 3 s)"); return false; }
  uint8_t outra = 1 - i;
  if (INTERTRAVAMENTO && porta[outra].estado != FECHADA) {
    Serial.printf("  recusado: intertravamento (porta %u nao esta FECHADA)\n", (unsigned)(outra + 1));
    return false;
  }
  if (porta[i].estado == ABERTA) { Serial.println("  porta ja ABERTA"); return false; }
  mudarEstado(i, ABRINDO);
  return true;
}

bool fechar(uint8_t i) {
  if (emergencia) { Serial.println("  recusado: EMERGENCIA ativa (RESET ou segure a parada 3 s)"); return false; }
  if (obstaculo[i]) { Serial.printf("  recusado: obstaculo no sensor IR %u\n", (unsigned)(i + 1)); return false; }
  if (porta[i].estado == FECHADA) { Serial.println("  porta ja FECHADA"); return false; }
  mudarEstado(i, FECHANDO);
  return true;
}

void alternar(uint8_t i, uint32_t agora) {
  if (emMovimento(i)) { parar(i, agora); return; }
  if (porta[i].estado == ABERTA) fechar(i);
  else abrir(i);
}

void atualizarPorta(uint8_t i, uint32_t agora) {
  Porta& p = porta[i];
  Motor& m = motor[i];
  switch (p.estado) {
    case ABRINDO:
      if (m.freando) break;
      if (m.dir == -1) { frearMotor(i, agora); break; }       // inverte: freia antes
      if (m.dir == 0) { ligarMotor(i, +1, PWM_ABRIR); p.ultimaConta = agora; break; }
      if (m.pwm != PWM_ABRIR) ligarMotor(i, +1, PWM_ABRIR);  // saindo do "segurar"
      p.pos += (float)(agora - p.ultimaConta) / (float)tempoAbrirMs;
      p.ultimaConta = agora;
      if (p.pos >= 1.0f) {
        p.pos = 1.0f;
        frearMotor(i, agora);
        mudarEstado(i, ABERTA);
      }
      break;

    case FECHANDO:
      if (obstaculo[i]) {                                     // PARADA AUTOMATICA
        Serial.printf("[porta %u] OBSTACULO durante o fechamento: freia e reabre\n", (unsigned)(i + 1));
        frearMotor(i, agora);
        p.inicioPausa = agora;
        mudarEstado(i, RECUANDO);
        break;
      }
      if (m.freando) break;
      if (m.dir == +1) { frearMotor(i, agora); break; }
      if (m.dir == 0) { ligarMotor(i, -1, PWM_FECHAR); p.ultimaConta = agora; break; }
      p.pos -= (float)(agora - p.ultimaConta) / (float)tempoFecharMs;
      p.ultimaConta = agora;
      if (p.pos <= 0.0f) {
        p.pos = 0.0f;
        frearMotor(i, agora);
        mudarEstado(i, FECHADA);
      }
      break;

    case RECUANDO:
      if (!m.freando && agora - p.inicioPausa >= PAUSA_OBSTACULO_MS) mudarEstado(i, ABRINDO);
      break;

    case AJUSTE:
      if (m.freando) break;
      if ((m.dir != p.jogDir || m.pwm != PWM_JOG) && (int32_t)(p.jogFim - agora) > 0) { ligarMotor(i, p.jogDir, PWM_JOG); break; }
      if ((int32_t)(agora - p.jogFim) >= 0) {
        frearMotor(i, agora);
        mudarEstado(i, p.antesJog);
      }
      break;

    case ABERTA:
    case PARADA:
      // SEGURAR: força baixa para cima, para a porta não descer com o peso.
      if (m.freando || p.pos <= 0.0f) break;
      if (pwmSegurar == 0) break;
      if (m.dir != +1 || m.pwm != pwmSegurar) ligarMotor(i, +1, pwmSegurar);
      break;

    default:
      break;
  }
}

// ---------------------------------------------------------------------
// Entradas
// ---------------------------------------------------------------------
void lerSensoresIr() {
  for (uint8_t i = 0; i < 2; i++) {
    uint32_t mv = analogReadMilliVolts(PINO_IR[i]);
    irMv[i] = mv > 65535 ? 65535 : (uint16_t)mv;
    bool novo = obstaculo[i];
    if (irMv[i] < IR_OBSTACULO_MV) novo = true;
    else if (irMv[i] > IR_LIVRE_MV) novo = false;
    // confirma após 3 leituras seguidas iguais (~3 laços)
    if (novo != obstaculo[i]) {
      if (++irContagem[i] >= 3) {
        obstaculo[i] = novo;
        irContagem[i] = 0;
        Serial.printf("[IR %u] %s (%u mV)\n", (unsigned)(i + 1), novo ? "OBSTACULO" : "livre", (unsigned)irMv[i]);
      }
    } else {
      irContagem[i] = 0;
    }
  }
}

void ativarEmergencia(uint32_t agora) {
  emergencia = true;
  contandoRearme = false;
  paradaSoltaDesdeEmergencia = false;
  for (uint8_t i = 0; i < 2; i++) parar(i, agora);
  Serial.println("*** EMERGENCIA: portas paradas. Rearme: solte e segure a parada 3 s, ou digite RESET ***");
}

void rearmar() {
  emergencia = false;
  contandoRearme = false;
  Serial.println("*** Rearmado: comandos liberados ***");
}

void lerBotoes(uint32_t agora) {
  // Botões 1 e 2 (contato NO): apertado = ALTO
  for (uint8_t i = 0; i < 2; i++) {
    bool apertado = digitalRead(PINO_BOTAO[i]) == HIGH;
    if (dbBotao[i].atualizar(apertado, agora)) {
      if (!dbBotao[i].estavel) { ignorarBotao[i] = false; continue; }
      if (ignorarBotao[i]) continue;
      Serial.printf("[botao %u] apertado\n", (unsigned)(i + 1));
      alternar(i, agora);
    }
  }
  // Parada (contato NC): solto = ALTO, apertado ou fio rompido = BAIXO
  if (!USAR_BOTAO_PARADA) return;
  bool paradaApertada = digitalRead(PINO_PARADA) == LOW;
  if (dbParada.atualizar(paradaApertada, agora)) {
    if (dbParada.estavel) {
      Serial.println("[parada] apertada");
      if (!emergencia) ativarEmergencia(agora);
      else if (paradaSoltaDesdeEmergencia) { contandoRearme = true; inicioRearme = agora; }
    } else {
      Serial.println("[parada] solta");
      if (emergencia) paradaSoltaDesdeEmergencia = true;
      contandoRearme = false;
    }
  }
  if (emergencia && contandoRearme && dbParada.estavel && agora - inicioRearme >= REARME_MS) rearmar();
}

// ---------------------------------------------------------------------
// Serial
// ---------------------------------------------------------------------
void imprimirAjuda() {
  Serial.println();
  Serial.println("Comandos (uma linha por comando):");
  Serial.println("  STATUS              estado das portas, botoes e sensores");
  Serial.println("  ABRIR 1|2           abre a porta");
  Serial.println("  FECHAR 1|2          fecha a porta");
  Serial.println("  PARAR [1|2]         para uma porta ou as duas");
  Serial.println("  JOG 1|2 SOBE|DESCE [ms]   gira o motor por pouco tempo (padrao 300 ms)");
  Serial.println("  INVERTER 1|2        inverte o sentido de giro do motor (teste)");
  Serial.println("  TEMPO <abrir> <fechar>   tempos de curso em ms (ex.: TEMPO 4500 3000)");
  Serial.println("  ZERAR 1|2           marca a porta como FECHADA na posicao atual");
  Serial.println("  SEGURAR <0-255>     forca para segurar a porta aberta (0 = so freio)");
  Serial.println("  MONITOR             liga/desliga a tensao dos IR a cada 0,5 s");
  Serial.println("  RESET               rearma a emergencia (parada precisa estar solta)");
  Serial.printf("  tempos atuais: abrir %lu ms, fechar %lu ms · segurar %u\n\n", (unsigned long)tempoAbrirMs, (unsigned long)tempoFecharMs, (unsigned)pwmSegurar);
}

void imprimirStatus() {
  Serial.println();
  for (uint8_t i = 0; i < 2; i++) {
    bool segurando = (porta[i].estado == ABERTA || porta[i].estado == PARADA) && motor[i].dir > 0;
    const char* m = motor[i].freando ? "FREANDO" : (segurando ? "SEGURA" : (motor[i].dir > 0 ? "SOBE" : (motor[i].dir < 0 ? "DESCE" : "PARADO")));
    Serial.printf("Porta %u: %-8s  posicao %3d%%  motor %-7s  inverter=%d  IR %4u mV %s\n",
                  (unsigned)(i + 1), NOME_ESTADO[porta[i].estado], (int)(porta[i].pos * 100.0f + 0.5f),
                  m, inverterMotor[i] ? 1 : 0, (unsigned)irMv[i],
                  obstaculo[i] ? "OBSTACULO" : "livre");
  }
  Serial.printf("Botao 1: %s   Botao 2: %s   Parada: %s (GPIO5 = %s)\n",
                dbBotao[0].estavel ? "APERTADO" : "solto", dbBotao[1].estavel ? "APERTADO" : "solto",
                !USAR_BOTAO_PARADA ? "DESLIGADA" : (dbParada.estavel ? "APERTADA" : "solta"),
                digitalRead(PINO_PARADA) ? "ALTO" : "BAIXO");
  Serial.printf("Emergencia: %s\n\n", emergencia ? "SIM" : "nao");
}

int lerPorta(const char* t) {
  if (!t) return -1;
  if (!strcmp(t, "1")) return 0;
  if (!strcmp(t, "2")) return 1;
  return -1;
}

void executar(char* linha, uint32_t agora) {
  for (char* c = linha; *c; c++) *c = toupper((unsigned char)*c);
  const char* sep = " \t:=,;";
  char* cmd = strtok(linha, sep);
  if (!cmd) return;
  char* a1 = strtok(nullptr, sep);
  char* a2 = strtok(nullptr, sep);
  char* a3 = strtok(nullptr, sep);
  int p = lerPorta(a1);

  if (!strcmp(cmd, "AJUDA") || !strcmp(cmd, "HELP") || !strcmp(cmd, "?")) imprimirAjuda();
  else if (!strcmp(cmd, "STATUS") || !strcmp(cmd, "DIAG") || !strcmp(cmd, "S")) imprimirStatus();
  else if (!strcmp(cmd, "ABRIR")) { if (p < 0) Serial.println("  use: ABRIR 1|2"); else abrir(p); }
  else if (!strcmp(cmd, "FECHAR")) { if (p < 0) Serial.println("  use: FECHAR 1|2"); else fechar(p); }
  else if (!strcmp(cmd, "PARAR")) {
    if (p < 0) { parar(0, agora); parar(1, agora); } else parar(p, agora);
  }
  else if (!strcmp(cmd, "JOG")) {
    if (p < 0 || !a2 || (strcmp(a2, "SOBE") && strcmp(a2, "DESCE"))) { Serial.println("  use: JOG 1|2 SOBE|DESCE [ms]"); return; }
    if (emergencia) { Serial.println("  recusado: EMERGENCIA ativa"); return; }
    if (emMovimento(p)) { Serial.println("  recusado: porta em movimento (PARAR antes)"); return; }
    long ms = a3 ? atol(a3) : 300;
    if (ms < 20) ms = 20;
    if (ms > 2000) ms = 2000;
    porta[p].jogDir = strcmp(a2, "SOBE") == 0 ? +1 : -1;
    porta[p].jogFim = agora + (uint32_t)ms;
    Serial.printf("  JOG porta %d %s por %ld ms\n", p + 1, a2, ms);
    porta[p].antesJog = porta[p].estado;
    mudarEstado(p, AJUSTE);
  }
  else if (!strcmp(cmd, "INVERTER")) {
    if (p < 0) { Serial.println("  use: INVERTER 1|2"); return; }
    if (emMovimento(p)) { Serial.println("  recusado: porta em movimento"); return; }
    inverterMotor[p] = !inverterMotor[p];
    Serial.printf("  motor %d: inverter = %d  (no firmware principal: INVERTER_MOTOR_%d %d)\n",
                  p + 1, inverterMotor[p] ? 1 : 0, p + 1, inverterMotor[p] ? 1 : 0);
  }
  else if (!strcmp(cmd, "TEMPO")) {
    long ab = a1 ? atol(a1) : 0;
    long fe = a2 ? atol(a2) : ab;
    if (ab < 100 || ab > 20000 || fe < 100 || fe > 20000) { Serial.println("  use: TEMPO <abrir ms> <fechar ms>  (100 a 20000)"); return; }
    if (emMovimento(0) || emMovimento(1)) { Serial.println("  recusado: pare as portas antes"); return; }
    tempoAbrirMs = (uint32_t)ab;
    tempoFecharMs = (uint32_t)fe;
    Serial.printf("  tempos: abrir %lu ms, fechar %lu ms\n", (unsigned long)tempoAbrirMs, (unsigned long)tempoFecharMs);
  }
  else if (!strcmp(cmd, "ZERAR")) {
    if (p < 0) { Serial.println("  use: ZERAR 1|2"); return; }
    if (emMovimento(p)) { Serial.println("  recusado: porta em movimento"); return; }
    frearMotor(p, agora);
    porta[p].pos = 0.0f;
    porta[p].estado = PARADA;
    mudarEstado(p, FECHADA);
  }
  else if (!strcmp(cmd, "SEGURAR")) {
    if (!a1) { Serial.printf("  segurar atual = %u  (use: SEGURAR <0-255>)\n", (unsigned)pwmSegurar); return; }
    long v = atol(a1);
    if (v < 0 || v > 255) { Serial.println("  use: SEGURAR <0-255>"); return; }
    pwmSegurar = (uint8_t)v;
    if (pwmSegurar == 0) {
      for (uint8_t i = 0; i < 2; i++)
        if ((porta[i].estado == ABERTA || porta[i].estado == PARADA) && motor[i].dir != 0) frearMotor(i, agora);
    }
    Serial.printf("  segurar = %u%s\n", (unsigned)pwmSegurar, pwmSegurar ? "" : " (desligado: so freio)");
  }
  else if (!strcmp(cmd, "MONITOR")) {
    monitorIr = !monitorIr;
    Serial.printf("  monitor dos IR %s\n", monitorIr ? "LIGADO" : "desligado");
  }
  else if (!strcmp(cmd, "RESET")) {
    if (!emergencia) Serial.println("  nao ha emergencia ativa");
    else if (dbParada.estavel) Serial.println("  solte o botao de parada antes do RESET");
    else rearmar();
  }
  else Serial.println("  comando desconhecido (digite AJUDA)");
}

void lerSerial(uint32_t agora) {
  static char buf[64];
  static uint8_t n = 0;
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\r') continue;
    if (c == '\n') { buf[n] = 0; if (n) executar(buf, agora); n = 0; }
    else if (n < sizeof(buf) - 1) buf[n++] = c;
  }
}

// ---------------------------------------------------------------------
// LED: aceso = motor girando · pisca rápido = emergência · pisca lento = ok
// ---------------------------------------------------------------------
void atualizarLed(uint32_t agora) {
  bool aceso;
  if (emergencia) aceso = (agora / 100) % 2;
  else if (emMovimento(0) || emMovimento(1)) aceso = true;
  else aceso = (agora / 1000) % 2;
  digitalWrite(PINO_LED, aceso ? HIGH : LOW);
}

// ---------------------------------------------------------------------
void setup() {
  // 1) Motores parados antes de tudo
  for (uint8_t i = 0; i < 2; i++) {
    pinMode(PINO_INA[i], OUTPUT);
    pinMode(PINO_INB[i], OUTPUT);
    digitalWrite(PINO_INA[i], LOW);
    digitalWrite(PINO_INB[i], LOW);
    pinMode(PINO_EN[i], OUTPUT);
    digitalWrite(PINO_EN[i], LOW);
    pwmIniciar(i);
    pwmEscrever(i, 0);
  }
  // 2) Entradas
  pinMode(PINO_BOTAO[0], INPUT);            // 36/39: pull-down externo de 10 kΩ
  pinMode(PINO_BOTAO[1], INPUT);
  pinMode(PINO_PARADA, INPUT_PULLDOWN);     // NC ao 3,3 V + pull-down
  pinMode(PINO_IR[0], INPUT);
  pinMode(PINO_IR[1], INPUT);
  analogReadResolution(12);
  analogSetPinAttenuation(PINO_IR[0], ADC_11db);
  analogSetPinAttenuation(PINO_IR[1], ADC_11db);
  pinMode(PINO_LED, OUTPUT);

  Serial.begin(115200);
  delay(300);
  Serial.println();
  Serial.println("==============================================");
  Serial.println(" BoviCare - TESTE DE BANCADA (COM parada)");
  Serial.println(" sem RFID e sem fins de curso (curso por tempo)");
  Serial.println(" Portas consideradas FECHADAS ao ligar.");
  Serial.println(" Comece com a CORDA SOLTA.");
  if (!USAR_BOTAO_PARADA) Serial.println(" ! BOTAO DE PARADA DESLIGADO (USAR_BOTAO_PARADA = false)");
  Serial.println("==============================================");

  // Estado inicial das entradas (sem disparar eventos)
  uint32_t agora = millis();
  for (uint8_t i = 0; i < 2; i++) {
    bool ap = digitalRead(PINO_BOTAO[i]) == HIGH;
    dbBotao[i].estavel = dbBotao[i].bruto = ap;
    ignorarBotao[i] = ap;
    if (ap) Serial.printf("! botao %u lido como APERTADO no boot: confira o resistor de 10 kOhm\n", (unsigned)(i + 1));
  }
  bool parAp = USAR_BOTAO_PARADA && digitalRead(PINO_PARADA) == LOW;
  dbParada.estavel = dbParada.bruto = parAp;
  for (uint8_t k = 0; k < 5; k++) { lerSensoresIr(); delay(5); }
  if (parAp) {
    Serial.println("! botao de PARADA lido como APERTADO: confira a ligacao NC (3,3 V -> NC -> GPIO5)");
    ativarEmergencia(agora);
  }
  imprimirAjuda();
  imprimirStatus();
}

void loop() {
  uint32_t agora = millis();
  lerSensoresIr();
  lerBotoes(agora);
  lerSerial(agora);
  for (uint8_t i = 0; i < 2; i++) {
    atualizarPorta(i, agora);
    atualizarMotor(i, agora);
  }
  if (monitorIr && agora - ultimoMonitor >= 500) {
    ultimoMonitor = agora;
    Serial.printf("IR1 %4u mV %-9s | IR2 %4u mV %s\n", (unsigned)irMv[0], obstaculo[0] ? "OBSTACULO" : "livre",
                  (unsigned)irMv[1], obstaculo[1] ? "OBSTACULO" : "livre");
  }
  atualizarLed(agora);
  delay(2);
}
