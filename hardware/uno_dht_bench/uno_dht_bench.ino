/*
  Qadam bench firmware — Arduino Uno + 2 x DHT22 (AM2302)
  ---------------------------------------------------------
  Role of the two sensors (one per foot, same plantar site = 1st metatarsal head, "mth1"):
    DHT LEFT  -> D2     DHT RIGHT -> D3
  The board only MEASURES and REPORTS. It never decides green/amber/red:
  the rule runs in the app and is re-checked by the hub (one tested implementation, no re-flashing).

  IMPORTANT: a DHT22 measures AIR temperature (+/-0.5 C, 0.1 C resolution, 1 reading / 2 s).
  It is used here as a prototype bench to demonstrate the full data chain. It is NOT a skin
  thermometer and NOT a medical device. The product roadmap uses contact sensors (DS18B20 / NTC).

  Serial frame (115200 baud, one line every 2.5 s):
    $QDM,1,<seq>,<tL>,<tR>,<spreadL>,<spreadR>,<n>,<hL>,<hR>,<flags>*<CRC8>
      tL/tR       mean temperature of the last 4 valid readings (C, 2 decimals) or "nan"
      spreadL/R   max-min of those readings (stability, used for the confidence index)
      n           number of valid readings in the window (min of both sides, 0..4)
      hL/hR       mean relative humidity (%), diagnostics only
      flags       bit0 left sensor fault, bit1 right sensor fault, bit2 warming up (window not full)
      CRC8        CRC-8/ATM (poly 0x07, init 0x00) of the characters between '$' and '*', 2 hex digits
  Lines starting with '#' are information (boot banner, errors) and are ignored by the bridge.

  Libraries (Arduino IDE > Library Manager): "DHT sensor library" (Adafruit) + "Adafruit Unified Sensor".
*/
#include <DHT.h>

#define DHT_TYPE DHT22      // change to DHT11 if that is the sensor you have (1 C resolution: demo only)
const uint8_t PIN_DHT_LEFT = 2;
const uint8_t PIN_DHT_RIGHT = 3;
const uint8_t PIN_LED_OK = 5;      // green: blinks on every valid frame
const uint8_t PIN_LED_FAULT = 6;   // red: on while a sensor is in fault
const uint8_t PIN_BUZZER = 8;      // active buzzer: 2 beeps at boot, 1 long beep when a fault appears

const unsigned long PERIOD_MS = 2500;  // DHT22 needs >= 2 s between reads
const uint8_t WINDOW = 4;              // 4 x 2.5 s = 10 s averaging window
const uint8_t FAULT_AFTER = 2;         // consecutive failed reads before declaring a fault

DHT dhtL(PIN_DHT_LEFT, DHT_TYPE);
DHT dhtR(PIN_DHT_RIGHT, DHT_TYPE);

struct Channel {
  float t[WINDOW];
  float h[WINDOW];
  uint8_t count = 0;    // valid readings stored (<= WINDOW)
  uint8_t head = 0;
  uint8_t failures = 0; // consecutive failed reads
};
Channel chL, chR;
unsigned long seq = 0;
unsigned long lastRead = 0;
bool lastFault = false;

uint8_t crc8(const char *s) {
  uint8_t crc = 0x00;
  while (*s) {
    crc ^= (uint8_t)*s++;
    for (uint8_t i = 0; i < 8; i++) crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0x07) : (uint8_t)(crc << 1);
  }
  return crc;
}

void beep(unsigned int ms) {
  digitalWrite(PIN_BUZZER, HIGH);
  delay(ms);
  digitalWrite(PIN_BUZZER, LOW);
}

void sample(DHT &d, Channel &c) {
  float t = d.readTemperature();
  float h = d.readHumidity();
  // reject failed or physically implausible readings (sensor unplugged, noise on the line)
  if (isnan(t) || isnan(h) || t < -10.0 || t > 60.0) {
    if (c.failures < 255) c.failures++;
    if (c.failures >= FAULT_AFTER) { c.count = 0; c.head = 0; }  // drop stale values: never report an old reading as new
    return;
  }
  c.failures = 0;
  c.t[c.head] = t;
  c.h[c.head] = h;
  c.head = (c.head + 1) % WINDOW;
  if (c.count < WINDOW) c.count++;
}

bool faulty(const Channel &c) { return c.failures >= FAULT_AFTER || c.count == 0; }

void stats(const Channel &c, float &mean, float &spread, float &hum) {
  if (c.count == 0) { mean = NAN; spread = NAN; hum = NAN; return; }
  float sum = 0, hs = 0, lo = 1000, hi = -1000;
  for (uint8_t i = 0; i < c.count; i++) {
    sum += c.t[i]; hs += c.h[i];
    if (c.t[i] < lo) lo = c.t[i];
    if (c.t[i] > hi) hi = c.t[i];
  }
  mean = sum / c.count; spread = hi - lo; hum = hs / c.count;
}

// AVR snprintf has no %f: format floats with dtostrf, "nan" when missing
void fmt(char *out, float v, uint8_t decimals) {
  if (isnan(v)) { strcpy(out, "nan"); return; }
  dtostrf(v, 0, decimals, out);
}

void setup() {
  pinMode(PIN_LED_OK, OUTPUT);
  pinMode(PIN_LED_FAULT, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  Serial.begin(115200);
  dhtL.begin();
  dhtR.begin();
  Serial.println(F("#QDM boot uno-dht22-bench fw=1.1 frame=v1 period_ms=2500 window=4"));
  beep(80); delay(80); beep(80);
  delay(2000);  // DHT22 power-up time
}

void loop() {
  if (millis() - lastRead < PERIOD_MS) return;
  lastRead = millis();
  sample(dhtL, chL);
  sample(dhtR, chR);

  float tL, tR, sL, sR, hL, hR;
  stats(chL, tL, sL, hL);
  stats(chR, tR, sR, hR);
  uint8_t flags = 0;
  if (faulty(chL)) flags |= 0x01;
  if (faulty(chR)) flags |= 0x02;
  if (chL.count < WINDOW || chR.count < WINDOW) flags |= 0x04;
  uint8_t n = min(chL.count, chR.count);

  char a[10], b[10], c[10], d[10], e[10], f[10];
  fmt(a, tL, 2); fmt(b, tR, 2); fmt(c, sL, 2); fmt(d, sR, 2); fmt(e, hL, 1); fmt(f, hR, 1);
  char body[96];
  snprintf(body, sizeof(body), "QDM,1,%lu,%s,%s,%s,%s,%u,%s,%s,%u", ++seq, a, b, c, d, n, e, f, flags);
  char crc[3];
  snprintf(crc, sizeof(crc), "%02X", crc8(body));
  Serial.print('$'); Serial.print(body); Serial.print('*'); Serial.println(crc);

  bool fault = flags & 0x03;
  digitalWrite(PIN_LED_FAULT, fault ? HIGH : LOW);
  if (fault && !lastFault) {
    Serial.println((flags & 0x01) ? F("#QDM error left sensor not responding (check D2 wiring / pull-up)")
                                : F("#QDM error right sensor not responding (check D3 wiring / pull-up)"));
    beep(400);
  }
  lastFault = fault;
  if (!fault) { digitalWrite(PIN_LED_OK, HIGH); delay(60); digitalWrite(PIN_LED_OK, LOW); }
}
