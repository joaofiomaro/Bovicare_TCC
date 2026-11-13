// Imitação do Bluetooth do ESP32 (Bluedroid) para os testes no PC.
#pragma once
#include "Arduino.h"

class BLEServer;
class BLECharacteristic;

class BLEDescriptor { public: virtual ~BLEDescriptor() {} };
class BLE2902 : public BLEDescriptor {};

class BLEServerCallbacks {
 public:
  virtual ~BLEServerCallbacks() {}
  virtual void onConnect(BLEServer*) {}
  virtual void onDisconnect(BLEServer*) {}
};

class BLECharacteristicCallbacks {
 public:
  virtual ~BLECharacteristicCallbacks() {}
  virtual void onWrite(BLECharacteristic*) {}
};

struct NotificacaoBle { std::string uuid, valor; };
namespace sim {
extern std::vector<NotificacaoBle> notificacoes;   // tudo o que foi notificado ao app
extern int anuncios;                               // vezes em que o anúncio BLE foi (re)ligado
extern std::string nomeBle;
}

class BLECharacteristic {
 public:
  static const uint32_t PROPERTY_READ = 1 << 0;
  static const uint32_t PROPERTY_WRITE = 1 << 1;
  static const uint32_t PROPERTY_NOTIFY = 1 << 2;
  static const uint32_t PROPERTY_WRITE_NR = 1 << 3;
  std::string uuid, valor;
  uint32_t props = 0;
  BLECharacteristicCallbacks* cb = nullptr;
  std::vector<BLEDescriptor*> descritores;
  BLECharacteristic(const char* u, uint32_t p) : uuid(u), props(p) {}
  ~BLECharacteristic() { for (auto* d : descritores) delete d; }
  void setCallbacks(BLECharacteristicCallbacks* c) { cb = c; }
  void addDescriptor(BLEDescriptor* d) { descritores.push_back(d); }
  void setValue(const char* s) { valor = s; }
  void setValue(uint8_t* d, size_t n) { valor.assign((const char*)d, n); }
  String getValue() { return String(valor); }
  void notify() { sim::notificacoes.push_back({uuid, valor}); }
};

class BLEService {
 public:
  std::string uuid;
  std::vector<BLECharacteristic*> caracteristicas;
  bool iniciado = false;
  explicit BLEService(const char* u) : uuid(u) {}
  ~BLEService() { for (auto* c : caracteristicas) delete c; }
  BLECharacteristic* createCharacteristic(const char* u, uint32_t p) {
    caracteristicas.push_back(new BLECharacteristic(u, p));
    return caracteristicas.back();
  }
  void start() { iniciado = true; }
};

class BLEServer {
 public:
  BLEServerCallbacks* cb = nullptr;
  std::vector<BLEService*> servicos;
  ~BLEServer() { for (auto* s : servicos) delete s; }
  void setCallbacks(BLEServerCallbacks* c) { cb = c; }
  BLEService* createService(const char* u) { servicos.push_back(new BLEService(u)); return servicos.back(); }
};

class BLEAdvertising {
 public:
  std::vector<std::string> uuids;
  void addServiceUUID(const char* u) { uuids.push_back(u); }
  void setScanResponse(bool) {}
};

namespace sim { extern BLEServer* servidorBle; extern BLEAdvertising anuncioBle; }

class BLEDevice {
 public:
  static void init(const char* nome) { sim::nomeBle = nome; }
  static void setMTU(uint16_t) {}
  static BLEServer* createServer() { sim::servidorBle = new BLEServer(); return sim::servidorBle; }
  static BLEAdvertising* getAdvertising() { return &sim::anuncioBle; }
  static void startAdvertising() { sim::anuncios++; }
};
