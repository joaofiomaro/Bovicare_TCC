// =====================================================================
//  BoviCare - estado da placa simulada (ver stubs/Arduino.h)
//
//  A tarefa do RFID roda numa thread de verdade, mas nunca ao mesmo tempo
//  que o laço principal: ela só anda quando o relógio simulado chega na
//  hora em que o vTaskDelay dela termina, e devolve o controle no próximo
//  vTaskDelay. Assim a intercalação entre os dois núcleos é a do ESP32,
//  só que sempre igual de uma execução para a outra.
// =====================================================================
#include <condition_variable>
#include <mutex>
#include <thread>
#include "stubs/Arduino.h"
#include "stubs/BLEDevice.h"
#include "stubs/MFRC522.h"
#include "stubs/Preferences.h"
#include "stubs/SPI.h"

namespace sim {
uint32_t agoraMs = 0;
int nivel[40];
int saida[40];
int modo[40];
uint32_t milivolts[40];
int duty[40];
bool pwmLigado[40];
std::function<void(uint32_t)> aoPassarTempo;

std::vector<NotificacaoBle> notificacoes;
int anuncios = 0;
std::string nomeBle;
BLEServer* servidorBle = nullptr;
BLEAdvertising anuncioBle;

std::map<std::string, uint32_t> nvs;
int gravacoesNvs = 0;

bool rc522Responde = true;
bool rc522AntenaLigada = false;
std::vector<uint8_t> tagNoCampo;
int rc522Inits = 0;

void (*tarefaCriada)(void*) = nullptr;
int tarefaSuspensa = 0;

// ---- escalonador da tarefa do RFID
static std::mutex mx;
static std::condition_variable cv;
static bool vezDaTarefa = false;
static bool tarefaExiste = false;
static uint32_t acordarEm = 0;
static thread_local bool naTarefa = false;

static void passarParaTarefa() {
  std::unique_lock<std::mutex> l(mx);
  vezDaTarefa = true;
  cv.notify_all();
  cv.wait(l, [] { return !vezDaTarefa; });
}

static void corpoDaTarefa(void (*f)(void*)) {
  {
    std::unique_lock<std::mutex> l(mx);
    cv.wait(l, [] { return vezDaTarefa; });
  }
  naTarefa = true;
  f(nullptr);   // laço infinito: nunca volta
}

void iniciarTarefa(void (*f)(void*)) {
  tarefaExiste = true;
  acordarEm = agoraMs;
  std::thread(corpoDaTarefa, f).detach();
  passarParaTarefa();   // roda até o primeiro vTaskDelay
}

void avancar(uint32_t ms) {
  for (uint32_t k = 0; k < ms; k++) {
    agoraMs++;
    if (aoPassarTempo) aoPassarTempo(agoraMs);
    if (!naTarefa && tarefaExiste && !tarefaSuspensa && (int32_t)(agoraMs - acordarEm) >= 0) passarParaTarefa();
  }
}
}  // namespace sim

void vTaskDelay(TickType_t ticks) {
  sim::acordarEm = sim::agoraMs + (ticks ? ticks : 1);
  std::unique_lock<std::mutex> l(sim::mx);
  sim::vezDaTarefa = false;
  sim::cv.notify_all();
  sim::cv.wait(l, [] { return sim::vezDaTarefa; });
}

// pino de entrada: -1 = nada ligado (flutuando), segue o pull-up / pull-down interno
int digitalRead(uint8_t p) {
  if (sim::modo[p] == OUTPUT) return sim::saida[p];
  int v = sim::nivel[p];
  if (v >= 0) return v;
  if (sim::modo[p] == INPUT_PULLUP) return HIGH;
  return LOW;
}

QueueHandle_t xQueueCreate(size_t capacidade, size_t tamItem) { return new FilaSim{tamItem, capacidade, {}}; }

BaseType_t xQueueSend(QueueHandle_t q, const void* item, TickType_t) {
  if (!q || q->itens.size() >= q->capacidade) return pdFALSE;
  const uint8_t* b = (const uint8_t*)item;
  q->itens.emplace_back(b, b + q->tamItem);
  return pdTRUE;
}

BaseType_t xQueueReceive(QueueHandle_t q, void* item, TickType_t) {
  if (!q || q->itens.empty()) return pdFALSE;
  memcpy(item, q->itens.front().data(), q->tamItem);
  q->itens.pop_front();
  return pdTRUE;
}

EspClass ESP;
SerialSim Serial;
SPIClass SPI;
