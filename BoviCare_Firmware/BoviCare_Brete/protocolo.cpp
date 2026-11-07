// =====================================================================
//  BoviCare - Brete automatizado
//  protocolo.cpp  ->  interpretação de comandos e JSON     (LÓGICA PURA)
// =====================================================================
#include "protocolo.h"
#include "parametros.h"
#include <stdio.h>
#include <string.h>

// ---------------------------------------------------------------------
// Nomes
// ---------------------------------------------------------------------
const char* nomeEstado(EstadoPorta e) {
  switch (e) {
    case EstadoPorta::FECHADA:  return "FECHADA";
    case EstadoPorta::ABRINDO:  return "ABRINDO";
    case EstadoPorta::ABERTA:   return "ABERTA";
    case EstadoPorta::FECHANDO: return "FECHANDO";
    case EstadoPorta::PARADA:   return "PARADA";
    case EstadoPorta::RECUANDO: return "RECUANDO";
    case EstadoPorta::AJUSTE:   return "AJUSTE";
    case EstadoPorta::FALHA:    return "FALHA";
  }
  return "?";
}

const char* nomeFalha(FalhaPorta f) {
  switch (f) {
    case FalhaPorta::NENHUMA:        return "";
    case FalhaPorta::TIMEOUT_ABRIR:  return "TIMEOUT_ABRIR";
    case FalhaPorta::TIMEOUT_FECHAR: return "TIMEOUT_FECHAR";
    case FalhaPorta::FIM_DUPLO:      return "FIM_DUPLO";
    case FalhaPorta::FIM_PRESO:      return "FIM_PRESO";
  }
  return "?";
}

const char* nomeResultado(Resultado r) {
  switch (r) {
    case Resultado::OK:              return "OK";
    case Resultado::JA_ABERTA:       return "JA_ABERTA";
    case Resultado::JA_FECHADA:      return "JA_FECHADA";
    case Resultado::OBSTACULO:       return "OBSTACULO";
    case Resultado::FALHA:           return "FALHA";
    case Resultado::EMERGENCIA:      return "EMERGENCIA";
    case Resultado::INTERTRAVAMENTO: return "INTERTRAVAMENTO";
    case Resultado::NAO_PERMITIDO:   return "NAO_PERMITIDO";
    case Resultado::INVALIDO:        return "INVALIDO";
    case Resultado::PORTA_INVALIDA:  return "PORTA_INVALIDA";
    case Resultado::FIM_DE_CURSO:    return "FIM_DE_CURSO";
  }
  return "?";
}

const char* nomeComando(TipoComando t) {
  switch (t) {
    case TipoComando::NENHUM:     return "";
    case TipoComando::ABRIR:      return "ABRIR";
    case TipoComando::FECHAR:     return "FECHAR";
    case TipoComando::ALTERNAR:   return "ALTERNAR";
    case TipoComando::PARAR:      return "PARAR";
    case TipoComando::EMERGENCIA: return "EMERGENCIA";
    case TipoComando::RESET:      return "RESET";
    case TipoComando::STATUS:     return "STATUS";
    case TipoComando::PING:       return "PING";
    case TipoComando::DIAG:       return "DIAG";
    case TipoComando::AJUDA:      return "AJUDA";
    case TipoComando::JOG:        return "JOG";
    case TipoComando::INVALIDO:   return "INVALIDO";
  }
  return "?";
}

const char* nomeOrigem(Origem o) {
  switch (o) {
    case Origem::BOTAO:      return "BOTAO";
    case Origem::APP:        return "APP";
    case Origem::SERIAL_USB: return "SERIAL";
    case Origem::SISTEMA:    return "SISTEMA";
  }
  return "?";
}

const char* nomeEvento(TipoEvento t) {
  switch (t) {
    case TipoEvento::INICIO:     return "INICIO";
    case TipoEvento::PORTA:      return "PORTA";
    case TipoEvento::OBSTACULO:  return "OBSTACULO";
    case TipoEvento::FALHA:      return "FALHA";
    case TipoEvento::EMERGENCIA: return "EMERGENCIA";
    case TipoEvento::REARME:     return "REARME";
    case TipoEvento::RESP:       return "RESP";
    case TipoEvento::RFID:       return "RFID";
    case TipoEvento::RFID_SAIU:  return "RFID_SAIU";
    case TipoEvento::RFID_OK:    return "RFID_OK";
    case TipoEvento::RFID_ERRO:  return "RFID_ERRO";
  }
  return "?";
}

