// =====================================================================
//  BoviCare - Sistema Integrado de Gestão Pecuária
//  Firmware do brete automatizado (ESP32 DevKit 38 pinos, WROOM-32)
//
//  TCC de Engenharia de Computação
//  João Pedro Fiomaro Santos e Leonardo Moreira Trento Pinge
//  Orientador: Prof. Renato Ferrari da Costa
//
//  Laço principal (núcleo 1), sem nenhuma espera bloqueante:
//    1. lê e filtra as entradas (fins de curso, sensores IR, botões)
//    2. avança a lógica (portas, emergência, intertravamento)
//    3. executa comandos recebidos (serial USB e Bluetooth)
//    4. recebe os eventos do leitor RFID (tarefa no núcleo 0)
//    5. aplica as saídas nos motores (L298N)
//    6. publica eventos e estado (serial e Bluetooth)
//  A segurança (parada por presença, fins de curso, tempos-limite) roda
//  inteira aqui, no ESP32: não depende do aplicativo nem da conexão.
//
//  Mapa de pinos: config_pinos.h   |   Ajustes: parametros.h
//  Ligações:      docs/LIGACOES.md |   Protocolo: docs/PROTOCOLO_BLE.md
// =====================================================================
//
//  Este arquivo é propositalmente curto: todo o código está nos .cpp da
//  pasta (aplicacao.cpp tem o laço). Assim o pré-processador do Arduino
//  não precisa gerar protótipos e o projeto compila igual no Arduino IDE
//  e no PlatformIO.
// =====================================================================
#include "aplicacao.h"

void setup() {
  aplicacaoIniciar();
}

void loop() {
  aplicacaoLaco();
}
