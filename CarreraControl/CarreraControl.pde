import processing.serial.*;  //<>//
import controlP5.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

import ddf.minim.*;
import ddf.minim.signals.*;

Minim minim;
AudioOutput out;
SineWave sine;
AudioPlayer player;

String AktAuto ="auto1.txt"; 

// Serielle Schnittstelle
Serial myPort;
String portName="--";

// Steuerungsvariablen
float speed = 0;
float maxSpeed = 255;
boolean connected = false;

// ControlP5 GUI-Elemente
ControlP5 cp5;
DropdownList portList;
Button actButton, connectButton, sendButton, stopButton, startButton, Auto1, Auto2, Auto3, Auto4;
Slider slider1, slider2, slider3, slider4, slider5;

void setup() {
  size(1000, 800); // Breiterer Sketch für Tachometer und GUI
  background(255);
  minim = new Minim(this);
  out = minim.getLineOut();

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
                .setPosition(10, 50)
                .setSize(180, 100)
                .setLabel("Wähle Port")
                .moveTo(connectionGroup);

  actPorts();

  actButton = cp5.addButton("actPorts")
                     .setLabel("Aktualisieren")
                     .setPosition(10, 20)
                     .setSize(180, 20)
                     .moveTo(connectionGroup);
                     
  connectButton = cp5.addButton("connect")
                     .setLabel("Verbinden")
                     .setPosition(10, 130)
                     .setSize(180, 30)
                     .moveTo(connectionGroup);

  // Schieberegler und Knopf rechts vom Tachometer
  Group sliderGroup = cp5.addGroup("sliderGroup")
                          .setLabel("Abschnittsgeschwindigkeiten")
                          .setPosition(670, 20)
                          .setSize(300, 600)
                          .setBackgroundColor(color(0,120,0))
                          .setBackgroundHeight(600);

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
               .setLabel("Steilkurve")  // Label setzen
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

  //slider1 = createSlider("V1", "Loop", 10, 20, sliderGroup);
  //slider2 = createSlider("V2", "Kurve Ende", 10, 60, sliderGroup);
  //slider3 = createSlider("V3", "Steilkurve", 10, 100, sliderGroup);
  //slider4 = createSlider("V4", "Looping Ende", 10, 140, sliderGroup);
  //slider5 = createSlider("V5", "Kurve Anfang", 10, 180, sliderGroup);

  sendButton = cp5.addButton("sendData")
                  .setLabel("Senden")
                  .setPosition(10, 230)
                  .setSize(200, 30)
                  .moveTo(sliderGroup);
  
  stopButton = cp5.addButton("stopAuto")
                  .setLabel("Stop")
                  .setPosition(10, 280)
                  .setSize(200, 30)
                  .moveTo(sliderGroup);
  
  startButton = cp5.addButton("startAuto")
                  .setLabel("Start")
                  .setPosition(10, 330)
                  .setSize(200, 30)
                  .moveTo(sliderGroup);
                  
    Auto1 = cp5.addButton("auto1")
                  .setLabel("Auto5")
                  .setPosition(10, 400)
                  .setSize(100, 30)
                  .moveTo(sliderGroup);
                  
    Auto2 = cp5.addButton("auto2")
                  .setLabel("Auto44")
                  .setPosition(120, 400)
                  .setSize(100, 30)
                  .moveTo(sliderGroup);
     Auto3 = cp5.addButton("auto3")
                  .setLabel("SR")
                  .setPosition(10, 440)
                  .setSize(100, 30)
                  .moveTo(sliderGroup);
      Auto4 = cp5.addButton("auto4")
                  .setLabel("Camera")
                  .setPosition(120, 440)
                  .setSize(100, 30)
                  .moveTo(sliderGroup);
                  
  loadSliderValues(AktAuto);
  
}

void auto1(){ 
  loadSliderValues("auto1.txt"); 
}

void auto2(){ 
  loadSliderValues("auto2.txt"); 
}
  
void auto3(){ 
  loadSliderValues("auto3.txt"); 
}