const char* nomeAcao(AcaoMotor a) {
  switch (a) {
    case AcaoMotor::PARADO: return "PARADO";
    case AcaoMotor::SUBIR:  return "SUBIR";
    case AcaoMotor::DESCER: return "DESCER";
    case AcaoMotor::FREAR:  return "FREAR";
  }
  return "?";
}

// ---------------------------------------------------------------------
// Interpretação de comandos
// ---------------------------------------------------------------------
static bool ehSeparador(char c) {
  return c == ' ' || c == ':' || c == '=' || c == ',' || c == ';' ||
         c == '\t' || c == '\r' || c == '\n';
}

// Lê um inteiro decimal sem sinal; retorna false se não for número.
static bool lerNumero(const char* s, uint32_t& valor) {
  if (!*s) return false;
  uint32_t v = 0;
  for (; *s; s++) {
    if (*s < '0' || *s > '9') return false;
    v = v * 10 + (uint32_t)(*s - '0');
    if (v > 1000000UL) return false;
  }
  valor = v;
  return true;
}

static int8_t lerPorta(const char* t) {
  if (!strcmp(t, "1") || !strcmp(t, "ENTRADA") || !strcmp(t, "E")) return 1;
  if (!strcmp(t, "2") || !strcmp(t, "SAIDA") || !strcmp(t, "S")) return 2;
  return -1;
}

static TipoComando lerTipo(const char* t) {
  struct Par { const char* nome; TipoComando tipo; };
  static const Par tabela[] = {
    {"ABRIR", TipoComando::ABRIR},       {"FECHAR", TipoComando::FECHAR},
    {"ALTERNAR", TipoComando::ALTERNAR}, {"PARAR", TipoComando::PARAR},
    {"EMERGENCIA", TipoComando::EMERGENCIA},
    {"RESET", TipoComando::RESET},       {"REARMAR", TipoComando::RESET},
    {"STATUS", TipoComando::STATUS},     {"ESTADO", TipoComando::STATUS},
    {"PING", TipoComando::PING},         {"DIAG", TipoComando::DIAG},
    {"AJUDA", TipoComando::AJUDA},       {"?", TipoComando::AJUDA},
    {"JOG", TipoComando::JOG},
  };
  for (const Par& p : tabela) {
    if (!strcmp(t, p.nome)) return p.tipo;
  }
  return TipoComando::INVALIDO;
}

bool interpretarComando(const char* texto, Comando& out) {
  out = Comando();
  if (!texto) return false;

  // Cópia em maiúsculas, separadores trocados por espaço
  char buf[COMANDO_MAX_CHARS + 1];
  size_t n = 0;
  for (const char* p = texto; *p && n < COMANDO_MAX_CHARS; p++) {
    char c = *p;
    if (ehSeparador(c)) c = ' ';
    else if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    buf[n++] = c;
  }
  buf[n] = 0;

  // Quebra em palavras
  const uint8_t MAX_TOK = 6;
  char* tok[MAX_TOK];
  uint8_t qt = 0;
  char* p = buf;
  while (*p && qt < MAX_TOK) {
    while (*p == ' ') p++;
    if (!*p) break;
    tok[qt++] = p;
    while (*p && *p != ' ') p++;
    if (*p) *p++ = 0;
  }
  if (qt == 0) return false;

  uint8_t k = 0;
  // Identificador opcional: "#17"
  if (tok[0][0] == '#') {
    uint32_t id;
    if (!lerNumero(tok[0] + 1, id) || id < 1 || id > 65535) {
      out.tipo = TipoComando::INVALIDO;
      return true;
    }
    out.id = (uint16_t)id;
    k = 1;
    if (qt == 1) { out.tipo = TipoComando::INVALIDO; return true; }
  }

  out.tipo = lerTipo(tok[k]);
  if (out.tipo == TipoComando::INVALIDO) return true;

  // Porta (opcional para PARAR; obrigatória para ABRIR/FECHAR/ALTERNAR/JOG)
  if (qt > k + 1) {
    bool aceitaPorta = out.tipo == TipoComando::ABRIR || out.tipo == TipoComando::FECHAR ||
                       out.tipo == TipoComando::ALTERNAR || out.tipo == TipoComando::PARAR ||
                       out.tipo == TipoComando::JOG;
    if (aceitaPorta) out.porta = lerPorta(tok[k + 1]);
  }

  if (out.tipo == TipoComando::JOG) {
    // JOG <porta> <SOBE|DESCE> [ms]
    if (qt < k + 3) { out.tipo = TipoComando::INVALIDO; return true; }
    const char* dir = tok[k + 2];
    if (!strcmp(dir, "SOBE") || !strcmp(dir, "SUBIR") || !strcmp(dir, "ABRIR")) out.jogSobe = true;
    else if (!strcmp(dir, "DESCE") || !strcmp(dir, "DESCER") || !strcmp(dir, "FECHAR")) out.jogSobe = false;
    else { out.tipo = TipoComando::INVALIDO; return true; }
    uint32_t ms = 300;
    if (qt > k + 3 && !lerNumero(tok[k + 3], ms)) { out.tipo = TipoComando::INVALIDO; return true; }
    if (ms > 65535) ms = 65535;
    out.jogMs = (uint16_t)ms;
  }
  return true;
}

