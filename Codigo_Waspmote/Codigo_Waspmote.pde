
#include <WaspSensorEvent_v30.h>

uint8_t value = 0;

pirSensorClass pir(SOCKET_1);

float temp;
float luxes;
uint32_t digitalLuxes;
char HTTP_SERVER[] = "test.mosquitto.org";
uint16_t HTTP_PORT = 1883;
uint8_t error;
uint8_t status;
unsigned long previous;

void setup() 
{
  // Turn on the USB and print a start message
  USB.ON();
  USB.println(F("Start program"));
  
  // Turn on the sensor board
  Events.ON();
    
  // Firstly, wait for PIR signal stabilization
  value = pir.readPirSensor();
  while (value == 1)
  {
    USB.println(F("...wait for PIR stabilization"));
    delay(1000);
    value = pir.readPirSensor();    
  }
  
  // Enable interruptions from the board
  Events.attachInt();

  error = WIFI_PRO_V3.ON(socket);

  if(error == 0){
    USB.println(F("1. WiFi switched ON"));
  }
  else{
    USB.prinln(F("1. WiFi did not initialize correctly"));
  }

  previous = millis();

  status = WIFI_PRO_V3.isConnected();

  if(status == true){
    USB.println(F("2.WiFi is connected OK"));

    USB.print(F("IP address: "));
    USB.println(WIFI_PRO_V3._ip);

    USB.print(F("GW address: "));
    USB.println(WIFI_PRO_V3._gw);

    USB.print(F("Netmask address: "));
    USB.println(WIFI_PRO_V3._netmask);

    USB.print(F("Time(ms): "));
    USB.println(millis() - previous);
  }
  else{
    USB.print(F("2. Wifi is connected ERROR"));
    USB.print(F("Time (ms): "));
    USB.println(millis() - previous);
    PWR.reboot();
  }

  error = WIFI_PRO_V3.mqttConfiguration(HTTP_SERVER, "user", HTTP_PORT, WaspWIFI_v3::MQTT_TLS_DISABLED);
  if(error == 0){
    USB.println(F("3. MQTT connection configured"));
  }
  else{
    USB.print(F("3. MQTT connection configured ERROR"));
  }
}

void loop() 
{
  ///////////////////////////////////////
  // 1. Read the sensor level
  ///////////////////////////////////////
  // Read the PIR Sensor
  value = pir.readPirSensor();
  
  // Print the info
  if (value == 1) 
  {
    USB.println(F("Sensor output: Presence detected"));
  } 
  else 
  {
    USB.println(F("Sensor output: Presence not detected"));
  }
  
  ///////////////////////////////////////
  // 2. Go to deep sleep mode
  ///////////////////////////////////////
  USB.println(F("enter deep sleep"));
  PWR.deepSleep("00:00:00:10", RTC_OFFSET, RTC_ALM1_MODE1, SENSOR_ON);
  USB.ON();
  USB.println(F("wake up\n"));
  
  
  ///////////////////////////////////////
  // 3. Check Interruption Flags
  ///////////////////////////////////////
    
  // 3.1. Check interruption from RTC alarm
  if (intFlag & RTC_INT)
  {
    USB.println(F("-----------------------------"));
    USB.println(F("RTC INT captured"));
    USB.println(F("-----------------------------"));

    // clear flag
    intFlag &= ~(RTC_INT);
  }
  
  // 3.2. Check interruption from Sensor Board
  if (intFlag & SENS_INT)
  {
    // Disable interruptions from the board
    Events.detachInt();
    
    // Load the interruption flag
    Events.loadInt();
    
    // In case the interruption came from PIR
    if (pir.getInt())
    {
      USB.println(F("-----------------------------"));
      USB.println(F("Interruption from PIR"));
      USB.println(F("-----------------------------"));
    }    
    
    // User should implement some warning
    // In this example, now wait for signal
    // stabilization to generate a new interruption
    // Read the sensor level
    value = pir.readPirSensor();
    temp = Events.getTemperature();
    digitalLuxes = Events.getLuxes(INDOOR);

    if(temp>=22){
      USB.println(F("Encender el aire acondicionado"));
    }

    USB.println(digitalLuxes);

    if(digitalLuxes<4000000000){
      USB.println(F("Encender las luces"));
    }
    
    while (value == 1)
    {
      USB.println(F("...wait for PIR stabilization"));
      delay(1000);
      value = pir.readPirSensor();
    }
    
    // Clean the interruption flag
    intFlag &= ~(SENS_INT);
    
    // Enable interruptions from the board
    Events.attachInt();
  }

  error = WIFI_PRO_V3.ON(socket);

  if(error == 0){
    USB.println(F("1. WiFi switched ON"));
  }
  else{
    USB.prinln(F("1. WiFi did not initialize correctly"));
  }

  error = WIFI_PRO_V3.mqttPublishTopic("myTopic", WaspWIFI_v3::QOS_1, WaspWIFI_v3::RETAINED, "Temp:17");

  if(error == 0){
    USB.println(F("Publish topi done!"));
  }
  else{
    USB.println(F("Error publisching topic!"));
  }

  WIFI_PRO_V3.OFF(socket);

  delay(10000);
}

