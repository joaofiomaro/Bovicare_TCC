// =====================================================================
//  BoviCare - Sistema Integrado de Gestão Pecuária
//  FIRMWARE FINAL DO BRETE - arquivo único, com TUDO
//
//  Autores: João Pedro Fiomaro Santos e Leonardo Moreira Trento Pinge
//  Orientador: Prof. Renato Ferrari da Costa
//
//  O que faz:
//    - controla as 2 portas guilhotina (L298N + motores JGB37);
//    - para cada porta nas chaves de fim de curso (aberta / fechada); o tempo
//      de curso (3 s / 2,2 s) estima a posição e serve de limite de segurança;
//    - SEGURA a porta aberta (ou parada no meio) contra o próprio peso e, se
//      ela escorregar e soltar a chave de cima, sobe de novo sozinha;
//    - detecta falhas das chaves (FIM_DUPLO, FIM_PRESO, TIMEOUT_ABRIR,
//      TIMEOUT_FECHAR): a porta fica em FALHA até o RESET;
//    - guarda os ajustes da serial (TEMPO, SEGURAR, INVERTER) na memória;
//    - parada automática pelos sensores IR: obstáculo no fechamento -> freia e reabre;
//    - botões 1 e 2 alternam a porta (abre / fecha / para);
//    - botão de parada (contato NC) -> emergência, com rearme;
//    - intertravamento: uma porta só abre com a outra fechada;
//    - leitor RFID RC522: informa ao app a tag que chegou e quando saiu
//      (roda numa tarefa separada, no núcleo 0: nunca atrasa as portas);
//    - Bluetooth Low Energy para o aplicativo (protocolo em docs/PROTOCOLO_BLE.md);
//    - os mesmos comandos pelo Monitor Serial (115200, final de linha "Nova linha").
//
//  Biblioteca necessária (Arduino IDE > Gerenciar Bibliotecas):
//    "MFRC522" by GithubCommunity, versão 1.4.12 ou mais nova (NÃO a "MFRC522v2").
//  O Bluetooth já vem com a placa ESP32.
//  Arduino IDE: placa "ESP32 Dev Module", Partition Scheme "Huge APP".
//  Este arquivo deve ficar numa pasta chamada BoviCare_Brete_Final.
// =====================================================================
#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#if !defined(CONFIG_NIMBLE_ENABLED)
  #include <BLE2902.h>
#endif

#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  #define LEDC_V3 1
#else
  #define LEDC_V3 0
#endif

#define FIRMWARE_VERSAO "1.3.0"

// =====================================================================
//  CONFIGURAÇÃO (ajuste aqui)
// =====================================================================
const bool     USAR_BOTAO_PARADA  = true;   // false = ignora o botão de parada (só para testes)
const bool     USAR_FINS_DE_CURSO = true;   // chaves NF ao GND (false = só por tempo)
const bool     USAR_RFID          = true;   // false = não usa o leitor RC522
const bool     INTERTRAVAMENTO    = true;   // só abre se a outra porta estiver fechada

// Valores de fábrica. Os ajustes feitos pela serial (TEMPO, SEGURAR, INVERTER)
// ficam salvos na memória da placa e valem mais que estes; PADRAO volta a estes.
const uint32_t TEMPO_ABRIR_PADRAO  = 3000;  // fechada -> aberta (ms)
const uint32_t TEMPO_FECHAR_PADRAO = 2200;  // aberta  -> fechada (ms)
const uint8_t  SEGURAR_PADRAO      = 100;   // força para segurar a porta aberta (0 = só freio)
const bool     INVERTER_PADRAO[2]  = {false, false};
uint32_t tempoAbrirMs  = TEMPO_ABRIR_PADRAO;
uint32_t tempoFecharMs = TEMPO_FECHAR_PADRAO;
uint8_t  pwmSegurar    = SEGURAR_PADRAO;

const uint8_t  PWM_ABRIR  = 255;            // máximo
const uint8_t  PWM_FECHAR = 255;            // máximo
const uint8_t  PWM_JOG    = 255;
bool inverterMotor[2] = {INVERTER_PADRAO[0], INVERTER_PADRAO[1]};   // sentido de giro (INVERTER pela serial)

const uint32_t FREIO_MS           = 150;    // freio dinâmico ao parar
const uint32_t PAUSA_OBSTACULO_MS = 300;    // pausa antes de reabrir
const uint32_t DEBOUNCE_MS        = 30;
const uint32_t REARME_MS          = 3000;   // segurar a parada para rearmar
const uint16_t IR_OBSTACULO_MV    = 700;    // abaixo: obstáculo
const uint16_t IR_LIVRE_MV        = 1100;   // acima: livre
const uint32_t ESTADO_PERIODO_MS  = 2000;   // ESTADO enviado ao app a cada 2 s
const uint32_t FIM_PRESO_MS       = 1500;   // a chave de partida tem de soltar nesse tempo
const uint32_t LIMITE_EXTRA_MS    = 1000;   // limite do curso = 2 x tempo + 1 s
const uint32_t CORRECAO_ESPERA_MS = 500;    // pausa mínima entre duas correções da porta aberta
const uint32_t RFID_PERIODO_MS    = 80;     // intervalo entre leituras do RC522
const uint32_t RFID_AUSENCIA_MS   = 1500;   // sem leitura por esse tempo = tag saiu
const uint32_t RFID_VERIFICA_MS   = 2000;   // checagem de saúde do RC522

#define BLE_NOME          "BoviCare-Brete"
#define BLE_UUID_SERVICO  "b0c1ca5e-0001-4b8e-9d3a-6f2e1c7a9d10"
#define BLE_UUID_COMANDO  "b0c1ca5e-0002-4b8e-9d3a-6f2e1c7a9d10"   // escrita
#define BLE_UUID_ESTADO   "b0c1ca5e-0003-4b8e-9d3a-6f2e1c7a9d10"   // leitura + notificação
#define BLE_UUID_EVENTO   "b0c1ca5e-0004-4b8e-9d3a-6f2e1c7a9d10"   // notificação
#define BLE_MTU           247

// =====================================================================
//  PINOS (iguais a docs/LIGACOES.md)
// =====================================================================
const uint8_t PINO_EN[2]        = {13, 33};   // ENA, ENB (PWM)
const uint8_t PINO_INA[2]       = {14, 26};   // IN1, IN3
const uint8_t PINO_INB[2]       = {27, 25};   // IN2, IN4
const uint8_t PINO_IR[2]        = {34, 35};   // sensores IR (analógico)
const uint8_t PINO_BOTAO[2]     = {36, 39};   // botão 1 (SP), botão 2 (SN) - contato NO
const uint8_t PINO_PARADA       = 5;          // botão de parada - contato NC
const uint8_t PINO_FIM_ABERTA[2]  = {16, 4};  // chaves (opcional)
const uint8_t PINO_FIM_FECHADA[2] = {17, 32};
const uint8_t PINO_LED          = 2;
const uint8_t PINO_RFID_SS      = 21;         // RC522 SDA   (alimentar em 3,3 V!)
const uint8_t PINO_RFID_SCK     = 18;         // RC522 SCK
const uint8_t PINO_RFID_MOSI    = 23;         // RC522 MOSI
const uint8_t PINO_RFID_MISO    = 19;         // RC522 MISO
const uint8_t PINO_RFID_RST     = 22;         // RC522 RST   (IRQ não é ligado)

