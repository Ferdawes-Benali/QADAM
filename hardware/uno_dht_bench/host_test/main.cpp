#include "Arduino.h"
#include "DHT.h"
unsigned long g_millis = 0;
SerialShim Serial;
// Script: t < 30 s normal (30.2 / 30.4), 30-60 s right hotspot (+2.8), 60-70 s left sensor unplugged, then normal.
float scripted_temp(int pin, unsigned long now) {
  float s = now / 1000.0f;
  if (pin == 2) return (s >= 60 && s < 70) ? NAN : 30.2f + 0.05f * ((int)s % 3);
  return (s >= 30 && s < 60) ? 33.0f : 30.4f;
}
#include "../uno_dht_bench.ino"
int main() {
  setup();
  for (int i = 0; i < 40; i++) { g_millis += 2500; loop(); }
  return 0;
}
