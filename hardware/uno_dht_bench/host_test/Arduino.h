// Minimal host shim to compile and exercise the Uno sketch logic on a PC (g++). Not used on the board.
#pragma once
#include <cmath>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <algorithm>
#include <string>
using std::min;
using std::isnan;
#define F(x) (x)
#define HIGH 1
#define LOW 0
#define OUTPUT 1
#ifndef NAN
#define NAN (0.0f/0.0f)
#endif
extern unsigned long g_millis;
inline unsigned long millis() { return g_millis; }
inline void delay(unsigned long ms) { g_millis += ms; }
inline void pinMode(int, int) {}
inline void digitalWrite(int, int) {}
inline char *dtostrf(double v, signed char width, unsigned char prec, char *buf) { sprintf(buf, "%*.*f", width, prec, v); return buf; }
struct SerialShim {
  void begin(long) {}
  void print(const char *s) { fputs(s, stdout); }
  void print(char c) { fputc(c, stdout); }
  void println(const char *s) { fputs(s, stdout); fputc('\n', stdout); }
};
extern SerialShim Serial;
