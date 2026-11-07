// =====================================================================
//  BoviCare - Brete automatizado
//  ble_brete.cpp  ->  servidor BLE (biblioteca BLE do próprio core ESP32)
//
//  Os callbacks do Bluetooth rodam em outra tarefa. Eles apenas colocam
//  o texto recebido numa fila; quem executa é o laço principal. Assim o
//  Bluetooth nunca mexe diretamente nos motores.
// =====================================================================
#include "ble_brete.h"
#include "parametros.h"
#include "protocolo.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#if !defined(CONFIG_NIMBLE_ENABLED)
  #include <BLE2902.h>
#endif

namespace ble {
namespace {

struct TextoComando { char txt[COMANDO_MAX_CHARS + 1]; };

BLEServer*         servidor = nullptr;
BLECharacteristic* carEstado = nullptr;
BLECharacteristic* carEvento = nullptr;
QueueHandle_t      filaComandos = nullptr;

volatile bool     estaConectado = false;
volatile bool     novaConexao = false;
volatile bool     precisaAnunciar = false;
volatile uint32_t instanteDesconexao = 0;
volatile uint32_t comandosRecebidos = 0;
volatile uint32_t conexoes = 0;

class CallbacksServidor : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    estaConectado = true;
    novaConexao = true;
    conexoes = conexoes + 1;
  }
  void onDisconnect(BLEServer*) override {
    estaConectado = false;
    precisaAnunciar = true;
    instanteDesconexao = millis();
  }
};

class CallbacksComando : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    auto valor = c->getValue();            // std::string (core 2.x) ou String (core 3.x)
    TextoComando t;
    size_t n = valor.length();
    if (n > COMANDO_MAX_CHARS) n = COMANDO_MAX_CHARS;
    memcpy(t.txt, valor.c_str(), n);
    t.txt[n] = 0;
    comandosRecebidos = comandosRecebidos + 1;
    if (filaComandos) xQueueSend(filaComandos, &t, 0);
  }
};

CallbacksServidor cbServidor;
CallbacksComando  cbComando;

void adicionarCccd(BLECharacteristic* c) {
#if !defined(CONFIG_NIMBLE_ENABLED)
  c->addDescriptor(new BLE2902());        // necessário para o app ativar notificações
#else
  (void)c;
#endif
}

}  // namespace

void iniciar(const char* nome) {
  filaComandos = xQueueCreate(8, sizeof(TextoComando));

  BLEDevice::init(nome);
  BLEDevice::setMTU(BLE_MTU);
  servidor = BLEDevice::createServer();
  servidor->setCallbacks(&cbServidor);

  BLEService* servico = servidor->createService(BLE_UUID_SERVICO);

  BLECharacteristic* carComando = servico->createCharacteristic(
      BLE_UUID_COMANDO,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  carComando->setCallbacks(&cbComando);

  carEstado = servico->createCharacteristic(
      BLE_UUID_ESTADO,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  adicionarCccd(carEstado);
  carEstado->setValue("{}");

  carEvento = servico->createCharacteristic(
      BLE_UUID_EVENTO, BLECharacteristic::PROPERTY_NOTIFY);
  adicionarCccd(carEvento);

  servico->start();

  BLEAdvertising* anuncio = BLEDevice::getAdvertising();
  anuncio->addServiceUUID(BLE_UUID_SERVICO);
  anuncio->setScanResponse(true);
  BLEDevice::startAdvertising();
}

void manter() {
  // Após desconectar, volta a anunciar (pequena espera para a pilha liberar).
  if (precisaAnunciar && (uint32_t)(millis() - instanteDesconexao) > 500) {
    precisaAnunciar = false;
    BLEDevice::startAdvertising();
  }
}

bool conectado() { return estaConectado; }

bool consumirNovaConexao() {
  if (!novaConexao) return false;
  novaConexao = false;
  return true;
}

bool proximoComando(char* destino, size_t tam) {
  if (!filaComandos || tam == 0) return false;
  TextoComando t;
  if (xQueueReceive(filaComandos, &t, 0) != pdTRUE) return false;
  strncpy(destino, t.txt, tam - 1);
  destino[tam - 1] = 0;
  return true;
}

void publicarEstado(const char* json, size_t tam) {
  if (!carEstado) return;
  carEstado->setValue((uint8_t*)json, tam);     // sempre atualizado para leitura
  if (estaConectado) carEstado->notify();
}

void publicarEvento(const char* json, size_t tam) {
  if (!carEvento || !estaConectado) return;
  carEvento->setValue((uint8_t*)json, tam);
  carEvento->notify();
}

void imprimirDiagnostico(Print& s) {
  s.printf("Bluetooth: %s  (\"%s\")  conexoes: %lu  comandos recebidos: %lu\n",
           estaConectado ? "CONECTADO" : "anunciando", BLE_NOME_DISPOSITIVO,
           (unsigned long)conexoes, (unsigned long)comandosRecebidos);
}

}  // namespace ble
