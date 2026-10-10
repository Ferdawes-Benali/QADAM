/*
  Qadam smart foot mat - ESP32 firmware, Wokwi simulation build (same pin map as the real mat)
  Wokwi: board-esp32-devkit-c-v4. Libraries listed in libraries.txt.

  Pin map (identical to Engineering Package rev A):
    GPIO4  -> 1-Wire bus LEFT foot  (4 x DS18B20) + 4.7k pull-up to 3V3
    GPIO16 -> 1-Wire bus RIGHT foot (4 x DS18B20) + 4.7k pull-up to 3V3
    GPIO5  -> 330R -> WS2812 status LED DIN (LED powered from 3V3)
    GPIO18 -> buzzer   (real board: via 1k + 2N2222; Wokwi: direct)
    GPIO27 -> push button to GND (short press = scan now, hold 3 s = recalibrate)
    GPIO34 -> battery sense (real: 100k/100k divider; Wokwi: potentiometer)

  How to use the simulation:
    1. Start: all sensors at 25 C -> calibration -> LED off.
    2. Press SCAN -> 10 s scan -> JSON on Serial Monitor, LED green (normal).
    3. Click R-mth1 sensor (tR2), drag its slider to 28 C, press SCAN again
       -> dT = 3 C -> LED orange + long beep (hotspot detected).
*/
#include <WiFi.h>
#include <HTTPClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ArduinoJson.h>
#include <Adafruit_NeoPixel.h>

// ---------- configuration ----------
const bool SEND_HTTP = false;                  // true on the real mat (laptop backend reachable)
const char* WIFI_SSID = "Wokwi-GUEST";         // real mat: your router / hotspot
const char* WIFI_PASS = "";
const char* API_URL   = "http://192.168.1.10:8000/readings";
const char* PATIENT_ID = "P001";
const char* DEVICE_ID  = "mat-01";

const int PIN_OW_L = 4, PIN_OW_R = 16, PIN_LED = 5, PIN_BUZ = 18, PIN_BTN = 27, PIN_VBAT = 34;
const char* SITES[4] = {"hallux", "mth1", "mth5", "heel"};
// Wokwi "deviceID" attributes set in diagram.json (real mat: replace by the printed ROM codes)
const char* ID_L[4] = {"0A0000000001", "0A0000000002", "0A0000000003", "0A0000000004"};
const char* ID_R[4] = {"0B0000000001", "0B0000000002", "0B0000000003", "0B0000000004"};

const float FOOT_DETECT_RISE_C = 2.0;   // auto scan when every site > ambient + 2 C
const float DT_ALERT_C = 2.2;           // left/right difference threshold
const uint32_t SCAN_MS = 10000;         // real mat: 20000
const int AVG_LAST = 5;                 // real mat: 10

OneWire owL(PIN_OW_L), owR(PIN_OW_R);
DallasTemperature busL(&owL), busR(&owR);
Adafruit_NeoPixel led(1, PIN_LED, NEO_GRB + NEO_KHZ800);
DeviceAddress ADDR_L[4], ADDR_R[4];
float offsetL[4] = {0}, offsetR[4] = {0};
float ambient = 25.0;

void setLed(uint8_t r, uint8_t g, uint8_t b) { led.setPixelColor(0, led.Color(r, g, b)); led.show(); }
void beep(int ms) { tone(PIN_BUZ, 2000, ms); delay(ms); noTone(PIN_BUZ); }

String hex6(const uint8_t* a, bool rev) {
  char b[13];
  for (int i = 0; i < 6; i++) sprintf(b + 2 * i, "%02X", rev ? a[6 - i] : a[1 + i]);
  return String(b);
}

void mapBus(DallasTemperature& bus, DeviceAddress* table, const char** ids, const char* name) {
  bus.begin(); bus.setResolution(12); bus.setWaitForConversion(true);
  int n = bus.getDeviceCount();
  bool found[4] = {false, false, false, false};
  Serial.printf("Bus %s: %d sensors\n", name, n);
  DeviceAddress all[8]; int m = 0;
  for (int i = 0; i < n && i < 8; i++) {
    bus.getAddress(all[m], i);
    Serial.print("  ROM "); for (int k = 0; k < 8; k++) Serial.printf("%02X", all[m][k]);
    bool matched = false;
    for (int s = 0; s < 4; s++)
      if (!found[s] && (hex6(all[m], false) == ids[s] || hex6(all[m], true) == ids[s])) {
        memcpy(table[s], all[m], 8); found[s] = true; matched = true;
        Serial.printf("  -> %s-%s", name, SITES[s]);
      }
    Serial.println(matched ? "" : "  (unmapped)");
    m++;
  }
  for (int s = 0, k = 0; s < 4; s++)            // fallback: enumeration order
    if (!found[s] && k < m) { memcpy(table[s], all[k++], 8); Serial.printf("  %s-%s mapped by order\n", name, SITES[s]); }
  if (n != 4) Serial.printf("  WARNING: expected 4 sensors on bus %s\n", name);
}

bool readFoot(DallasTemperature& bus, DeviceAddress* addr, float* off, float* out) {
  bus.requestTemperatures();
  for (int i = 0; i < 4; i++) {
    float t = bus.getTempC(addr[i]);
    if (t == DEVICE_DISCONNECTED_C || t > 84.0 || t < -50.0) return false;
    out[i] = t - off[i];
  }
  return true;
}

