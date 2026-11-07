#!/usr/bin/env bash
# =====================================================================
#  BoviCare - roda todos os testes da lógica do firmware no computador
#  Requisitos: g++ (C++17) e python3.   Uso: bash rodar_testes.sh
# =====================================================================
set -e
cd "$(dirname "$0")"
SRC=../BoviCare_Brete
MOD="$SRC/porta.cpp $SRC/controlador.cpp $SRC/protocolo.cpp"
FLAGS="-std=c++17 -Wall -Wextra -Werror -O1 -I$SRC"
mkdir -p build

echo "== Compilando (com -Wall -Wextra -Werror) =="
g++ $FLAGS -fsanitize=address,undefined teste_logica.cpp $MOD -o build/teste_logica
g++ $FLAGS -fsanitize=address,undefined simulacao.cpp $MOD -o build/simulacao

echo; echo "== Testes da logica =="
./build/teste_logica build/amostras_json.txt
echo; echo "== Validacao do JSON =="
python3 validar_json.py build/amostras_json.txt
echo; echo "== Simulacao fisica =="
./build/simulacao
echo; echo "TODOS OS TESTES PASSARAM"
