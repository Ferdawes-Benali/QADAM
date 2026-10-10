/*
  Qadam - demo 2 capteurs (Arduino UNO + 2 x DHT22/DHT11)
  Bibliotheque : "DHT sensor library" (Adafruit) + "Adafruit Unified Sensor"
  Branchement :
    DHT gauche : VCC -> 5V, DATA -> D2, GND -> GND  (+ 10k entre DATA et 5V si capteur nu a 4 pattes)
    DHT droit  : VCC -> 5V, DATA -> D3, GND -> GND  (+ 10k idem)
    LED verte  : D5 -> 220R -> LED -> GND
    LED rouge  : D6 -> 220R -> LED -> GND
    Buzzer actif 5 V : D8 -> buzzer + ; buzzer - -> GND
  Sortie : une ligne JSON toutes les 2 s sur l'USB (115200 bauds), lue par mqtt_bridge.py
*/
#include <DHT.h>

#define DHTTYPE DHT22          // mettre DHT11 si ce sont des DHT11 (bleus)
const byte PIN_L = 2, PIN_R = 3, LED_OK = 5, LED_ALERT = 6, BUZ = 8;
const float SEUIL = 2.2;       // difference gauche/droite en degres C
const byte PERSISTANCE = 5;    // 5 lectures de suite (~10 s) au-dessus du seuil = alerte

DHT dhtL(PIN_L, DHTTYPE), dhtR(PIN_R, DHTTYPE);
float offset = 0;              // correction mesuree au demarrage (capteurs a l'air libre)
byte compteur = 0;

void setup() {
  Serial.begin(115200);
  pinMode(LED_OK, OUTPUT); pinMode(LED_ALERT, OUTPUT); pinMode(BUZ, OUTPUT);
  dhtL.begin(); dhtR.begin();
  delay(2500);
  // calibration : personne sur le tapis, 5 lectures
  float s = 0; byte n = 0;
  for (byte i = 0; i < 5; i++) {
    float l = dhtL.readTemperature(), r = dhtR.readTemperature();
    if (!isnan(l) && !isnan(r)) { s += l - r; n++; }
    delay(2100);
  }
  if (n) offset = s / n;
  Serial.print(F("# calibration offset G-D = ")); Serial.println(offset, 2);
  digitalWrite(BUZ, HIGH); delay(80); digitalWrite(BUZ, LOW);
}

void loop() {
  float l = dhtL.readTemperature();
  float r = dhtR.readTemperature() + offset;    // aligne le capteur droit sur le gauche
  if (isnan(l) || isnan(r)) { Serial.println(F("# erreur lecture DHT")); delay(2000); return; }
  float dt = fabs(l - r);
  compteur = (dt >= SEUIL) ? min(compteur + 1, 250) : 0;
  bool alerte = compteur >= PERSISTANCE;
  digitalWrite(LED_OK, !alerte);
  digitalWrite(LED_ALERT, alerte);
  if (compteur == PERSISTANCE) { digitalWrite(BUZ, HIGH); delay(300); digitalWrite(BUZ, LOW); }  // un seul bip
  Serial.print(F("{\"left\":")); Serial.print(l, 2);
  Serial.print(F(",\"right\":")); Serial.print(r, 2);
  Serial.print(F(",\"dt\":")); Serial.print(dt, 2);
  Serial.print(F(",\"alert\":")); Serial.print(alerte ? F("true") : F("false"));
  Serial.println('}');
  delay(2000);                                   // le DHT22 ne lit pas plus vite que toutes les 2 s
}
