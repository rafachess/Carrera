import processing.serial.*; //<>//
import controlP5.*;

// Serielle Schnittstelle
Serial myPort;
String portName;

// Steuerungsvariablen
float speed = 200;
float maxSpeed = 255;
boolean connected = false;

// ControlP5 GUI-Elemente
ControlP5 cp5;
DropdownList portList;
Button connectButton, sendButton, stopButton, startButton;
Slider slider1, slider2, slider3, slider4, slider5;

void setup() {
  size(1000, 500); // Breiterer Sketch für Tachometer und GUI
  background(255);

  // Initialisiere die GUI
  cp5 = new ControlP5(this);

  // Verbindungssteuerung links vom Tachometer
  Group connectionGroup = cp5.addGroup("connectionGroup")
                              .setLabel("Verbindungssteuerung")
                              .setPosition(20, 20)
                              .setSize(200, 200)
                              .setBackgroundColor(color(240))
                              .setBackgroundHeight(200);

  // Dropdown-Liste für Ports
  portList = cp5.addDropdownList("ports")
                .setPosition(10, 20)
                .setSize(180, 100)
                .setLabel("Wähle Port")
                .moveTo(connectionGroup);

  // Ports in Dropdown einfügen
  String[] ports = Serial.list();
  for (int i = 0; i < ports.length; i++) {
    portList.addItem(ports[i], i);
  }

  // Knopf für Verbindung
  connectButton = cp5.addButton("connect")
                     .setLabel("Verbinden")
                     .setPosition(10, 130)
                     .setSize(180, 30)
                     .moveTo(connectionGroup);

  // Schieberegler und Knopf rechts vom Tachometer
  Group sliderGroup = cp5.addGroup("sliderGroup")
                          .setLabel("Schieberegler-Werte")
                          .setPosition(670, 20)
                          .setSize(300, 400)
                          .setBackgroundColor(color(0,120,0))
                          .setBackgroundHeight(400);


  slider1 = cp5.addSlider("V1")
               .setLabel("Loop")  // Label setzen
               .setPosition(10, 20)
               .setSize(200, 20)
               .setRange(0, 255)
               .moveTo(sliderGroup);
  
  slider2 = cp5.addSlider("V2")
               .setLabel("Kurve Ende")  // Label setzen
               .setPosition(10, 60)
               .setSize(200, 20)
               .setRange(0, 255)
               .moveTo(sliderGroup);
  
  slider3 = cp5.addSlider("V3")
               .setLabel("Rampe")  // Label setzen
               .setPosition(10, 100)
               .setSize(200, 20)
               .setRange(0, 255)
               .moveTo(sliderGroup);
  
  slider4 = cp5.addSlider("V4")
               .setLabel("Looping Ende")  // Label setzen
               .setPosition(10, 140)
               .setSize(200, 20)
               .setRange(0, 255)
               .moveTo(sliderGroup);
               
  slider5 = cp5.addSlider("V5")
               .setLabel("Kurve Anfang")  // Label setzen
               .setPosition(10, 180)
               .setSize(200, 20)
               .setRange(0, 255)
               .moveTo(sliderGroup);

  sendButton = cp5.addButton("sendData")
                  .setLabel("Senden")
                  .setPosition(10, 230)
                  .setSize(200, 30)
                  .moveTo(sliderGroup);
  
  stopButton = cp5.addButton("stop")
                  .setLabel("Stop")
                  .setPosition(10, 280)
                  .setSize(200, 30)
                  .moveTo(sliderGroup);
  
   startButton = cp5.addButton("start")
                  .setLabel("Start")
                  .setPosition(10, 330)
                  .setSize(200, 30)
                  .moveTo(sliderGroup);
  
}

void draw() {
  background(255);

  // Tachometer zeichnen
  fill(200);
  ellipse(500, 200, 300, 300); // Tachometer-Kreis

  fill(0);
  textSize(24);
  textAlign(CENTER);
  text(nf(speed, 1, 2) + " km/h", 500, 300); // Geschwindigkeit anzeigen

  // Zeiger zeichnen
  float angle = speed; //map(speed, 0, maxSpeed, -PI, 0);
  stroke(255, 0, 0);
  strokeWeight(4);
  line(500, 200, 500 + cos(angle) * 100, 200 + sin(angle) * 100);

  // Skala auf den Tachometer-Kreis zeichnen
  stroke(0);
  strokeWeight(1);
  textSize(14);
  for (int i = 0; i <= 255; i+=10) { // 255 Teilstriche für die Skala
    float a = map(i, 0, 255, -PI, 0); // Winkel für jeden Teilstrich
    float x1 = 500 + cos(a) * 130;  // Äußerer Punkt des Teilstrichs
    float y1 = 200 + sin(a) * 130;
    float x2 = 500 + cos(a) * 110;  // Innerer Punkt des Teilstrichs
    float y2 = 200 + sin(a) * 110;
    line(x1, y1, x2, y2); // Teilstrich zeichnen

    // Zahlen auf der Skala zeichnen
    float tx = 500 + cos(a) * 150;
    float ty = 200 + sin(a) * 150;
    textAlign(CENTER, CENTER);
    text(i , tx, ty); // Werte in 2er-Schritten anzeigen
  }

  // Verbindungsstatus anzeigen
  fill(0);
  textSize(16);
  textAlign(LEFT);
  if (connected) {
    text("Verbunden mit: " + portName, 20, height - 20);
  } else {
    text("Nicht verbunden", 20, height - 20);
  }
}

// Verbindung herstellen
public void connect() {
  int selectedIndex = (int) portList.getValue();
  String[] ports = Serial.list();

  if (selectedIndex >= 0 && selectedIndex < ports.length) { //<>//
    try {
      portName = ports[selectedIndex];
      myPort = new Serial(this, portName, 2400);
      myPort.bufferUntil('\n');
      connected = true;
      println("Verbunden mit: " + portName);
    } catch (Exception e) {
      println("Fehler beim Verbinden: " + e.getMessage());
      connected = false;
    }
  } else {
    println("Ungültige Port-Auswahl");
  }
}

// Daten senden
public void sendData() {
  if (connected) { //<>//
    int v1 = (int) slider1.getValue();
    int v2 = (int) slider2.getValue();
    int v3 = (int) slider3.getValue();
    int v4 = (int) slider4.getValue();
    int v5 = (int) slider5.getValue();

    String protocol = "speeds :" + v1 + " " + v2 + " " + v3 + " " + v4 + " " +v5;
    myPort.write(protocol + "\n");
    println("Gesendet: " + protocol);
  } else {
    println("Keine Verbindung zur seriellen Schnittstelle.");
  }
}

public void stop() {
  if (connected) {
    
    String protocol = "stop" ;
    myPort.write(protocol + "\n");
    println("Gesendet: " + protocol);
  } else {
    println("Keine Verbindung zur seriellen Schnittstelle.");
  }
}

public void start() {
  if (connected) {
    
    String protocol = "start" ;
    myPort.write(protocol + "\n");
    println("Gesendet: " + protocol);
  } else {
    println("Keine Verbindung zur seriellen Schnittstelle.");
  }
}

// Serielle Daten empfangen
void serialEvent(Serial myPort) {
  String data = myPort.readStringUntil('\n');
  if (data != null) {
    data = trim(data);
    try {
      speed = float(data); // Empfange Geschwindigkeit (falls korrekt)
    } catch (Exception e) {
      println("Fehler beim Parsen der Geschwindigkeit: " + e.getMessage());
    }
  }
}