void auto4(){ 
  loadSliderValues("auto4.txt"); 
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
  float angle = map(speed, 0, maxSpeed, -PI, 0);
  stroke(255, 0, 0);
  strokeWeight(4);
  line(500, 200, 500 + cos(angle) * 100, 200 + sin(angle) * 100);

  // Skala auf den Tachometer-Kreis zeichnen
  stroke(0);
  strokeWeight(1);
  textSize(14);
  for (int i = 0; i <= 255; i+=20) { // 255 Teilstriche für die Skala
    float a = map(i, 0, 255, -PI, 0); // Winkel für jeden Teilstrich
    float x1 = 500 + cos(a) * 110;  // Äußerer Punkt des Teilstrichs
    float y1 = 200 + sin(a) * 110;
    float x2 = 500 + cos(a) * 100;  // Innerer Punkt des Teilstrichs
    float y2 = 200 + sin(a) * 100;
    line(x1, y1, x2, y2); // Teilstrich zeichnen

    // Zahlen auf der Skala zeichnen
    float tx = 500 + cos(a) * 130;
    float ty = 200 + sin(a) * 130;
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

// Verbindung herstellen oder trennen
public void connect() {
  if (connected) {
    // Disconnect if already connected
    if (myPort != null) {
      myPort.stop();
      myPort = null;
    }
    connected = false;
    connectButton.setLabel("Verbinden");  // Button zurück auf "Verbinden" setzen
    println("Verbindung getrennt.");
  } else {
    int selectedIndex = (int) portList.getValue();
    String[] ports = Serial.list();

    if (selectedIndex >= 0 && selectedIndex < ports.length) {
      try {
        portName = ports[selectedIndex];
        myPort = new Serial(this, portName, 9600);
        myPort.bufferUntil('\n');
        connected = true;
        connectButton.setLabel("Trennen");  // Button zu "Trennen" ändern
        println("Verbunden mit: " + portName);
      } catch (Exception e) {
        println("Fehler beim Verbinden: " + e.getMessage());
        connected = false;
      }
    } else {
      println("Ungültige Port-Auswahl");
    }
  }
}

// Daten senden
public void sendData() {
  if (connected) {
    int v1 = (int) slider1.getValue();
    int v2 = (int) slider2.getValue();
    int v3 = (int) slider3.getValue();
    int v4 = (int) slider4.getValue();
    int v5 = (int) slider5.getValue();

    String protocol = "speeds :" + v1 + " " + v2 + " " + v3 + " " + v4 + " " +v5;
    myPort.write(protocol + "\n");
    println("Gesendet: " + protocol);
    // Werte in Datei speichern
    String saveData = v1 + "," + v2 + "," + v3 + "," + v4 + "," + v5;
    saveStrings(AktAuto, new String[]{saveData});
    println("Slider-Werte gespeichert: " + saveData);
  } else {
    println("Keine Verbindung zur seriellen Schnittstelle.");
  }
}

void loadSliderValues( String Datei) {
  AktAuto=Datei;
  String[] loadedData = loadStrings(Datei);

  if (loadedData != null && loadedData.length > 0) {
    String[] values = split(loadedData[0], ',');
    if (values.length == 5) {
      slider1.setValue(float(values[0]));
      slider2.setValue(float(values[1]));
      slider3.setValue(float(values[2]));
      slider4.setValue(float(values[3]));
      slider5.setValue(float(values[4]));
      println("Geladene Slider-Werte: " + loadedData[0]);
    }
  } else {
    println("Keine gespeicherten Slider-Werte gefunden.");
  }
}

public void stopAuto() {
  player.close();
  minim.stop();
  if (connected) {    
    String protocol = "stop" ;
    myPort.write(protocol + "\n");
    println("Gesendet: " + protocol);
  } else {
    println("Keine Verbindung zur seriellen Schnittstelle.");
  }
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}

public void startAuto() {
  if (connected) {
    sendData();  // Immer davor aktuelle Werte setzen
    

    for( int i=0; i<3; i++ ){
      sine = new SineWave(440, 0.2, out.sampleRate());
      sine.portamento(5);
      out.addSignal(sine);
      delay(200);
      out.removeSignal(sine);
      delay(1000);
    }
    
    sine = new SineWave(640, 0.2, out.sampleRate());
    sine.portamento(5);
    out.addSignal(sine);
    delay(200);
    out.removeSignal(sine);
    
    String protocol = "start" ;
    myPort.write(protocol + "\n");
    
    int trackNumber = (int)random(2, 10); // 10 is exclusive, so gives 1–9
    String filename = "music/m" + trackNumber + ".mp3";      
    player = minim.loadFile(filename);
    player.rewind();
    player.play();
  
    println("Gesendet: " + protocol);
  } else {
    println("Keine Verbindung zur seriellen Schnittstelle.");
  }
}

// Serielle Daten empfangen
void serialEvent(Serial myPort) {
  String data = myPort.readStringUntil('\n');
  println("Data von Arduino: " + data);
  if (data != null) {
    data = trim(data);
    try {
      speed = float(data); // Empfange Geschwindigkeit (falls korrekt)
    } catch (Exception e) {
      println("Fehler beim Parsen der Geschwindigkeit: " + e.getMessage());
    }
  }
}

void actPorts() {
  portList.clear();
  portList.setLabel("Wähle Port");
  String[] ports = Serial.list();
  for (int i = 0; i < ports.length; i++) {
    portList.addItem(ports[i], i);
  }
}

Slider createSlider(String name, String label, int x, int y, Group group) {
  return cp5.addSlider(name)
            .setLabel(label)
            .setPosition(x, y)
            .setSize(200, 20)
            .setRange(0, 255)
            .moveTo(group);
}
