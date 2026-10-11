#pragma once
#define DHT22 22
#define DHT11 11
float scripted_temp(int pin, unsigned long now);
class DHT {
 public:
  DHT(int pin, int) : pin_(pin) {}
  void begin() {}
  float readTemperature() { return scripted_temp(pin_, millis()); }
  float readHumidity() { return std::isnan(scripted_temp(pin_, millis())) ? NAN : 45.0f; }
 private:
  int pin_;
};
