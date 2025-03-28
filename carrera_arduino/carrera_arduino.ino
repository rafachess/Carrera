// Rafael Heinitz, Lukas Herb
// Jugen  Forscht 2025
// Carrera-Projekt
// Version 1.0


bool TestPrintSensoren=0;                                 // Zum Steuern von Testausgabe der Sensor-Werte
bool TestPrintAktSpeed=1;                                  // Zum Steuern von Testausgabe der Akt Geschw. Werte
bool TestPrint=0;                                          // Zum Steuern von Testausgabe der Werte

const int BahnPin = 45;                                        // Arduino-Pin für PWM
int StartSpeed = 120;                                         // Konstante für Anfangsgeschwindigkeit
volatile int FahrtWatchDog = 0;                               // Watch-Dog Zähler. Zum Stoppen, wenn keine LS nach 2s ausgelöst
volatile bool StopWunsch = false;                             // Stop-Knopf in Prozessing signalisiert nur den Stop-Wunsch
volatile bool Gestoppt = false;                               // StopWunsch abgearbeitet. Wenn aus Trägheit weitere LS überquerrt wird, ignorieren

                                                              // Stoppen im Looping oder Steilkurve ist jedoch gefährlich
const int StopLS= 3;                                          // Lichtschranke, nach der gestoppt wird (bei Stop-Wunsch)

const int Sensoren[] = {31,39,33,37,35};                           // Arduino Pins, wo die Sensoren angeschlossen sind

volatile byte LS_Werte[] = {0,0,0,0,0};                       // Werte der Sensoren (an/aus)
volatile byte Abschnitt_speed[] = {0,0,0,0,0};                // Geschwindigkeit, die nach den jeweiligen Sensor gesetzt wird

const int SensorenAnz = sizeof( Sensoren ) / sizeof(Sensoren[0]); // Automatische Berechnung der Anzahl der Sensoren

volatile int AktSpeed = 0;                                    // Aktuelle Geschwindigkeit

void speedwerte_von_processing(String input);                 // Funktion zum Auswerten der Processing-Nachrichten


void setup()                                                  // Arduino Setup-Funktion. Wird ein Mal beim Reset ausgeführt
{
  analogWrite(BahnPin, 0);                                    // Auto stoppen
  pinMode(LED_BUILTIN, OUTPUT);                               // Das eingebaute LED als Ausgang konfigurieren (zum Testen von Timer-Interrupt)
  Serial.begin(9600);                                          
  Serial2.begin(9600);
  pinMode(BahnPin, OUTPUT);                                   // Bahn-Pin als Ausgang konfigurieren
  for (auto s : Sensoren)                                      // Alle Sensoren als Eingänge konfigurieren
  {
    pinMode(s, INPUT_PULLUP);                                 
  }
  
                                                              // Timer-Interrupt mit 1ms Periode konfigurieren
  noInterrupts();                                             // Weiterhin folgt eine Magie, die micht mal ChatGPT
  TCCR1A = 0;                                                 // beherrscht. 
  TCCR1B = 0;                                                 // ChatGPT hat die Periode immer zu hoch eingestellt. 
  TCNT1  = 0;                                                 // Erst durch Blinken der eingebauten LED im Timer-Interrupt  

  OCR1A = 16000;                                              // habe ich festgestellt, dass die PEriode nicht 1ms war
  TCCR1B |= (1 << WGM12);                                     // Durch die Recherche in den Foren bin ich auf diese
  TCCR1B |= (1 << CS10);                                      // Einstellungen gekommen.
  TIMSK1 |= (1 << OCIE1A);    
  interrupts();                                               // Timer-Interrupt Einstellung für 1ms fertig

  Serial.print("Setup Ende");
}


void loop() {                                                 // Arduino Endlosschleife
  while (Serial2.available() > 0) {                           // Falls Daten von Prozessing ...
    static String NachrichtVonProcessing = "";                // Eine Textvariable zum Speichern der Nachricht   
        
    char receivedChar = Serial2.read();                       // Zeichen aus Serial2 lesen
    if (receivedChar == '\n') {                               // Wenn Return...      
      speedwerte_von_processing(NachrichtVonProcessing);      // ...dann ist Nachricht komplett -> bearbeiten, interpretieren
      NachrichtVonProcessing = "";                            // alte Nachricht löschen
    } else {                                                  // Noch kein Return-Zeichen?  
      NachrichtVonProcessing += receivedChar;                 // Zeichen zu der Nachricht-Variable hinzufügen
    }
  }

  Serial2.println(AktSpeed);                                  // Sende aktuelle Geschwindigkeit an Processing
  if ( TestPrintAktSpeed ) { Serial.println(AktSpeed); }               
}


void speedwerte_von_processing(String input) {                //Funktion interpretiert die NAchrichten von Processing
  if ( TestPrint )
  {
    Serial.print( "Processing: " );
    Serial.println( input.c_str() );
  }
  if (input.startsWith("speeds :")) {
    input = input.substring(8); // Entferne "speeds :" aus dem String
    input.trim();               // Entferne führende und nachgestellte Leerzeichen
    
    // Teile den String anhand der Leerzeichen in Werte auf
    int index = 0;
    while (input.length() > 0 && index < SensorenAnz) {
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
        index++;
      };  
    }    
  }
  else if (input.startsWith("stop")) {    
    StopWunsch = true;    
  }
  else if (input.startsWith("start")) {    
    StopWunsch = false;
    Gestoppt = false;
    FahrtWatchDog = 0;
    AktSpeed = StartSpeed;
    analogWrite(BahnPin, AktSpeed);    
  }


  if ( TestPrint )
  {
    Serial.print("Abschnitt_speed: ");
    for (int i = 0; i < SensorenAnz; i++) {
      Serial.print(Abschnitt_speed[i]);
      Serial.print(", StopWunsch:");
      Serial.print(StopWunsch);
      Serial.print(", Stop:");
      Serial.print(Gestoppt);
    }
    Serial.println();
  }
}


// Timer-Interrupt. 
// Diese Funktion wird vom Arduino 
// automatisch jede Millisekunde aufgerufen
ISR(TIMER1_COMPA_vect) {                                         
  digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));      // Mit eingebauten LED jedes Mal blinken
  FahrtWatchDog++;                                           // Watch-Dog Zähler erhöhen

  if ( FahrtWatchDog >=2000 )                                // Nach 2 Sekunden Bahn ausschalten, walls Watch-Dog Zähler nicht resettet ist
  {
    AktSpeed = 0;
  }


  for (int i = 0; i < SensorenAnz; i++) {                    // Prüfe alle Sensoren
    LS_Werte[i] = digitalRead(Sensoren[i]);
  
    if ( TestPrintSensoren )
    {
      Serial.print(LS_Werte[i]);
      Serial.print( "\t");
    }
  
    if (LS_Werte[i] == 1)                                     // Wenn Lichtschranke AN
    {
      FahrtWatchDog = 0;                                      // Watch-Dog Zähler reset
      if ( StopWunsch && (i==StopLS) ){             // Wenn Stop-Wunsch und entsprechende Lichtschranke   ...
        AktSpeed = 0; 
        Gestoppt = true;                                        //  -> Stop     
      }
      else
      {
        if (!Gestoppt)                      //wenn nach stoppwunsch nicht gestoppt
        {
          AktSpeed = Abschnitt_speed[i];    // übernehe die Abschnittsgeschwindigkeit
        }                        
      }
    }
    analogWrite(BahnPin, AktSpeed);                           // Setze PWM
  }
  
  if ( TestPrintSensoren ) { Serial.println( "");  }

}