// =====================================================================
//  TIPOS E ESTADO
// =====================================================================
enum Estado : uint8_t { FECHADA, ABRINDO, ABERTA, FECHANDO, PARADA, RECUANDO, AJUSTE, FALHA };
const char* NOME_ESTADO[] = {"FECHADA", "ABRINDO", "ABERTA", "FECHANDO", "PARADA", "RECUANDO", "AJUSTE", "FALHA"};

enum Origem : uint8_t { ORIG_APP, ORIG_SERIAL, ORIG_BOTAO, ORIG_SISTEMA };
const char* NOME_ORIGEM[] = {"APP", "SERIAL", "BOTAO", "SISTEMA"};

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
  uint32_t inicioMov = 0;
  uint32_t inicioPausa = 0;
  int8_t jogDir = 0;
  uint32_t jogFim = 0;
  Estado antesJog = FECHADA;
  const char* falha = "";  // código da falha ("" = sem falha)
  uint32_t inicioGiro = 0; // quando o motor começou a girar no curso atual
  bool corrigindo = false; // porta aberta escorregou: subindo de volta até a chave
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

Preferences memoria;
Motor motor[2];
Porta porta[2];
Debounce dbBotao[2], dbParada, dbFimA[2], dbFimF[2];
bool obstaculo[2] = {true, true};          // começa em "obstáculo" (seguro)
uint16_t irMv[2] = {0, 0};
uint8_t irContagem[2] = {0, 0};
bool ignorarBotao[2] = {false, false};
bool emergencia = false;
bool paradaSoltaDesdeEmergencia = false;
bool contandoRearme = false;
uint32_t inicioRearme = 0;
bool estadoMudou = true;
uint32_t ultimoEstado = 0;
bool monitorIr = false;
uint32_t ultimoMonitor = 0;

// Ajustes salvos na memória (NVS)
void salvarAjustes() {
  memoria.putUInt("abrir", tempoAbrirMs);
  memoria.putUInt("fechar", tempoFecharMs);
  memoria.putUChar("segurar", pwmSegurar);
  memoria.putBool("inv1", inverterMotor[0]);
  memoria.putBool("inv2", inverterMotor[1]);
}

void carregarAjustes() {
  memoria.begin("bovicare", false);
  uint32_t a = memoria.getUInt("abrir", TEMPO_ABRIR_PADRAO);
  uint32_t f = memoria.getUInt("fechar", TEMPO_FECHAR_PADRAO);
  if (a >= 100 && a <= 20000) tempoAbrirMs = a;
  if (f >= 100 && f <= 20000) tempoFecharMs = f;
  pwmSegurar = memoria.getUChar("segurar", SEGURAR_PADRAO);
  inverterMotor[0] = memoria.getBool("inv1", INVERTER_PADRAO[0]);
  inverterMotor[1] = memoria.getBool("inv2", INVERTER_PADRAO[1]);
}

// =====================================================================
//  BLUETOOTH
// =====================================================================
struct TextoComando { char txt[65]; };
BLECharacteristic* carEstado = nullptr;
BLECharacteristic* carEvento = nullptr;
QueueHandle_t filaComandos = nullptr;
volatile bool bleConectado = false;
volatile bool bleNovaConexao = false;
volatile bool blePrecisaAnunciar = false;
volatile uint32_t bleDesconexao = 0;

class CallbacksServidor : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { bleConectado = true; bleNovaConexao = true; }
  void onDisconnect(BLEServer*) override {
    bleConectado = false;
    blePrecisaAnunciar = true;
    bleDesconexao = millis();
  }
};

class CallbacksComando : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    auto valor = c->getValue();            // std::string (core 2.x) ou String (core 3.x)
    TextoComando t;
    size_t n = valor.length();
    if (n > sizeof(t.txt) - 1) n = sizeof(t.txt) - 1;
    memcpy(t.txt, valor.c_str(), n);
    t.txt[n] = 0;
    if (filaComandos) xQueueSend(filaComandos, &t, 0);   // executado no laço principal
  }
};

CallbacksServidor cbServidor;
CallbacksComando cbComando;