void calibrate() {
  setLed(40, 0, 40);
  float sumL[4] = {0}, sumR[4] = {0}, l[4], r[4], zero[4] = {0}; int ok = 0;
  for (int k = 0; k < 5; k++)
    if (readFoot(busL, ADDR_L, zero, l) && readFoot(busR, ADDR_R, zero, r)) {
      for (int i = 0; i < 4; i++) { sumL[i] += l[i]; sumR[i] += r[i]; } ok++;
    }
  if (!ok) { Serial.println("Calibration failed - check wiring"); setLed(60, 0, 0); return; }
  float mean = 0;
  for (int i = 0; i < 4; i++) { sumL[i] /= ok; sumR[i] /= ok; mean += sumL[i] + sumR[i]; }
  ambient = mean / 8;
  for (int i = 0; i < 4; i++) { offsetL[i] = sumL[i] - ambient; offsetR[i] = sumR[i] - ambient; }
  Serial.printf("Calibrated: ambient %.2f C\n", ambient);
  beep(60); setLed(0, 0, 0);
}

bool feetPresent(float* l, float* r) {
  for (int i = 0; i < 4; i++)
    if (l[i] < ambient + FOOT_DETECT_RISE_C || r[i] < ambient + FOOT_DETECT_RISE_C) return false;
  return true;
}

float batteryVolts() { return analogReadMilliVolts(PIN_VBAT) * 2.0 / 1000.0; }

void sendScan(float* l, float* r, float maxDT, int site) {
  JsonDocument doc;
  doc["patient_id"] = PATIENT_ID; doc["device_id"] = DEVICE_ID; doc["battery_v"] = batteryVolts();
  JsonObject L = doc["left"].to<JsonObject>(), R = doc["right"].to<JsonObject>();
  for (int i = 0; i < 4; i++) { L[SITES[i]] = roundf(l[i] * 100) / 100; R[SITES[i]] = roundf(r[i] * 100) / 100; }
  doc["max_dt"] = roundf(maxDT * 100) / 100; doc["site"] = SITES[site];
  String body; serializeJson(doc, body);
  Serial.println(body);
  if (!SEND_HTTP || WiFi.status() != WL_CONNECTED) return;
  HTTPClient http; http.begin(API_URL); http.addHeader("Content-Type", "application/json");
  Serial.printf("POST -> %d\n", http.POST(body)); http.end();
}

void runScan(bool forced) {
  Serial.println(forced ? "Manual scan" : "Feet detected - scanning");
  float bufL[AVG_LAST][4], bufR[AVG_LAST][4]; int n = 0;
  uint32_t t0 = millis();
  while (millis() - t0 < SCAN_MS) {
    setLed(0, 0, (millis() / 250) % 2 ? 60 : 5);
    float l[4], r[4];
    if (readFoot(busL, ADDR_L, offsetL, l) && readFoot(busR, ADDR_R, offsetR, r)) {
      memcpy(bufL[n % AVG_LAST], l, sizeof l); memcpy(bufR[n % AVG_LAST], r, sizeof r); n++;
      if (!forced && !feetPresent(l, r) && millis() - t0 > 3000) { Serial.println("Feet removed"); setLed(60, 30, 0); beep(300); return; }
    }
  }
  int m = min(n, AVG_LAST);
  if (m < 2) { Serial.println("Too few samples"); setLed(60, 0, 0); return; }
  float aL[4] = {0}, aR[4] = {0};
  for (int k = 0; k < m; k++) for (int i = 0; i < 4; i++) { aL[i] += bufL[k][i] / m; aR[i] += bufR[k][i] / m; }
  float maxDT = 0; int site = 0;
  for (int i = 0; i < 4; i++) { float d = fabsf(aL[i] - aR[i]); if (d > maxDT) { maxDT = d; site = i; } }
  Serial.printf("max dT = %.2f C at %s\n", maxDT, SITES[site]);
  sendScan(aL, aR, maxDT, site);
  if (maxDT >= DT_ALERT_C) { setLed(70, 25, 0); beep(700); }          // orange: hotspot (backend decides red after 2 days)
  else { setLed(0, 60, 0); beep(80); delay(100); beep(80); }          // green: normal
}

volatile bool btnFlag = false;
void IRAM_ATTR onButton() { btnFlag = true; }

void setup() {
  Serial.begin(115200);
  pinMode(PIN_BTN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PIN_BTN), onButton, FALLING);
  analogSetPinAttenuation(PIN_VBAT, ADC_11db);
  led.begin(); setLed(20, 20, 20);
  mapBus(busL, ADDR_L, ID_L, "L"); mapBus(busR, ADDR_R, ID_R, "R");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  for (int i = 0; i < 20 && WiFi.status() != WL_CONNECTED; i++) delay(250);
  Serial.printf("WiFi %s | battery %.2f V\n", WiFi.status() == WL_CONNECTED ? "OK" : "off", batteryVolts());
  calibrate();
}

void loop() {
  if (btnFlag) {                                   // button press caught by interrupt (no missed clicks)
    btnFlag = false;
    uint32_t t0 = millis();
    while (digitalRead(PIN_BTN) == LOW && millis() - t0 < 3000) delay(10);
    if (millis() - t0 >= 3000) { calibrate(); while (digitalRead(PIN_BTN) == LOW) delay(10); }
    else runScan(true);
    btnFlag = false;
  }
  float l[4], r[4];
  if (readFoot(busL, ADDR_L, offsetL, l) && readFoot(busR, ADDR_R, offsetR, r) && feetPresent(l, r)) runScan(false);
  delay(50);
}
