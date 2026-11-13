#!/usr/bin/env python3
"""BoviCare - valida as amostras de JSON geradas pelo teste de lógica.

Cada linha do arquivo deve ser um JSON válido. Confere também o tamanho
máximo do estado numa notificação BLE: MTU 185 -> 182 bytes úteis na versão
modular 1.0.3 (padrão) e MTU 247 -> 244 bytes na 1.5.1 (segundo argumento).
Uso: validar_json.py amostras.txt [limite_em_bytes]
"""
import json
import sys

LIMITE_ESTADO = int(sys.argv[2]) if len(sys.argv) > 2 else 182
CHAVES_ESTADO = {"p1", "p2", "f1", "f2", "ir", "fa", "ff", "em", "bot", "rfid", "rok", "up"}

arquivo = sys.argv[1] if len(sys.argv) > 1 else "amostras_json.txt"
ok = falhas = 0
with open(arquivo, encoding="utf-8") as f:
    for n, linha in enumerate(f, 1):
        linha = linha.rstrip("\n")
        if not linha:
            continue
        try:
            obj = json.loads(linha)
        except json.JSONDecodeError as e:
            print(f"  FALHOU linha {n}: JSON invalido ({e}): {linha}")
            falhas += 1
            continue
        ok += 1
        if "ev" not in obj:  # é um estado
            faltando = CHAVES_ESTADO - obj.keys()
            if faltando:
                print(f"  FALHOU linha {n}: estado sem as chaves {sorted(faltando)}")
                falhas += 1
            if len(linha.encode()) > LIMITE_ESTADO:
                print(f"  FALHOU linha {n}: estado com {len(linha.encode())} bytes (> {LIMITE_ESTADO})")
                falhas += 1
            else:
                ok += 1

print(f"Validacao de JSON: {ok} verificacoes OK, {falhas} falhas")
sys.exit(1 if falhas else 0)
