// =====================================================================
//  BoviCare - Brete automatizado
//  protocolo.h  ->  comandos de texto e mensagens JSON     (LÓGICA PURA)
//
//  O mesmo protocolo é usado pela serial USB e pelo Bluetooth.
//  Especificação completa em docs/PROTOCOLO_BLE.md.
// =====================================================================
#pragma once
#include "tipos.h"
#include "controlador.h"

// Tamanho máximo do JSON de estado: cabe numa notificação BLE com MTU 185
// (o iOS negocia 185; no Android o app pede MTU 247).
#define JSON_ESTADO_MAX   182
#define JSON_EVENTO_MAX   120
#define COMANDO_MAX_CHARS  64

// Converte um texto ("ABRIR 1", "#17 fechar saida", "JOG 2 SOBE 300")
// em Comando. Retorna false se o texto estiver vazio.
bool interpretarComando(const char* texto, Comando& out);

// Monta o JSON de estado e o de evento. Retornam o tamanho (sem o \0).
size_t jsonEstado(const Controlador& c, uint32_t segundosLigado, char* buf, size_t tam);
size_t jsonEvento(const Evento& ev, char* buf, size_t tam);

// Nomes usados nas mensagens
const char* nomeEstado(EstadoPorta e);
const char* nomeFalha(FalhaPorta f);
const char* nomeResultado(Resultado r);
const char* nomeComando(TipoComando t);
const char* nomeOrigem(Origem o);
const char* nomeEvento(TipoEvento t);
const char* nomeAcao(AcaoMotor a);
