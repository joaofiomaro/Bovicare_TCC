// =====================================================================
//  BoviCare - imitação da placa ESP32 para rodar o firmware 1.5.1 no PC
//
//  Os testes de testes_nativos/final/ compilam o próprio arquivo
//  BoviCare_Brete_Final.ino, sem nenhuma alteração, contra estas imitações:
//  pinos, tempo, PWM, Serial, memória (NVS), filas do FreeRTOS, Bluetooth
//  e leitor RC522. O tempo é simulado: millis() só anda quando o teste
//  manda (ou quando o firmware chama delay()).
// =====================================================================
#pragma once
#include <cctype>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <functional>
#include <map>
#include <string>
#include <vector>

#define ESP_ARDUINO_VERSION_MAJOR 3   // core 3.x: ledcAttach(pino, ...) / ledcWrite(pino, ...)

typedef uint8_t byte;
#define HIGH 1
#define LOW 0
#define INPUT 0x01
#define OUTPUT 0x03
#define INPUT_PULLUP 0x05
#define INPUT_PULLDOWN 0x09
enum adc_attenuation_t { ADC_0db, ADC_2_5db, ADC_6db, ADC_11db };

// ---------------------------------------------------------------- placa simulada
namespace sim {
extern uint32_t agoraMs;
extern int nivel[40];          // nível lido em cada GPIO (digitalRead)
extern int saida[40];          // nível escrito em cada GPIO (digitalWrite)
extern int modo[40];           // pinMode de cada GPIO
extern uint32_t milivolts[40]; // analogReadMilliVolts
extern int duty[40];           // ledcWrite por pino
extern bool pwmLigado[40];     // ledcAttach / ledcDetach
extern std::function<void(uint32_t)> aoPassarTempo;   // física do brete (1 chamada por ms)
void avancar(uint32_t ms);     // anda o relógio de 1 em 1 ms, chamando a física
}

inline uint32_t millis() { return sim::agoraMs; }
inline void delay(uint32_t ms) { sim::avancar(ms); }
inline void delayMicroseconds(uint32_t) {}
inline void pinMode(uint8_t p, uint8_t m) { sim::modo[p] = m; }
inline void digitalWrite(uint8_t p, uint8_t v) { sim::saida[p] = v; }
int digitalRead(uint8_t p);
inline uint32_t analogReadMilliVolts(uint8_t p) { return sim::milivolts[p]; }
inline void analogSetPinAttenuation(uint8_t, adc_attenuation_t) {}
inline void analogReadResolution(uint8_t) {}
inline bool ledcAttach(uint8_t p, uint32_t, uint8_t) { sim::pwmLigado[p] = true; return true; }
inline bool ledcDetach(uint8_t p) { sim::pwmLigado[p] = false; return true; }
inline bool ledcWrite(uint8_t p, uint32_t d) { sim::duty[p] = (int)d; return true; }
inline void enableLoopWDT() {}
inline void disableLoopWDT() {}

struct Reiniciou {};   // ESP.restart() no teste: sai do laço como exceção
struct EspClass {
  int reinicios = 0;
  [[noreturn]] void restart() { reinicios++; throw Reiniciou{}; }
};
extern EspClass ESP;

// ---------------------------------------------------------------- Serial
class String : public std::string {
 public:
  using std::string::string;
  String(const std::string& s) : std::string(s) {}
};

struct SerialSim {
  std::string saidaTexto;        // tudo o que o firmware imprimiu
  std::deque<char> entrada;      // o que o "usuário" digitou
  void begin(unsigned long) {}
  void flush() {}
  int available() { return (int)entrada.size(); }
  int read() {
    if (entrada.empty()) return -1;
    char c = entrada.front();
    entrada.pop_front();
    return (unsigned char)c;
  }
  void print(const char* s) { saidaTexto += s; }
  void println(const char* s) { saidaTexto += s; saidaTexto += "\n"; }
  void println() { saidaTexto += "\n"; }
  int printf(const char* fmt, ...) __attribute__((format(printf, 2, 3))) {
    char b[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(b, sizeof(b), fmt, ap);
    va_end(ap);
    saidaTexto += b;
    return n;
  }
  void digitar(const std::string& linha) { for (char c : linha) entrada.push_back(c); entrada.push_back('\n'); }
};
extern SerialSim Serial;

// ---------------------------------------------------------------- FreeRTOS
typedef int BaseType_t;
typedef uint32_t TickType_t;
#define pdTRUE 1
#define pdFALSE 0
#define pdMS_TO_TICKS(ms) ((TickType_t)(ms))
struct FilaSim {
  size_t tamItem, capacidade;
  std::deque<std::vector<uint8_t>> itens;
};
typedef FilaSim* QueueHandle_t;
typedef void* TaskHandle_t;
QueueHandle_t xQueueCreate(size_t capacidade, size_t tamItem);
BaseType_t xQueueSend(QueueHandle_t q, const void* item, TickType_t);
BaseType_t xQueueReceive(QueueHandle_t q, void* item, TickType_t);

namespace sim {
extern void (*tarefaCriada)(void*);   // a tarefa do RFID não roda sozinha: o teste decide
extern int tarefaSuspensa;
void iniciarTarefa(void (*f)(void*));   // roda a tarefa até o primeiro vTaskDelay
}
inline BaseType_t xTaskCreatePinnedToCore(void (*f)(void*), const char*, uint32_t, void*, unsigned, TaskHandle_t* h, int) {
  sim::tarefaCriada = f;
  if (h) *h = (TaskHandle_t)f;
  sim::iniciarTarefa(f);
  return pdTRUE;
}
inline void vTaskSuspend(TaskHandle_t) { sim::tarefaSuspensa++; }
void vTaskDelay(TickType_t ticks);