// ---------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------
static size_t ajustar(int n, size_t tam) {
  if (n < 0) return 0;
  if ((size_t)n >= tam) return tam ? tam - 1 : 0;   // truncado
  return (size_t)n;
}

size_t jsonEstado(const Controlador& c, uint32_t segundosLigado, char* buf, size_t tam) {
  const Porta& p1 = c.porta(0);
  const Porta& p2 = c.porta(1);
  const EntradasSistema& e = c.entradas();
  int n = snprintf(buf, tam,
      "{\"p1\":\"%s\",\"p2\":\"%s\",\"f1\":\"%s\",\"f2\":\"%s\","
      "\"ir\":\"%d%d\",\"fa\":\"%d%d\",\"ff\":\"%d%d\",\"em\":%d,"
      "\"bot\":\"%d%d%d\",\"rfid\":\"%s\",\"rok\":%d,\"up\":%lu}",
      nomeEstado(p1.estado()), nomeEstado(p2.estado()),
      nomeFalha(p1.falha()), nomeFalha(p2.falha()),
      e.porta[0].obstaculo ? 1 : 0, e.porta[1].obstaculo ? 1 : 0,
      e.porta[0].fimAberta ? 1 : 0, e.porta[1].fimAberta ? 1 : 0,
      e.porta[0].fimFechada ? 1 : 0, e.porta[1].fimFechada ? 1 : 0,
      c.emergencia() ? 1 : 0,
      e.botao1 ? 1 : 0, e.botao2 ? 1 : 0, e.botaoParada ? 1 : 0,
      c.uidAtual(), c.rfidOk() ? 1 : 0, (unsigned long)segundosLigado);
  return ajustar(n, tam);
}

size_t jsonEvento(const Evento& ev, char* buf, size_t tam) {
  int n = 0;
  const char* nome = nomeEvento(ev.tipo);
  switch (ev.tipo) {
    case TipoEvento::INICIO:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"ver\":\"%s\"}", nome, FIRMWARE_VERSAO);
      break;
    case TipoEvento::PORTA:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"p\":%u,\"e\":\"%s\"}", nome,
                   (unsigned)ev.porta, nomeEstado(ev.estado));
      break;
    case TipoEvento::OBSTACULO:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"p\":%u}", nome, (unsigned)ev.porta);
      break;
    case TipoEvento::FALHA:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"p\":%u,\"f\":\"%s\"}", nome,
                   (unsigned)ev.porta, nomeFalha(ev.falha));
      break;
    case TipoEvento::EMERGENCIA:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"on\":%d,\"orig\":\"%s\"}", nome,
                   ev.ligado ? 1 : 0, nomeOrigem(ev.origem));
      break;
    case TipoEvento::REARME:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"orig\":\"%s\"}", nome, nomeOrigem(ev.origem));
      break;
    case TipoEvento::RESP:
      n = snprintf(buf, tam,
                   "{\"ev\":\"%s\",\"cmd\":\"%s\",\"p\":%u,\"id\":%u,\"res\":\"%s\",\"orig\":\"%s\"}",
                   nome, nomeComando(ev.cmd), (unsigned)ev.porta, (unsigned)ev.id,
                   nomeResultado(ev.res), nomeOrigem(ev.origem));
      break;
    case TipoEvento::RFID:
    case TipoEvento::RFID_SAIU:
      n = snprintf(buf, tam, "{\"ev\":\"%s\",\"uid\":\"%s\"}", nome, ev.uid);
      break;
    case TipoEvento::RFID_OK:
    case TipoEvento::RFID_ERRO:
      n = snprintf(buf, tam, "{\"ev\":\"%s\"}", nome);
      break;
  }
  return ajustar(n, tam);
}
