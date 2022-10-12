#include <WaspSensorCities_PRO.h>
#include <WaspWIFI_PRO.h>

bmeCitiesSensor  bme(SOCKET_A);
luxesCitiesSensor  luxes(SOCKET_E);
Gas  gas_sensor(SOCKET_F);

float temperature;
float humidity;
float pressure;
uint32_t luminosity;
float concentration;

uint8_t socket = SOCKET0;
uint8_t error;
uint8_t status;
unsigned long previous;
char ESSID[] = "UiTiOt-E3.1";
char PASSW[] = "UiTiOtAP";

void setup()
{
  USB.ON();
  USB.println(F("Smart Cities Libelium"));
  noise.configure();

  USB.println(F("Start program"));  


  //////////////////////////////////////////////////
  // 1. Switch ON the WiFi module
  //////////////////////////////////////////////////
  error = WIFI_PRO.ON(socket);

  if (error == 0)
  {    
    USB.println(F("1. WiFi switched ON"));
  }
  else
  {
    USB.println(F("1. WiFi did not initialize correctly"));
  }


  //////////////////////////////////////////////////
  // 2. Reset to default values
  //////////////////////////////////////////////////
  error = WIFI_PRO.resetValues();

  if (error == 0)
  {    
    USB.println(F("2. WiFi reset to default"));
  }
  else
  {
    USB.println(F("2. WiFi reset to default ERROR"));
  }


  //////////////////////////////////////////////////
  // 3. Set ESSID
  //////////////////////////////////////////////////
  error = WIFI_PRO.setESSID(ESSID);

  if (error == 0)
  {    
    USB.println(F("3. WiFi set ESSID OK"));
  }
  else
  {
    USB.println(F("3. WiFi set ESSID ERROR"));
  }


  //////////////////////////////////////////////////
  // 4. Set password key (It takes a while to generate the key)
  // Authentication modes:
  //    OPEN: no security
  //    WEP64: WEP 64
  //    WEP128: WEP 128
  //    WPA: WPA-PSK with TKIP encryption
  //    WPA2: WPA2-PSK with TKIP or AES encryption
  //////////////////////////////////////////////////
  error = WIFI_PRO.setPassword(WPA2, PASSW);

  if (error == 0)
  {    
    USB.println(F("4. WiFi set AUTHKEY OK"));
  }
  else
  {
    USB.println(F("4. WiFi set AUTHKEY ERROR"));
  }


  //////////////////////////////////////////////////
  // 5. Software Reset 
  // Parameters take effect following either a 
  // hardware or software reset
  //////////////////////////////////////////////////
  error = WIFI_PRO.softReset();

  if (error == 0)
  {    
    USB.println(F("5. WiFi softReset OK"));
  }
  else
  {
    USB.println(F("5. WiFi softReset ERROR"));
  }


  USB.println(F("*******************************************"));
  USB.println(F("Once the module is configured with ESSID"));
  USB.println(F("and PASSWORD, the module will attempt to "));
  USB.println(F("join the specified Access Point on power up"));
  USB.println(F("*******************************************\n"));

  // get current time
  previous = millis();

}

void loop()
{
  //////////////////////////////////////////////////
  // 1. Connect to wifi
  //////////////////////////////////////////////////
  if (WIFI_PRO.isConnected() == true)
  {    
    USB.print(F("WiFi is connected OK"));
    USB.print(F(" Time(ms):"));    
    USB.println(millis()-previous); 

    USB.println(F("\n*** Program stops ***"));
    while(1)
    {}
  }
  else
  {
    USB.print(F("WiFi is connected ERROR")); 
    USB.print(F(" Time(ms):"));    
    USB.println(millis()-previous);  
  }
  
  status =  WIFI_PRO.isConnected();

  //////////////////////////////////////////////////
  // 2. Check if module is connected
  //////////////////////////////////////////////////
  if (status == true)
  { 
    USB.print(F("2. WiFi is connected OK."));
    USB.print(F(" Time(ms):"));    
    USB.println(millis()-previous);

    error = WIFI_PRO.ping("www.google.com");

    if (error == 0)
    {        
      USB.print(F("3. PING OK. Round Trip Time(ms)="));
      USB.println( WIFI_PRO._rtt, DEC );
    }
    else
    {
      USB.println(F("3. Error calling 'ping' function")); 
    }
  }
  else
  {
    USB.print(F("2. WiFi is connected ERROR.")); 
    USB.print(F(" Time(ms):"));    
    USB.println(millis()-previous);  
  }

  delay(10000);

  //////////////////////////////////////////////////
  // 3. Declare Sensor
  //////////////////////////////////////////////////
  int status = noise.getSPLA(SLOW_MODE);

  gas_sensor.OFF();
  bme.ON();
  luxes.ON();

  temperature = bme.getTemperature();
  humidity = bme.getHumidity();
  pressure = bme.getPressure();
  luminosity = luxes.getLuminosity();

  //////////////////////////////////////////////////
  // 4. Check status of noise sensor
  //////////////////////////////////////////////////
  if (status == 0) 
  {
    USB.print(F("Sound Pressure Level with A-Weighting (SLOW): "));
    USB.print(noise.SPLA);
    USB.println(F(" dBA"));
  }
  else
  {
    USB.println(F("[CITIES PRO] Communication error. No response from the audio sensor (SLOW)"));
  }

  delay(5);
  
  //////////////////////////////////////////////////
  // 5. Get sensor data
  //////////////////////////////////////////////////
  USB.print(F("Temperature: "));
  USB.printFloat(temperature, 2);
  USB.println(F(" Celsius degrees"));
  USB.print(F("RH: "));
  USB.printFloat(humidity, 2);
  USB.println(F(" %"));
  USB.print(F("Pressure: "));
  USB.printFloat(pressure, 2);
  USB.println(F(" Pa"));
  USB.print(F("Luminosity: "));
  USB.print(luminosity);
  USB.println(F(" luxes"));

  bme.OFF();
  luxes.OFF();
  gas_sensor.ON();

  //////////////////////////////////////////////////
  // 6. Waiting heating time and get O3 sensor data
  //////////////////////////////////////////////////
  USB.println(F("Enter deep sleep mode to wait for electrochemical heating time..."));
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  USB.ON();
  USB.println(F("wake up!!"));
  
  // Read the electrochemical sensor and compensate with the temperature internally
  concentration = gas_sensor.getConc(temperature);
  USB.print(F("O3: "));
  USB.printFloat(concentration,2);
}