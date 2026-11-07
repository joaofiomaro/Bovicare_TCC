// =====================================================================
//  BoviCare - Brete automatizado
//  hardware_brete.cpp  ->  acesso aos pinos (único módulo que mexe neles,
//                          junto com o RC522 em leitor_rfid.cpp)
//
//  Compatível com o core ESP32 2.0.x e 3.x (a API de PWM "LEDC" mudou).
// =====================================================================
#include "hardware_brete.h"
#include "config_pinos.h"
#include "parametros.h"
#include "protocolo.h"
#include "limiar.h"

#if defined(ESP_ARDUINO_VERSION_MAJOR) && ESP_ARDUINO_VERSION_MAJOR >= 3
  #define BOVI_LEDC_V3 1
#else
  #define BOVI_LEDC_V3 0
#endif

namespace {

struct PinosMotor {
  uint8_t en, inA, inB;
  bool inverter;
  uint8_t canal;            // canal LEDC (usado só no core 2.x)
};

const PinosMotor MOTOR[2] = {
  {PINO_M1_EN, PINO_M1_IN1, PINO_M1_IN2, INVERTER_MOTOR_1 != 0, 0},
  {PINO_M2_EN, PINO_M2_IN3, PINO_M2_IN4, INVERTER_MOTOR_2 != 0, 1},
};

AcaoMotor acaoAtual[2] = {AcaoMotor::PARADO, AcaoMotor::PARADO};
uint8_t   pwmAtual[2] = {0, 0};

void pwmIniciar(const PinosMotor& m) {
#if BOVI_LEDC_V3
  ledcAttach(m.en, P_PWM_FREQ_HZ, P_PWM_BITS);
#else
  ledcSetup(m.canal, P_PWM_FREQ_HZ, P_PWM_BITS);
  ledcAttachPin(m.en, m.canal);
#endif
}

void pwmEscrever(const PinosMotor& m, uint8_t duty) {
#if BOVI_LEDC_V3
  ledcWrite(m.en, duty);
#else
  ledcWrite(m.canal, duty);
#endif
}

bool ler(uint8_t pino, bool ativoEmAlto) {
  bool alto = digitalRead(pino) == HIGH;
  return ativoEmAlto ? alto : !alto;
}

#if IR_LEITURA_ANALOGICA
// Começa em "obstáculo" (seguro) até a primeira leitura acima do limiar livre.
bool irObstaculoAnalog[2] = {true, true};
uint16_t irMilivolts[2] = {0, 0};

bool lerIrAnalogico(uint8_t indice, uint8_t pino) {
  uint32_t mv = analogReadMilliVolts(pino);
  irMilivolts[indice] = mv > 65535 ? 65535 : (uint16_t)mv;
  irObstaculoAnalog[indice] = irObstaculoPorTensao(irMilivolts[indice], irObstaculoAnalog[indice],
                                                   P_IR_LIMIAR_OBSTACULO_MV, P_IR_LIMIAR_LIVRE_MV);
  return irObstaculoAnalog[indice];
}
#endif

}  // namespace

