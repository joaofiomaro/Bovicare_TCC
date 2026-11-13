#pragma once
#include "Arduino.h"
struct SPIClass { int inicios = 0; void begin(int, int, int, int) { inicios++; } };
extern SPIClass SPI;
