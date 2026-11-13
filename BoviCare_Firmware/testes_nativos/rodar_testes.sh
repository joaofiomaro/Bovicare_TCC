#!/usr/bin/env bash
# =====================================================================
#  BoviCare - roda todos os testes do firmware no computador
#  Requisitos: g++ (C++17) e python3.   Uso: bash rodar_testes.sh
#
#  1) final/: o firmware que vai no brete (BoviCare_Brete_Final.ino, 1.5.1),
#     compilado sem alteração contra uma placa ESP32 simulada e ligado a um
#     modelo físico das duas porteiras.
#  2) teste_logica.cpp e simulacao.cpp: a versão modular anterior (1.0.3),
#     mantida como referência.
# =====================================================================
set -e
cd "$(dirname "$0")"
FLAGS="-std=c++17 -Wall -Wextra -Werror -O1"
SAN="-fsanitize=address,undefined"

echo "== Firmware 1.5.1 (BoviCare_Brete_Final.ino) =="
mkdir -p final/build
g++ $FLAGS $SAN -Ifinal/stubs final/teste_final.cpp final/placa_sim.cpp -o final/build/teste_final -lpthread
./final/build/teste_final final/build/amostras_final.txt
python3 validar_json.py final/build/amostras_final.txt 244

echo; echo "== Versao modular 1.0.3 (BoviCare_Brete/) =="
SRC=../BoviCare_Brete
MOD="$SRC/porta.cpp $SRC/controlador.cpp $SRC/protocolo.cpp"
mkdir -p build
g++ $FLAGS $SAN -I$SRC teste_logica.cpp $MOD -o build/teste_logica
g++ $FLAGS $SAN -I$SRC simulacao.cpp $MOD -o build/simulacao
./build/teste_logica build/amostras_json.txt
python3 validar_json.py build/amostras_json.txt
./build/simulacao

echo; echo "TODOS OS TESTES PASSARAM"