namespace hw {

void iniciar() {
  // 1) Motores: tudo em nível baixo ANTES de qualquer outra coisa.
  for (const PinosMotor& m : MOTOR) {
    pinMode(m.inA, OUTPUT);
    pinMode(m.inB, OUTPUT);
    digitalWrite(m.inA, LOW);
    digitalWrite(m.inB, LOW);
    pinMode(m.en, OUTPUT);
    digitalWrite(m.en, LOW);
    pwmIniciar(m);
    pwmEscrever(m, 0);
  }

  // 2) Fins de curso: contato NF ao GND + pull-up interno.
  pinMode(PINO_FIM_1_ABERTA, INPUT_PULLUP);
  pinMode(PINO_FIM_1_FECHADA, INPUT_PULLUP);
  pinMode(PINO_FIM_2_ABERTA, INPUT_PULLUP);
  pinMode(PINO_FIM_2_FECHADA, INPUT_PULLUP);

  // 3) Sensores IR (34/35 não têm resistor interno: nível vem do divisor).
  pinMode(PINO_IR_1, INPUT);
  pinMode(PINO_IR_2, INPUT);
#if IR_LEITURA_ANALOGICA
  // 34 e 35 são canais do ADC1 (funcionam junto com o Bluetooth).
  analogReadResolution(12);
  analogSetPinAttenuation(PINO_IR_1, ADC_11db);   // faixa até ~3,1 V
  analogSetPinAttenuation(PINO_IR_2, ADC_11db);
#endif

  // 4) Botões: pull-down externo de 10 kΩ (36/39 não têm resistor interno).
  pinMode(PINO_BOTAO_1, INPUT);
  pinMode(PINO_BOTAO_2, INPUT);
  // Parada (contato NC): o pull-down garante BAIXO = parada se o fio romper.
  pinMode(PINO_BOTAO_PARADA, INPUT_PULLDOWN);   // reforço do pull-down externo

  pinMode(PINO_LED, OUTPUT);
  digitalWrite(PINO_LED, LOW);
}

void lerEntradas(EntradasBrutas& b) {
  const bool fimAlto = FIM_ACIONADO_EM_NIVEL_ALTO != 0;
  const bool irAlto = IR_OBSTACULO_EM_NIVEL_BAIXO == 0;
  const bool botAlto = BOTAO_PRESSIONADO_EM_ALTO != 0;
  const bool paradaAlto = PARADA_PRESSIONADA_EM_ALTO != 0;
  b.fimAberta[0]  = ler(PINO_FIM_1_ABERTA, fimAlto);
  b.fimFechada[0] = ler(PINO_FIM_1_FECHADA, fimAlto);
  b.fimAberta[1]  = ler(PINO_FIM_2_ABERTA, fimAlto);
  b.fimFechada[1] = ler(PINO_FIM_2_FECHADA, fimAlto);
#if IR_LEITURA_ANALOGICA
  (void)irAlto;
  b.obstaculo[0]  = lerIrAnalogico(0, PINO_IR_1);
  b.obstaculo[1]  = lerIrAnalogico(1, PINO_IR_2);
#else
  b.obstaculo[0]  = ler(PINO_IR_1, irAlto);
  b.obstaculo[1]  = ler(PINO_IR_2, irAlto);
#endif
  b.botao1        = ler(PINO_BOTAO_1, botAlto);
  b.botao2        = ler(PINO_BOTAO_2, botAlto);
  b.botaoParada   = ler(PINO_BOTAO_PARADA, paradaAlto);
}

// L298N (por canal):
//   SUBIR  -> INa=1, INb=0, EN=PWM
//   DESCER -> INa=0, INb=1, EN=PWM
//   FREAR  -> INa=0, INb=0, EN=100%  (terminais do motor em curto: freio dinâmico)
//   PARADO -> INa=0, INb=0, EN=0     (motor solto)
void aplicarMotor(uint8_t indice, AcaoMotor acao, uint8_t pwm) {
  if (indice > 1) return;
  const PinosMotor& m = MOTOR[indice];

  if (acao != acaoAtual[indice]) {
    // Desliga o enable antes de trocar o sentido.
    pwmEscrever(m, 0);
    bool a = false, b = false;
    if (acao == AcaoMotor::SUBIR)  { a = true;  b = false; }
    if (acao == AcaoMotor::DESCER) { a = false; b = true;  }
    if (m.inverter && (acao == AcaoMotor::SUBIR || acao == AcaoMotor::DESCER)) {
      bool t = a; a = b; b = t;
    }
    digitalWrite(m.inA, a ? HIGH : LOW);
    digitalWrite(m.inB, b ? HIGH : LOW);
    acaoAtual[indice] = acao;
    pwmAtual[indice] = 0;
  }

  uint8_t duty = 0;
  if (acao == AcaoMotor::SUBIR || acao == AcaoMotor::DESCER) duty = pwm;
  else if (acao == AcaoMotor::FREAR) duty = 255;
  if (duty != pwmAtual[indice]) {
    pwmEscrever(m, duty);
    pwmAtual[indice] = duty;
  }
}

void led(bool aceso) {
  digitalWrite(PINO_LED, aceso ? HIGH : LOW);
}

static void linha(Print& s, const char* nome, uint8_t pino, const char* repouso) {
  bool alto = digitalRead(pino) == HIGH;
  s.printf("  %-24s GPIO%-2u  %-5s  (repouso esperado: %s)\n", nome, (unsigned)pino,
           alto ? "ALTO" : "BAIXO", repouso);
}

void imprimirNiveis(Print& s) {
  s.println("Entradas (nivel eletrico):");
  linha(s, "Fim porta 1 ABERTA", PINO_FIM_1_ABERTA, "BAIXO");
  linha(s, "Fim porta 1 FECHADA", PINO_FIM_1_FECHADA, "BAIXO");
  linha(s, "Fim porta 2 ABERTA", PINO_FIM_2_ABERTA, "BAIXO");
  linha(s, "Fim porta 2 FECHADA", PINO_FIM_2_FECHADA, "BAIXO");
#if IR_LEITURA_ANALOGICA
  const uint8_t pinosIr[2] = {PINO_IR_1, PINO_IR_2};
  for (uint8_t i = 0; i < 2; i++) {
    uint32_t mv = analogReadMilliVolts(pinosIr[i]);
    s.printf("  Sensor IR porta %u          GPIO%-2u  %4lu mV (%s)  (livre > %u mV, obstaculo < %u mV)\n",
             (unsigned)(i + 1), (unsigned)pinosIr[i], (unsigned long)mv,
             irObstaculoAnalog[i] ? "OBSTACULO" : "livre",
             (unsigned)P_IR_LIMIAR_LIVRE_MV, (unsigned)P_IR_LIMIAR_OBSTACULO_MV);
  }
#else
  linha(s, "Sensor IR porta 1", PINO_IR_1, "ALTO");
  linha(s, "Sensor IR porta 2", PINO_IR_2, "ALTO");
#endif
  linha(s, "Botao 1 (porta 1)", PINO_BOTAO_1, "BAIXO");
  linha(s, "Botao 2 (porta 2)", PINO_BOTAO_2, "BAIXO");
  linha(s, "Botao PARADA", PINO_BOTAO_PARADA, PARADA_PRESSIONADA_EM_ALTO ? "BAIXO" : "ALTO");
  s.println("Motores:");
  for (uint8_t i = 0; i < 2; i++) {
    s.printf("  Motor %u: %-6s  PWM %3u  (EN GPIO%u, IN GPIO%u/GPIO%u)\n", (unsigned)(i + 1),
             nomeAcao(acaoAtual[i]), (unsigned)pwmAtual[i], (unsigned)MOTOR[i].en,
             (unsigned)MOTOR[i].inA, (unsigned)MOTOR[i].inB);
  }
}

}  // namespace hw
