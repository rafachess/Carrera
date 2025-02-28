

//const int bahn1 = 7;
const int bahn2 = 7;
const int sensors[5] = {2,3,4,5,6};
volatile byte LS_Werte[5] = {0,0,0,0,0};
volatile byte Abschnitt_speed[5] = {0,0,0,0,0};
bool autoAn = true;
bool kurve = false;
unsigned long t1 = 0;
unsigned long t2 = 0;
float s = 2.28;
float v = 0;
int sollGeschwindigkeit = 7.9;
int speed = 0;
int speed_automatic = 0;
bool start =false;
String receivedData = "";

//#define DEBUG 

void speedwerte_von_processing(String input) {
  Serial.println( input.c_str() );
  if (input.startsWith("speeds :")) {
    input = input.substring(8); // Entferne "speeds :" aus dem String
    input.trim();               // Entferne führende und nachgestellte Leerzeichen
    
    // Teile den String anhand der Leerzeichen in Werte auf
    int index = 0;
    while (input.length() > 0 && index < 5) {
      int splitIndex = input.indexOf(' '); // Finde die nächste Leerstelle
      String value;
      if (splitIndex == -1) { // Kein Leerzeichen mehr, letzter Wert
        value = input;
        input = "";
      } else {
        value = input.substring(0, splitIndex); // Extrahiere den nächsten Wert
        input = input.substring(splitIndex + 1); // Reststring weiterverarbeiten
      }
      value.trim(); // Entferne Leerzeichen von extrahiertem Wert
      int intValue = value.toInt(); // Konvertiere zu Integer
      if (intValue >= 0 && intValue <= 255) { // Gültigen Bereich prüfen
        Abschnitt_speed[index] = (byte)intValue; // Im Array speichern
        Serial.print(Abschnitt_speed[index]);
        Serial.print(" ");
        
        index++;
      }
    }
    Serial.println();


  }


  else if (input.startsWith("stop")) {
    
    speed_automatic = 0;
    analogWrite(bahn2, speed_automatic);
    
    Serial.println();


  }

  else if (input.startsWith("start")) {
    
    speed_automatic = 120;
    analogWrite(bahn2, speed_automatic);
    
    Serial.println();


  }


  // Debug-Ausgabe
  Serial.print("Abschnitt_speed: ");
  for (int i = 0; i < 5; i++) {
    Serial.print(Abschnitt_speed[i]);

    if (i < 4) Serial.print(", ");
  }
  Serial.println();
}

void lichtschranke() {
  if (t1 == 0) {
    t1 = millis();
  }

  else if (millis()-t1 > 500)
  {
    t2 = millis();
    v = s/(t2-t1);

    v *= 1000;

   /* Serial.print("t1:");
    Serial.print(t1);
    Serial.print(", t2:");
    Serial.print(t2);*/
    Serial.print(" v:");
    Serial.print(v*3.6);
    Serial.println("km/h");
    t1 = t2;
    t2 = 0;
  }
  
  
  // Update the last event time every time the light barrier closes
  //lastEventTime = millis();
}

ISR(TIMER1_COMPA_vect) {
  digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN)); 
  for (int i = 0; i < 5; i++) {
    LS_Werte[i] = digitalRead(i+2);
  #ifdef DEBUG
    Serial.print(LS_Werte[i]);
    Serial.print( "\t");
  #endif
    if (LS_Werte[i] == 1)
    {
      speed_automatic = Abschnitt_speed[i];
      analogWrite(bahn2, speed_automatic);
    }

  }
  #ifdef DEBUG
    Serial.println( "");
  #endif
}


// Geschwindigkeitseinstellungen
int speedFast = 255; // Schnelle Geschwindigkeit (0-255)
int speedMedium = 150; // Mittlere Geschwindigkeit (0-255)
int speedSlow = 120; // Langsame Geschwindigkeit (0-255)

void setup() 
{
  //analogWrite(bahn1, 0);
  analogWrite(bahn2, 0);
  pinMode(LED_BUILTIN, OUTPUT); 
  Serial.begin(9600);
  Serial2.begin(2400);
  // Setze die Pins als Ausgang
  //pinMode(bahn1, OUTPUT);
  pinMode(bahn2, OUTPUT);
  for (int s=2; s<6; s++)
  {
    pinMode(s, INPUT_PULLUP);
  }
  //attachInterrupt(digitalPinToInterrupt(sensor), lichtschranke, FALLING);

  // Configure Timer1 for 10ms interval
noInterrupts();           // disable all interrupts
  TCCR1A = 0;
  TCCR1B = 0;
  TCNT1  = 0;

  OCR1A = 16000;            // compare match register 16MHz/1000
  TCCR1B |= (1 << WGM12);   // CTC mode
  TCCR1B |= (1 << CS10);    // No prescaler 
  TIMSK1 |= (1 << OCIE1A);  // enable timer compare interrupt
  interrupts();             // Enable interrupts


  Serial.print("ready");
}

int sp = 0;
void loop() { 
  while (Serial2.available() > 0) {
    // Zeichen aus Serial2 lesen
    char receivedChar = Serial2.read();
    // Zeichen anhängen, solange kein Zeilenumbruch kommt
    if (receivedChar == '\n') {
      // Gesamte Nachricht verarbeiten
      speedwerte_von_processing(receivedData);
      receivedData = "";      // Buffer leeren
    } else {
      receivedData += receivedChar; // Zeichen an den String anhängen
    }
  }
  //int speedIn = analogRead(A0);

   Serial2.println(speed_automatic);
  
  
  //Serial.println(" 0 2");
    
 /* if (speedIn > 100)
  { 
    speed = map( speedIn, 0, 1024, 0, 255);
    float f = kurve ? 1.3 : 1;
    sp = speed*f > 255? 255:speed*f;
    
    //Serial.print(t1);
    //Serial.print(" ");
    //Serial.println(t2);
    //Serial.print(v*3.6);
    //Serial.println("km/h");

    //Sende zu Prozessing
    Serial2.print(v*3.6);
    Serial2.println("km/h");

    Serial.print("hand ");
    Serial.print(speedIn);
    Serial.print(" ");
    Serial.println(speed);

   // analogWrite(bahn2, 255 );
  }slider
  else*/
  {
    /*for (int s=0; s<5; s++)
    {
      if (LS_Werte[s] == 1)
      {
        speed_automatic = Abschnitt_speed[s];
        break;
      }   
    }
    analogWrite(bahn2, speed_automatic);
    */
    //Serial.print("auto ");
    //Serial.print(speedIn);
    //Serial.print(" ");
    Serial.println(speed_automatic);

  }
  

  /*if (v*3.6 < sollGeschwindigkeit*0.95)
  {
    sp = sp + 1;
  }

  else if (v*3.6>sollGeschwindigkeit*1.05)
  {
    sp = sp - 1;
  }*/
}
/*void processReceivedData(String data) {
  // Daten (CSV-Format) verarbeiten
  int firstComma = data.indexOf(',');
  if ( data.substring(0, firstComma) == "1")
  {
    speed = 75;
  }

  int lastIndex = firstComma;
  for (int i = 0; i < 4; i++) {
    int nextComma = data.indexOf(',', lastIndex + 1);
    if (nextComma == -1) nextComma = data.length();
    Abschnitt_speed[i] = data.substring(lastIndex + 1, nextComma).toInt();
    lastIndex = nextComma;
  }
}*/

