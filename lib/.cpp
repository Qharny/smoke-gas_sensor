#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>

const char* ssid = "Huawei Y9";
const char* password = "qwertyuiop1234";
const char* serverAddress = "http://11.11.136.160:5000/update";

void setup() {
    // ... (previous setup code)
    WiFi.begin(ssid, password);
}

void loop() {
    // ... (previous loop code)

    // Send data to server
    if(WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(serverAddress);
        http.addHeader("Content-Type", "application/json");
        String httpRequestData = "{\"sensor_value\":" + String(n) + "}";
        int httpResponseCode = http.POST(httpRequestData);
        http.end();
    }
}