void bleIniciar() {
  filaComandos = xQueueCreate(8, sizeof(TextoComando));
  BLEDevice::init(BLE_NOME);
  BLEDevice::setMTU(BLE_MTU);
  BLEServer* servidor = BLEDevice::createServer();
  servidor->setCallbacks(&cbServidor);
  BLEService* servico = servidor->createService(BLE_UUID_SERVICO);

  BLECharacteristic* carComando = servico->createCharacteristic(
      BLE_UUID_COMANDO, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  carComando->setCallbacks(&cbComando);

  carEstado = servico->createCharacteristic(
      BLE_UUID_ESTADO, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  carEvento = servico->createCharacteristic(BLE_UUID_EVENTO, BLECharacteristic::PROPERTY_NOTIFY);
#if !defined(CONFIG_NIMBLE_ENABLED)
  carEstado->addDescriptor(new BLE2902());
  carEvento->addDescriptor(new BLE2902());
#endif
  carEstado->setValue("{}");
  servico->start();

  BLEAdvertising* anuncio = BLEDevice::getAdvertising();
  anuncio->addServiceUUID(BLE_UUID_SERVICO);
  anuncio->setScanResponse(true);
  BLEDevice::startAdvertising();
}

void bleManter() {
  if (blePrecisaAnunciar && millis() - bleDesconexao > 500) {
    blePrecisaAnunciar = false;
    BLEDevice::startAdvertising();
  }
}

// =====================================================================
//  LEITOR RFID RC522 (tarefa no núcleo 0)
//  A cada RFID_PERIODO_MS acorda as tags do campo (WUPA), lê o UID e as
//  manda dormir de novo (HLTA): a mesma tag é revista a cada ciclo.
//    tag nova -> CHEGOU   ·   sem leitura por 1,5 s -> SAIU
//  A saúde do leitor é conferida a cada 2 s; se o chip reiniciar por
//  ruído, ele é reconfigurado sozinho. O laço principal só recebe eventos
//  por uma fila e nunca espera o RFID.
// =====================================================================
const uint8_t UID_MAX = 21;                      // até 10 bytes = 20 caracteres hex
enum TipoRfid : uint8_t { TR_CHEGOU, TR_SAIU, TR_LEITOR_OK, TR_LEITOR_ERRO };
struct LeituraRfid { TipoRfid tipo; char uid[UID_MAX]; };

MFRC522 leitorRfid(PINO_RFID_SS, PINO_RFID_RST);
QueueHandle_t filaRfid = nullptr;
volatile uint8_t  rfidVersao = 0;
volatile uint32_t rfidTotalLeituras = 0;
volatile uint32_t rfidReinicios = 0;
bool rfidOk = false;                              // usados só no laço principal
char uidAtual[UID_MAX] = {0};

void rfidEnviar(TipoRfid tipo, const char* uid) {
  LeituraRfid l;
  l.tipo = tipo;
  l.uid[0] = 0;
  if (uid) { strncpy(l.uid, uid, UID_MAX - 1); l.uid[UID_MAX - 1] = 0; }
  xQueueSend(filaRfid, &l, 0);                    // fila cheia: descarta (nunca bloqueia)
}

bool rfidVersaoValida(uint8_t v) { return v != 0x00 && v != 0xFF; }   // 0x91/0x92 originais; 0x88, 0x12, 0xB2 clones

bool rfidInicializar() {
  leitorRfid.PCD_Init();
  delay(10);
  uint8_t v = leitorRfid.PCD_ReadRegister(MFRC522::VersionReg);
  rfidVersao = v;
  if (!rfidVersaoValida(v)) return false;
  leitorRfid.PCD_SetAntennaGain(MFRC522::RxGain_max);
  leitorRfid.PCD_AntennaOn();
  return true;
}

bool rfidSaudavel() {
  uint8_t v = leitorRfid.PCD_ReadRegister(MFRC522::VersionReg);
  if (!rfidVersaoValida(v)) return false;
  uint8_t tx = leitorRfid.PCD_ReadRegister(MFRC522::TxControlReg);   // antena desligada = chip reiniciou
  return (tx & 0x03) == 0x03;
}

void rfidUidTexto(const MFRC522::Uid& u, char* destino) {
  static const char HEX_DIG[] = "0123456789ABCDEF";
  uint8_t n = u.size > 10 ? 10 : u.size;
  for (uint8_t i = 0; i < n; i++) {
    destino[2 * i] = HEX_DIG[u.uidByte[i] >> 4];
    destino[2 * i + 1] = HEX_DIG[u.uidByte[i] & 0x0F];
  }
  destino[2 * n] = 0;
}

void rfidTarefa(void*) {
  SPI.begin(PINO_RFID_SCK, PINO_RFID_MISO, PINO_RFID_MOSI, PINO_RFID_SS);
  bool ok = false, presente = false, erroAvisado = false, primeira = true;
  uint32_t ultimaTentativa = 0, ultimaVerificacao = 0, ultimaLeitura = 0;
  char uidPresente[UID_MAX] = {0};

  for (;;) {
    uint32_t agora = millis();
    if (!ok) {
      if (primeira || agora - ultimaTentativa >= RFID_VERIFICA_MS) {
        primeira = false;
        ultimaTentativa = agora;
        if (rfidInicializar()) {
          ok = true;
          erroAvisado = false;
          ultimaVerificacao = agora;
          rfidEnviar(TR_LEITOR_OK, nullptr);
        } else if (!erroAvisado) {
          erroAvisado = true;
          rfidEnviar(TR_LEITOR_ERRO, nullptr);
        }
      }
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }

    if (agora - ultimaVerificacao >= RFID_VERIFICA_MS) {          // saúde do leitor
      ultimaVerificacao = agora;
      if (!rfidSaudavel()) {
        ok = false;
        rfidReinicios = rfidReinicios + 1;
        if (presente) { presente = false; rfidEnviar(TR_SAIU, uidPresente); uidPresente[0] = 0; }
        rfidEnviar(TR_LEITOR_ERRO, nullptr);
        erroAvisado = true;
        ultimaTentativa = agora - RFID_VERIFICA_MS;                // tenta reiniciar já
        continue;
      }
    }

    byte atqa[2];
    byte tam = sizeof(atqa);
    MFRC522::StatusCode st = leitorRfid.PICC_WakeupA(atqa, &tam);
    if ((st == MFRC522::STATUS_OK || st == MFRC522::STATUS_COLLISION) && leitorRfid.PICC_ReadCardSerial()) {
      char uid[UID_MAX];
      rfidUidTexto(leitorRfid.uid, uid);
      leitorRfid.PICC_HaltA();
      ultimaLeitura = agora;
      rfidTotalLeituras = rfidTotalLeituras + 1;
      if (!presente || strcmp(uid, uidPresente) != 0) {
        if (presente) rfidEnviar(TR_SAIU, uidPresente);            // trocou de animal
        strncpy(uidPresente, uid, UID_MAX);
        presente = true;
        rfidEnviar(TR_CHEGOU, uidPresente);
      }
    }
    if (presente && agora - ultimaLeitura >= RFID_AUSENCIA_MS) {
      presente = false;
      rfidEnviar(TR_SAIU, uidPresente);
      uidPresente[0] = 0;
    }
    vTaskDelay(pdMS_TO_TICKS(RFID_PERIODO_MS));
  }
}

void rfidIniciar() {
  filaRfid = xQueueCreate(8, sizeof(LeituraRfid));
  xTaskCreatePinnedToCore(rfidTarefa, "rfid", 4096, nullptr, 1, nullptr, 0);   // núcleo 0, prioridade baixa
}

// =====================================================================
//  EVENTOS E ESTADO (JSON)
// =====================================================================
void enviarEvento(const char* json) {
  Serial.print("EVT ");
  Serial.println(json);
  if (carEvento && bleConectado) {
    carEvento->setValue((uint8_t*)json, strlen(json));
    carEvento->notify();
  }
}

void eventoInicio() {
  char b[64];
  snprintf(b, sizeof(b), "{\"ev\":\"INICIO\",\"ver\":\"%s\"}", FIRMWARE_VERSAO);
  enviarEvento(b);
}

void eventoPorta(uint8_t i) {
  char b[64];
  snprintf(b, sizeof(b), "{\"ev\":\"PORTA\",\"p\":%u,\"e\":\"%s\"}", (unsigned)(i + 1), NOME_ESTADO[porta[i].estado]);
  enviarEvento(b);
}

void eventoObstaculo(uint8_t i) {
  char b[48];
  snprintf(b, sizeof(b), "{\"ev\":\"OBSTACULO\",\"p\":%u}", (unsigned)(i + 1));
  enviarEvento(b);
}

void eventoEmergencia(bool on, Origem o) {
  char b[64];
  snprintf(b, sizeof(b), "{\"ev\":\"EMERGENCIA\",\"on\":%d,\"orig\":\"%s\"}", on ? 1 : 0, NOME_ORIGEM[o]);
  enviarEvento(b);
}

void eventoRearme(Origem o) {
  char b[48];
  snprintf(b, sizeof(b), "{\"ev\":\"REARME\",\"orig\":\"%s\"}", NOME_ORIGEM[o]);
  enviarEvento(b);
}

void eventoResp(const char* cmd, int p, unsigned id, const char* res, Origem o) {
  char b[128];
  snprintf(b, sizeof(b), "{\"ev\":\"RESP\",\"cmd\":\"%s\",\"p\":%d,\"id\":%u,\"res\":\"%s\",\"orig\":\"%s\"}",
           cmd, p < 0 ? 0 : p + 1, id, res, NOME_ORIGEM[o]);
  enviarEvento(b);
}

void eventoFalha(uint8_t i) {
  char b[64];
  snprintf(b, sizeof(b), "{\"ev\":\"FALHA\",\"p\":%u,\"f\":\"%s\"}", (unsigned)(i + 1), porta[i].falha);
  enviarEvento(b);
}

void eventoRfid(const char* nome, const char* uid) {   // RFID, RFID_SAIU (com uid) · RFID_OK, RFID_ERRO
  char b[72];
  if (uid) snprintf(b, sizeof(b), "{\"ev\":\"%s\",\"uid\":\"%s\"}", nome, uid);
  else snprintf(b, sizeof(b), "{\"ev\":\"%s\"}", nome);
  enviarEvento(b);
}

// Recebe os eventos da tarefa do RFID (chamado no laço principal)
void processarRfid() {
  LeituraRfid l;
  while (filaRfid && xQueueReceive(filaRfid, &l, 0) == pdTRUE) {
    switch (l.tipo) {
      case TR_CHEGOU: {
        uint8_t n = 0;                                    // só hexadecimal (vai direto no JSON)
        for (const char* p = l.uid; *p && n < UID_MAX - 1; p++) {
          char ch = *p;
          if ((ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'F')) uidAtual[n++] = ch;
          else if (ch >= 'a' && ch <= 'f') uidAtual[n++] = (char)(ch - 'a' + 'A');
        }
        uidAtual[n] = 0;
        eventoRfid("RFID", uidAtual);
        break;
      }
      case TR_SAIU:
        eventoRfid("RFID_SAIU", uidAtual[0] ? uidAtual : l.uid);
        uidAtual[0] = 0;
        break;
      case TR_LEITOR_OK:
        rfidOk = true;
        eventoRfid("RFID_OK", nullptr);
        break;
      case TR_LEITOR_ERRO:
        rfidOk = false;
        eventoRfid("RFID_ERRO", nullptr);
        break;
    }
    estadoMudou = true;
  }
}

bool fimAbertaAtivo(uint8_t i)  { return USAR_FINS_DE_CURSO && dbFimA[i].estavel; }
bool fimFechadaAtivo(uint8_t i) { return USAR_FINS_DE_CURSO && dbFimF[i].estavel; }

size_t montarEstado(char* b, size_t tam) {
  int n = snprintf(b, tam,
      "{\"p1\":\"%s\",\"p2\":\"%s\",\"f1\":\"%s\",\"f2\":\"%s\",\"ir\":\"%d%d\",\"fa\":\"%d%d\",\"ff\":\"%d%d\","
      "\"em\":%d,\"bot\":\"%d%d%d\",\"rfid\":\"%s\",\"rok\":%d,\"up\":%lu}",
      NOME_ESTADO[porta[0].estado], NOME_ESTADO[porta[1].estado], porta[0].falha, porta[1].falha,
      obstaculo[0] ? 1 : 0, obstaculo[1] ? 1 : 0,
      fimAbertaAtivo(0) ? 1 : 0, fimAbertaAtivo(1) ? 1 : 0,
      fimFechadaAtivo(0) ? 1 : 0, fimFechadaAtivo(1) ? 1 : 0,
      emergencia ? 1 : 0,
      dbBotao[0].estavel ? 1 : 0, dbBotao[1].estavel ? 1 : 0, (USAR_BOTAO_PARADA && dbParada.estavel) ? 1 : 0,
      uidAtual, rfidOk ? 1 : 0,
      (unsigned long)(millis() / 1000));
  return n < 0 ? 0 : ((size_t)n >= tam ? tam - 1 : (size_t)n);
}

void publicarEstado(bool tambemSerial) {
  char b[240];
  size_t n = montarEstado(b, sizeof(b));
  if (carEstado) {
    carEstado->setValue((uint8_t*)b, n);       // sempre atualizado para leitura
    if (bleConectado) carEstado->notify();
  }
  if (tambemSerial) { Serial.print("EST "); Serial.println(b); }
}

// =====================================================================
//  MOTORES
// =====================================================================
void pwmIniciar(uint8_t i) {
#if LEDC_V3
  ledcAttach(PINO_EN[i], 1000, 8);
#else
  ledcSetup(i, 1000, 8);
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
  motor[i].pwm = 0;
  motor[i].freando = true;
  motor[i].inicioFreio = agora;
}

void atualizarMotor(uint8_t i, uint32_t agora) {
  if (motor[i].freando && agora - motor[i].inicioFreio >= FREIO_MS) {
    pwmEscrever(i, 0);
    motor[i].freando = false;
  }
}

// =====================================================================
//  PORTAS
// =====================================================================
void mudarEstado(uint8_t i, Estado e) {
  if (porta[i].estado == e) return;
  porta[i].estado = e;
  estadoMudou = true;
  eventoPorta(i);
}

// Estado da porta pelo que as chaves mostram (sem chaves: pela posição estimada)
Estado estadoPelasChaves(uint8_t i) {
  if (USAR_FINS_DE_CURSO) {
    bool a = dbFimA[i].estavel, f = dbFimF[i].estavel;
    if (a && f) return FALHA;
    if (f) { porta[i].pos = 0.0f; return FECHADA; }
    if (a) { porta[i].pos = 1.0f; return ABERTA; }
    if (porta[i].pos <= 0.0f) porta[i].pos = 0.05f;      // sem chave nenhuma: está no meio
    if (porta[i].pos >= 1.0f) porta[i].pos = 0.95f;
    return PARADA;
  }
  if (porta[i].pos <= 0.0f) return FECHADA;
  if (porta[i].pos >= 1.0f) return ABERTA;
  return PARADA;
}

void entrarFalha(uint8_t i, const char* codigo, uint32_t agora) {
  frearMotor(i, agora);
  porta[i].corrigindo = false;
  bool novo = porta[i].estado != FALHA || strcmp(porta[i].falha, codigo) != 0;
  porta[i].falha = codigo;
  mudarEstado(i, FALHA);
  if (novo) eventoFalha(i);
  estadoMudou = true;
}

void limparFalha(uint8_t i, uint32_t agora) {
  if (porta[i].estado != FALHA) return;
  Estado e = estadoPelasChaves(i);
  if (e == FALHA) { entrarFalha(i, "FIM_DUPLO", agora); return; }   // as duas chaves continuam acionadas
  porta[i].falha = "";
  mudarEstado(i, e);
}

bool emMovimento(uint8_t i) {
  Estado e = porta[i].estado;
  return e == ABRINDO || e == FECHANDO || e == RECUANDO || e == AJUSTE;
}

void parar(uint8_t i, uint32_t agora) {
  frearMotor(i, agora);
  porta[i].corrigindo = false;
  Estado e = porta[i].estado;
  if (e == FECHADA || e == ABERTA || e == FALHA) return;
  if (e == AJUSTE) { mudarEstado(i, porta[i].antesJog); return; }
  Estado n = estadoPelasChaves(i);
  if (n == FALHA) entrarFalha(i, "FIM_DUPLO", agora);
  else mudarEstado(i, n);
}

const char* abrir(uint8_t i, uint32_t agora) {
  if (emergencia) return "EMERGENCIA";
  if (porta[i].estado == FALHA) return "FALHA";
  if (porta[i].estado == AJUSTE) return "NAO_PERMITIDO";
  if (porta[i].estado == ABERTA) return "JA_ABERTA";
  if (porta[i].estado == ABRINDO || porta[i].estado == RECUANDO) return "OK";
  uint8_t outra = 1 - i;
  if (INTERTRAVAMENTO && porta[outra].estado != FECHADA) return "INTERTRAVAMENTO";
  porta[i].inicioMov = agora;
  mudarEstado(i, ABRINDO);
  return "OK";
}

const char* fechar(uint8_t i, uint32_t agora) {
  if (emergencia) return "EMERGENCIA";
  if (porta[i].estado == FALHA) return "FALHA";
  if (porta[i].estado == AJUSTE) return "NAO_PERMITIDO";
  if (porta[i].estado == FECHADA) return "JA_FECHADA";
  if (porta[i].estado == FECHANDO) return "OK";
  if (obstaculo[i]) return "OBSTACULO";
  porta[i].inicioMov = agora;
  mudarEstado(i, FECHANDO);
  return "OK";
}

const char* alternar(uint8_t i, uint32_t agora) {
  if (porta[i].estado == FALHA) return "FALHA";
  if (emMovimento(i) && porta[i].estado != AJUSTE) { parar(i, agora); return "OK"; }
  if (porta[i].estado == ABERTA) return fechar(i, agora);
  return abrir(i, agora);
}

void chegouAberta(uint8_t i, uint32_t agora) {
  porta[i].pos = 1.0f;
  porta[i].corrigindo = false;
  frearMotor(i, agora);
  mudarEstado(i, ABERTA);
}

void chegouFechada(uint8_t i, uint32_t agora) {
  porta[i].pos = 0.0f;
  frearMotor(i, agora);
  mudarEstado(i, FECHADA);
}

void atualizarPorta(uint8_t i, uint32_t agora) {
  Porta& p = porta[i];
  Motor& m = motor[i];
  // As duas chaves da mesma porta acionadas = fio solto ou chave travada
  if (USAR_FINS_DE_CURSO && p.estado != FALHA && fimAbertaAtivo(i) && fimFechadaAtivo(i)) {
    entrarFalha(i, "FIM_DUPLO", agora);
    return;
  }
  switch (p.estado) {
    case ABRINDO:
      if (fimAbertaAtivo(i)) { chegouAberta(i, agora); break; }
      if (m.freando) break;
      if (m.dir == -1) { frearMotor(i, agora); break; }          // inverte: freia antes
      if (m.dir == 0 || m.pwm != PWM_ABRIR) {                     // parte (ou sai do "segurar")
        ligarMotor(i, +1, PWM_ABRIR);
        p.ultimaConta = agora;
        p.inicioGiro = agora;
        break;
      }
      p.pos += (float)(agora - p.ultimaConta) / (float)tempoAbrirMs;
      p.ultimaConta = agora;
      // Com chaves: o tempo vira só um limite de segurança.
      if (USAR_FINS_DE_CURSO) {
        if (p.pos > 0.99f) p.pos = 0.99f;
        if (fimFechadaAtivo(i) && agora - p.inicioGiro > FIM_PRESO_MS) { entrarFalha(i, "FIM_PRESO", agora); break; }
        if (agora - p.inicioMov > tempoAbrirMs * 2 + LIMITE_EXTRA_MS) entrarFalha(i, "TIMEOUT_ABRIR", agora);
      } else if (p.pos >= 1.0f) {
        chegouAberta(i, agora);
      }
      break;

    case FECHANDO:
      if (obstaculo[i]) {                                        // PARADA AUTOMÁTICA
        frearMotor(i, agora);
        p.inicioPausa = agora;
        mudarEstado(i, RECUANDO);
        eventoObstaculo(i);
        break;
      }
      if (fimFechadaAtivo(i)) { chegouFechada(i, agora); break; }
      if (m.freando) break;
      if (m.dir == +1) { frearMotor(i, agora); break; }
      if (m.dir == 0) { ligarMotor(i, -1, PWM_FECHAR); p.ultimaConta = agora; p.inicioGiro = agora; break; }
      p.pos -= (float)(agora - p.ultimaConta) / (float)tempoFecharMs;
      p.ultimaConta = agora;
      if (USAR_FINS_DE_CURSO) {
        if (p.pos < 0.01f) p.pos = 0.01f;
        if (fimAbertaAtivo(i) && agora - p.inicioGiro > FIM_PRESO_MS) { entrarFalha(i, "FIM_PRESO", agora); break; }
        if (agora - p.inicioMov > tempoFecharMs * 2 + LIMITE_EXTRA_MS) entrarFalha(i, "TIMEOUT_FECHAR", agora);
      } else if (p.pos <= 0.0f) {
        chegouFechada(i, agora);
      }
      break;

    case RECUANDO:
      if (!m.freando && agora - p.inicioPausa >= PAUSA_OBSTACULO_MS) {
        p.inicioMov = agora;
        mudarEstado(i, ABRINDO);
      }
      break;

    case AJUSTE:
      if (m.freando) break;
      if ((m.dir != p.jogDir || m.pwm != PWM_JOG) && (int32_t)(p.jogFim - agora) > 0) {
        ligarMotor(i, p.jogDir, PWM_JOG);
        break;
      }
      if ((int32_t)(agora - p.jogFim) >= 0 ||
          (p.jogDir > 0 && fimAbertaAtivo(i)) || (p.jogDir < 0 && fimFechadaAtivo(i))) {
        frearMotor(i, agora);
        mudarEstado(i, p.antesJog);
      }
      break;

    case ABERTA:
      // Porta escorregou e soltou a chave de cima: sobe de novo até a chave.
      if (USAR_FINS_DE_CURSO && !emergencia) {
        if (!p.corrigindo && !fimAbertaAtivo(i) && !m.freando && agora - p.inicioPausa >= CORRECAO_ESPERA_MS) {
          p.corrigindo = true;
          p.inicioMov = agora;
        }
        if (p.corrigindo) {
          if (fimAbertaAtivo(i)) {
            p.corrigindo = false;
            p.inicioPausa = agora;
          } else if (agora - p.inicioMov > tempoAbrirMs * 2 + LIMITE_EXTRA_MS) {
            entrarFalha(i, "TIMEOUT_ABRIR", agora);
            break;
          } else {
            if (!m.freando && (m.dir != +1 || m.pwm != PWM_ABRIR)) ligarMotor(i, +1, PWM_ABRIR);
            break;
          }
        }
      }
      __attribute__((fallthrough));               // segura a porta
    case PARADA:
    case FALHA:
      // SEGURAR: força baixa para cima, para a porta não descer com o peso.
      if (p.estado == ABERTA && emergencia) p.corrigindo = false;
      if (m.freando || p.pos <= 0.0f || pwmSegurar == 0) break;
      if (p.estado == FALHA && USAR_FINS_DE_CURSO && fimFechadaAtivo(i)) { if (m.dir != 0) frearMotor(i, agora); break; }
      if (m.dir != +1 || m.pwm != pwmSegurar) ligarMotor(i, +1, pwmSegurar);
      break;

    default:
      break;
  }
}

// =====================================================================
//  EMERGÊNCIA
// =====================================================================
void ativarEmergencia(Origem o, uint32_t agora) {
  if (emergencia) return;
  emergencia = true;
  contandoRearme = false;
  paradaSoltaDesdeEmergencia = !(USAR_BOTAO_PARADA && dbParada.estavel);
  for (uint8_t i = 0; i < 2; i++) parar(i, agora);
  estadoMudou = true;
  eventoEmergencia(true, o);
}

void rearmar(Origem o) {
  emergencia = false;
  contandoRearme = false;
  estadoMudou = true;
  eventoEmergencia(false, o);
  eventoRearme(o);
}

// =====================================================================
//  ENTRADAS
// =====================================================================
void lerSensoresIr() {
  for (uint8_t i = 0; i < 2; i++) {
    uint32_t mv = analogReadMilliVolts(PINO_IR[i]);
    irMv[i] = mv > 65535 ? 65535 : (uint16_t)mv;
    bool novo = obstaculo[i];
    if (irMv[i] < IR_OBSTACULO_MV) novo = true;
    else if (irMv[i] > IR_LIVRE_MV) novo = false;
    if (novo != obstaculo[i]) {
      if (++irContagem[i] >= 3) {               // confirma após 3 leituras
        obstaculo[i] = novo;
        irContagem[i] = 0;
        estadoMudou = true;
      }
    } else {
      irContagem[i] = 0;
    }
  }
}

void lerEntradas(uint32_t agora) {
  // Botões 1 e 2 (contato NO): apertado = ALTO
  for (uint8_t i = 0; i < 2; i++) {
    bool apertado = digitalRead(PINO_BOTAO[i]) == HIGH;
    if (dbBotao[i].atualizar(apertado, agora)) {
      estadoMudou = true;
      if (!dbBotao[i].estavel) { ignorarBotao[i] = false; continue; }
      if (ignorarBotao[i]) continue;
      eventoResp("ALTERNAR", i, 0, alternar(i, agora), ORIG_BOTAO);
    }
  }
  // Fins de curso (opcional): NF ao GND + pull-up -> acionado = ALTO
  if (USAR_FINS_DE_CURSO) {
    for (uint8_t i = 0; i < 2; i++) {
      if (dbFimA[i].atualizar(digitalRead(PINO_FIM_ABERTA[i]) == HIGH, agora)) estadoMudou = true;
      if (dbFimF[i].atualizar(digitalRead(PINO_FIM_FECHADA[i]) == HIGH, agora)) estadoMudou = true;
    }
  }
  // Parada (contato NC): solto = ALTO, apertado ou fio rompido = BAIXO
  if (!USAR_BOTAO_PARADA) return;
  if (dbParada.atualizar(digitalRead(PINO_PARADA) == LOW, agora)) {
    estadoMudou = true;
    if (dbParada.estavel) {
      if (!emergencia) ativarEmergencia(ORIG_BOTAO, agora);
      else if (paradaSoltaDesdeEmergencia) { contandoRearme = true; inicioRearme = agora; }
    } else {
      if (emergencia) paradaSoltaDesdeEmergencia = true;
      contandoRearme = false;
    }
  }
  if (emergencia && contandoRearme && dbParada.estavel && agora - inicioRearme >= REARME_MS) rearmar(ORIG_BOTAO);
}

// =====================================================================
//  COMANDOS (app e serial)
// =====================================================================
int lerPorta(const char* t) {
  if (!t) return -1;
  if (!strcmp(t, "1") || !strcmp(t, "ENTRADA") || !strcmp(t, "E")) return 0;
  if (!strcmp(t, "2") || !strcmp(t, "SAIDA") || !strcmp(t, "S")) return 1;
  return -1;
}

void imprimirAjuda() {
  Serial.println();
  Serial.println("Comandos (app e serial):");
  Serial.println("  ABRIR 1|2 · FECHAR 1|2 · ALTERNAR 1|2 · PARAR [1|2]");
  Serial.println("  EMERGENCIA · RESET · STATUS · PING   (prefixo opcional: #id, ex.: #5 ABRIR 1)");
  Serial.println("Somente pela serial:");
  Serial.println("  JOG 1|2 SOBE|DESCE [ms]   ajuste manual (padrao 300 ms, max 2000)");
  Serial.println("  ZERAR 1|2                 marca a porta como FECHADA");
  Serial.println("  TEMPO <abrir> <fechar>    tempos de curso em ms (ex.: TEMPO 3000 2200)");
  Serial.println("  SEGURAR <0-255>           forca para segurar a porta aberta");
  Serial.println("  INVERTER 1|2              inverte o sentido do motor");
  Serial.println("  PADRAO                    volta TEMPO, SEGURAR e INVERTER ao valor do codigo");
  Serial.println("(TEMPO, SEGURAR e INVERTER ficam salvos na memoria da placa)");
  Serial.println("FALHA de uma porta: corrija a causa e envie RESET.");
  Serial.println("  MONITOR                   tensao dos sensores IR a cada 0,5 s");
  Serial.println("  DIAG                      estado legivel (portas, botoes, Bluetooth e RFID)");
  Serial.printf("Atual: abrir %lu ms, fechar %lu ms, segurar %u, parada %s, fins de curso %s, RFID %s\n\n",
                (unsigned long)tempoAbrirMs, (unsigned long)tempoFecharMs, (unsigned)pwmSegurar,
                USAR_BOTAO_PARADA ? "LIGADA" : "DESLIGADA", USAR_FINS_DE_CURSO ? "LIGADOS" : "desligados",
                USAR_RFID ? "LIGADO" : "DESLIGADO");
}

void imprimirDiag() {
  Serial.println();
  for (uint8_t i = 0; i < 2; i++) {
    bool segurando = (porta[i].estado == ABERTA || porta[i].estado == PARADA) && motor[i].dir > 0;
    const char* m = motor[i].freando ? "FREANDO" : (segurando ? "SEGURA" : (motor[i].dir > 0 ? "SOBE" : (motor[i].dir < 0 ? "DESCE" : "PARADO")));
    Serial.printf("Porta %u: %-8s posicao %3d%%  motor %-7s  IR %4u mV %s", (unsigned)(i + 1),
                  NOME_ESTADO[porta[i].estado], (int)(porta[i].pos * 100.0f + 0.5f), m,
                  (unsigned)irMv[i], obstaculo[i] ? "OBSTACULO" : "livre");
    if (USAR_FINS_DE_CURSO) Serial.printf("  fim A=%d F=%d", dbFimA[i].estavel ? 1 : 0, dbFimF[i].estavel ? 1 : 0);
    if (porta[i].estado == FALHA) Serial.printf("  FALHA: %s", porta[i].falha);
    Serial.println();
  }
  Serial.printf("Botao 1: %s  Botao 2: %s  Parada: %s (GPIO5=%s)  Emergencia: %s  Bluetooth: %s\n\n",
                dbBotao[0].estavel ? "APERTADO" : "solto", dbBotao[1].estavel ? "APERTADO" : "solto",
                !USAR_BOTAO_PARADA ? "DESLIGADA" : (dbParada.estavel ? "APERTADA" : "solta"),
                digitalRead(PINO_PARADA) ? "ALTO" : "BAIXO", emergencia ? "SIM" : "nao",
                bleConectado ? "CONECTADO" : "anunciando");
  if (!USAR_RFID) Serial.println("RFID RC522: DESLIGADO (USAR_RFID = false)\n");
  else Serial.printf("RFID RC522: %s  (versao 0x%02X)  leituras: %lu  reinicios: %lu  tag: %s\n\n",
                     rfidOk ? "OK" : "SEM RESPOSTA - confira as ligacoes e o 3,3 V", (unsigned)rfidVersao,
                     (unsigned long)rfidTotalLeituras, (unsigned long)rfidReinicios, uidAtual[0] ? uidAtual : "-");
}

void executar(char* linha, Origem orig, uint32_t agora) {
  for (char* c = linha; *c; c++) *c = toupper((unsigned char)*c);
  const char* sep = " \t:=,;\r\n";
  char* tok = strtok(linha, sep);
  if (!tok) return;
  unsigned id = 0;
  if (tok[0] == '#') {
    long v = atol(tok + 1);
    id = (v >= 1 && v <= 65535) ? (unsigned)v : 0;
    tok = strtok(nullptr, sep);
    if (!tok) { eventoResp("?", -1, id, "INVALIDO", orig); return; }
  }
  char* cmd = tok;
  char* a1 = strtok(nullptr, sep);
  char* a2 = strtok(nullptr, sep);
  char* a3 = strtok(nullptr, sep);
  int p = lerPorta(a1);
  bool serial = orig == ORIG_SERIAL;

  if (!strcmp(cmd, "ABRIR") || !strcmp(cmd, "FECHAR") || !strcmp(cmd, "ALTERNAR")) {
    if (p < 0) { eventoResp(cmd, -1, id, "PORTA_INVALIDA", orig); return; }
    const char* r = !strcmp(cmd, "ABRIR") ? abrir(p, agora) : (!strcmp(cmd, "FECHAR") ? fechar(p, agora) : alternar(p, agora));
    eventoResp(cmd, p, id, r, orig);
  }
  else if (!strcmp(cmd, "PARAR")) {
    if (a1 && p < 0) { eventoResp(cmd, -1, id, "PORTA_INVALIDA", orig); return; }
    if (p < 0) { parar(0, agora); parar(1, agora); } else parar(p, agora);
    eventoResp(cmd, p, id, "OK", orig);
  }
  else if (!strcmp(cmd, "EMERGENCIA")) {
    ativarEmergencia(orig, agora);
    eventoResp(cmd, -1, id, "OK", orig);
  }
  else if (!strcmp(cmd, "RESET") || !strcmp(cmd, "REARMAR")) {
    if (USAR_BOTAO_PARADA && dbParada.estavel) { eventoResp("RESET", -1, id, "EMERGENCIA", orig); return; }  // solte o botão
    if (emergencia) rearmar(orig);
    for (uint8_t i = 0; i < 2; i++) limparFalha(i, agora);
    eventoResp("RESET", -1, id, "OK", orig);
  }
  else if (!strcmp(cmd, "STATUS") || !strcmp(cmd, "ESTADO")) {
    eventoResp("STATUS", -1, id, "OK", orig);
    publicarEstado(true);
  }
  else if (!strcmp(cmd, "PING")) eventoResp(cmd, -1, id, "OK", orig);
  else if (!strcmp(cmd, "JOG")) {
    if (!serial) { eventoResp(cmd, p, id, "NAO_PERMITIDO", orig); return; }
    if (p < 0) { eventoResp(cmd, -1, id, "PORTA_INVALIDA", orig); return; }
    if (!a2 || (strcmp(a2, "SOBE") && strcmp(a2, "DESCE"))) { eventoResp(cmd, p, id, "INVALIDO", orig); return; }
    if (emergencia) { eventoResp(cmd, p, id, "EMERGENCIA", orig); return; }
    if (emMovimento(p)) { eventoResp(cmd, p, id, "NAO_PERMITIDO", orig); return; }
    long ms = a3 ? atol(a3) : 300;
    if (ms < 20) ms = 20;
    if (ms > 2000) ms = 2000;
    porta[p].jogDir = strcmp(a2, "SOBE") == 0 ? +1 : -1;
    porta[p].jogFim = agora + (uint32_t)ms;
    porta[p].antesJog = porta[p].estado;
    mudarEstado(p, AJUSTE);
    eventoResp(cmd, p, id, "OK", orig);
  }
  else if (!serial && (!strcmp(cmd, "ZERAR") || !strcmp(cmd, "TEMPO") || !strcmp(cmd, "SEGURAR") ||
                       !strcmp(cmd, "INVERTER") || !strcmp(cmd, "PADRAO") || !strcmp(cmd, "MONITOR") || !strcmp(cmd, "DIAG") || !strcmp(cmd, "AJUDA"))) {
    eventoResp(cmd, -1, id, "NAO_PERMITIDO", orig);
  }
  else if (!strcmp(cmd, "ZERAR")) {
    if (p < 0) { Serial.println("  use: ZERAR 1|2"); return; }
    if (emMovimento(p)) { Serial.println("  recusado: porta em movimento"); return; }
    frearMotor(p, agora);
    porta[p].pos = 0.0f;
    porta[p].estado = PARADA;
    mudarEstado(p, FECHADA);
  }
  else if (!strcmp(cmd, "TEMPO")) {
    long ab = a1 ? atol(a1) : 0;
    long fe = a2 ? atol(a2) : ab;
    if (ab < 100 || ab > 20000 || fe < 100 || fe > 20000) { Serial.println("  use: TEMPO <abrir ms> <fechar ms>"); return; }
    if (emMovimento(0) || emMovimento(1)) { Serial.println("  recusado: pare as portas antes"); return; }
    tempoAbrirMs = (uint32_t)ab;
    tempoFecharMs = (uint32_t)fe;
    salvarAjustes();
    Serial.printf("  tempos: abrir %lu ms, fechar %lu ms\n", (unsigned long)tempoAbrirMs, (unsigned long)tempoFecharMs);
  }
  else if (!strcmp(cmd, "SEGURAR")) {
    if (!a1) { Serial.printf("  segurar = %u\n", (unsigned)pwmSegurar); return; }
    long v = atol(a1);
    if (v < 0 || v > 255) { Serial.println("  use: SEGURAR <0-255>"); return; }
    pwmSegurar = (uint8_t)v;
    salvarAjustes();
    if (pwmSegurar == 0)
      for (uint8_t i = 0; i < 2; i++)
        if ((porta[i].estado == ABERTA || porta[i].estado == PARADA) && motor[i].dir != 0) frearMotor(i, agora);
    Serial.printf("  segurar = %u\n", (unsigned)pwmSegurar);
  }
  else if (!strcmp(cmd, "INVERTER")) {
    if (p < 0) { Serial.println("  use: INVERTER 1|2"); return; }
    if (emMovimento(p)) { Serial.println("  recusado: porta em movimento"); return; }
    frearMotor(p, agora);
    inverterMotor[p] = !inverterMotor[p];
    salvarAjustes();
    Serial.printf("  motor %d: inverter = %d (salvo na memoria)\n", p + 1, inverterMotor[p] ? 1 : 0);
  }
  else if (!strcmp(cmd, "PADRAO")) {
    if (emMovimento(0) || emMovimento(1)) { Serial.println("  recusado: pare as portas antes"); return; }
    memoria.clear();
    tempoAbrirMs = TEMPO_ABRIR_PADRAO; tempoFecharMs = TEMPO_FECHAR_PADRAO; pwmSegurar = SEGURAR_PADRAO;
    inverterMotor[0] = INVERTER_PADRAO[0]; inverterMotor[1] = INVERTER_PADRAO[1];
    Serial.println("  ajustes de fabrica restaurados");
    imprimirAjuda();
  }
  else if (!strcmp(cmd, "MONITOR")) {
    monitorIr = !monitorIr;
    Serial.printf("  monitor dos IR %s\n", monitorIr ? "LIGADO" : "desligado");
  }
  else if (!strcmp(cmd, "DIAG")) imprimirDiag();
  else if (!strcmp(cmd, "AJUDA") || !strcmp(cmd, "HELP") || !strcmp(cmd, "?")) imprimirAjuda();
  else eventoResp(cmd, -1, id, "INVALIDO", orig);
}

void lerSerial(uint32_t agora) {
  static char buf[65];
  static uint8_t n = 0;
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\r') continue;
    if (c == '\n') { buf[n] = 0; if (n) executar(buf, ORIG_SERIAL, agora); n = 0; }
    else if (n < sizeof(buf) - 1) buf[n++] = c;
  }
}

void lerBluetooth(uint32_t agora) {
  TextoComando t;
  while (filaComandos && xQueueReceive(filaComandos, &t, 0) == pdTRUE) executar(t.txt, ORIG_APP, agora);
}

// =====================================================================
//  LED: aceso = porta em movimento · pisca rápido = emergência · lento = ok
// =====================================================================
void atualizarLed(uint32_t agora) {
  bool aceso;
  if (emergencia) aceso = (agora / 100) % 2;
  else if (emMovimento(0) || emMovimento(1)) aceso = true;
  else aceso = bleConectado ? ((agora / 250) % 8 == 0) : ((agora / 1000) % 2);
  digitalWrite(PINO_LED, aceso ? HIGH : LOW);
}

// =====================================================================
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
  for (uint8_t i = 0; i < 2; i++) {
    pinMode(PINO_FIM_ABERTA[i], INPUT_PULLUP);
    pinMode(PINO_FIM_FECHADA[i], INPUT_PULLUP);
    pinMode(PINO_IR[i], INPUT);
    analogSetPinAttenuation(PINO_IR[i], ADC_11db);
  }
  analogReadResolution(12);
  pinMode(PINO_LED, OUTPUT);

  Serial.begin(115200);
  delay(300);
  Serial.println();
  Serial.println("==============================================");
  Serial.printf(" BoviCare - Brete automatizado  (firmware %s)\n", FIRMWARE_VERSAO);
  Serial.println(USAR_FINS_DE_CURSO ? " Estado inicial das portas lido nas chaves de fim de curso."
                                    : " Portas consideradas FECHADAS ao ligar.");
  Serial.println("==============================================");

  // 3) Estado inicial das entradas (sem disparar comandos)
  uint32_t agora = millis();
  for (uint8_t i = 0; i < 2; i++) {
    bool ap = digitalRead(PINO_BOTAO[i]) == HIGH;
    dbBotao[i].estavel = dbBotao[i].bruto = ap;
    ignorarBotao[i] = ap;
    if (ap) Serial.printf("! botao %u lido como APERTADO no boot: ignorado ate soltar\n", (unsigned)(i + 1));
    bool fa = digitalRead(PINO_FIM_ABERTA[i]) == HIGH, ff = digitalRead(PINO_FIM_FECHADA[i]) == HIGH;
    dbFimA[i].estavel = dbFimA[i].bruto = fa;
    dbFimF[i].estavel = dbFimF[i].bruto = ff;
  }
  carregarAjustes();
  for (uint8_t i = 0; i < 2; i++) {
    Estado e = estadoPelasChaves(i);
    if (e == FALHA) { porta[i].estado = FALHA; porta[i].falha = "FIM_DUPLO"; }
    else porta[i].estado = e;
    if (USAR_FINS_DE_CURSO)
      Serial.printf(" Porta %u: %s%s\n", (unsigned)(i + 1), NOME_ESTADO[porta[i].estado],
                    e == FALHA ? " (FIM_DUPLO: as duas chaves acionadas - confira a fiacao)" :
                    (e == PARADA ? " (nenhuma chave acionada: porta no meio do curso)" : ""));
  }
  for (uint8_t k = 0; k < 5; k++) { lerSensoresIr(); delay(5); }

  // 4) Bluetooth e RFID
  bleIniciar();
  eventoInicio();
  for (uint8_t i = 0; i < 2; i++) if (porta[i].estado == FALHA) eventoFalha(i);
  if (USAR_RFID) rfidIniciar();                 // RFID_OK (ou RFID_ERRO) chega logo depois

  bool parAp = USAR_BOTAO_PARADA && digitalRead(PINO_PARADA) == LOW;
  dbParada.estavel = dbParada.bruto = parAp;
  if (parAp) {
    Serial.println("! botao de PARADA lido como APERTADO: confira a ligacao NC (3,3 V -> NC -> GPIO5)");
    ativarEmergencia(ORIG_BOTAO, agora);
  }
  imprimirAjuda();
  publicarEstado(true);
  enableLoopWDT();                           // reinicia a placa se o laço travar
}

