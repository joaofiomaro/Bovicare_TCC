// Imitação da memória NVS (Preferences): um mapa que sobrevive ao "reinício" simulado.
#pragma once
#include "Arduino.h"
namespace sim { extern std::map<std::string, uint32_t> nvs; extern int gravacoesNvs; }
class Preferences {
 public:
  bool begin(const char*, bool) { return true; }
  void clear() { sim::nvs.clear(); }
  void putUInt(const char* k, uint32_t v) { sim::nvs[k] = v; sim::gravacoesNvs++; }
  void putUChar(const char* k, uint8_t v) { sim::nvs[k] = v; sim::gravacoesNvs++; }
  void putBool(const char* k, bool v) { sim::nvs[k] = v; sim::gravacoesNvs++; }
  uint32_t getUInt(const char* k, uint32_t d) { auto it = sim::nvs.find(k); return it == sim::nvs.end() ? d : it->second; }
  uint8_t getUChar(const char* k, uint8_t d) { auto it = sim::nvs.find(k); return it == sim::nvs.end() ? d : (uint8_t)it->second; }
  bool getBool(const char* k, bool d) { auto it = sim::nvs.find(k); return it == sim::nvs.end() ? d : it->second != 0; }
};