void loop() {
  uint32_t agora = millis();
  lerSensoresIr();
  lerEntradas(agora);
  lerSerial(agora);
  lerBluetooth(agora);
  processarRfid();
  for (uint8_t i = 0; i < 2; i++) {
    atualizarPorta(i, agora);
    atualizarMotor(i, agora);
  }
  bleManter();
  if (bleNovaConexao) {                       // app acabou de conectar: retrato completo
    bleNovaConexao = false;
    delay(200);
    eventoInicio();
    if (USAR_RFID) eventoRfid(rfidOk ? "RFID_OK" : "RFID_ERRO", nullptr);
    if (uidAtual[0]) eventoRfid("RFID", uidAtual);   // animal que já está no brete
    estadoMudou = true;
  }
  if (estadoMudou || agora - ultimoEstado >= ESTADO_PERIODO_MS) {
    estadoMudou = false;
    ultimoEstado = agora;
    publicarEstado(false);
  }
  if (monitorIr && agora - ultimoMonitor >= 500) {
    ultimoMonitor = agora;
    Serial.printf("IR1 %4u mV %-9s | IR2 %4u mV %s\n", (unsigned)irMv[0], obstaculo[0] ? "OBSTACULO" : "livre",
                  (unsigned)irMv[1], obstaculo[1] ? "OBSTACULO" : "livre");
  }
  atualizarLed(agora);
  delay(2);
}
