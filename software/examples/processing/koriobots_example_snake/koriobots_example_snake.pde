/**
 *  Koriobots Example Mouse2D
 *
 *  Processing for moving 2D koriobot based on your mouse position.
 *  See Koriobot Server documentation here: https://github.com/madelinegannon/koriobots
 *
 *  Library Dependencies:
 *    - oscP5 (https://sojamo.de/libraries/oscP5)
 *    - controlP5 (https://sojamo.de/libraries/controlP5)
 *
 *  Madeline Gannon | atonaton.com
 *  01.17.2023
 */

import netP5.*;
import oscP5.*;
import controlP5.*;

OscP5 oscP5;
NetAddress server_addr;

ControlP5 cp5;
ArrayList<PVector> waypoints = new ArrayList<PVector>(); // waypoints are in absolute pixel (screen) coordinate space. not normalized!

// Change these to match the koriobot server osc settings
String host = "192.168.1.130";   // ip address of the koriobot server
int port_send = 55555;       // receiving port of the koriobot server
int port_receive = 55556;    // sending port of the koriobot server

// Setup the bounds
float bounds_x = 0;
float bounds_y = 0;
float bounds_width = 0;
float bounds_height = 0;

int startTime = 0;
int displayTime = 0;
boolean isPlaying = false;
float secsPerWaypoint = 1.000;
float tailOffsets[] = {1.0, 2.0, 3.0};
int tick = 0;
int updateLimit = 20;

boolean is_inside = false;

void setup() {
  size(800, 500);
  oscP5 = new OscP5(this, port_receive);
  server_addr = new NetAddress(host, port_send);
  setup_gui();

  // Create the safety boundary rectangle
  bounds_x = 180;
  bounds_y = 10;
  bounds_width = 600;
  bounds_height = 375;
  
  strokeWeight(2);
}

void draw() {
  background(0);

  // move the koriobot's target with the mouse if we are inside the safety bounds
  if (is_inside) {
    stroke(100);
    line(mouseX, bounds_y, mouseX, bounds_y+bounds_height);
    line(bounds_x, mouseY, bounds_x+bounds_width, mouseY);
    if (mousePressed){
      fill(255, 60);
      ellipse(mouseX, mouseY, 25, 25);
    }
  }

  // working boundary
  noFill();
  stroke(250, 0, 250);
  rect(bounds_x, bounds_y, bounds_width, bounds_height);
 
  // path between waypoints
  if (waypoints.size() >= 2) {
    stroke(150);
    for (int i = 1; i < waypoints.size(); i++) {
      PVector a = waypoints.get(i -1);
      PVector b = waypoints.get(i);
      line(a.x, a.y, b.x, b.y);
    }
  }
  
  // waypoints
  for (int i = 0; i < waypoints.size(); i++) {
    PVector point = waypoints.get(i);
    if (i == 0) { // starting waypoint
      stroke(0, 200, 0);
      square(point.x - 6, point.y - 6, 12);
    } else if (i == waypoints.size() - 1) { // end waypoint
      stroke(200, 0, 0);
      square(point.x - 5, point.y - 5, 10);
    } else { // middle waypoints
      stroke(0, 100, 240);
      square(point.x - 4, point.y - 4, 8);
    }    
  }
  
  if (isPlaying) {    
    int deltaTime = millis() - startTime; 
    
    if (waypoints.size() >= 2) {
      float progress = deltaTime / (secsPerWaypoint * 1000.0);
      
      PVector cableBotAPos = getInterpolatedVector(progress);
      PVector cableBotBPos = getInterpolatedVector(progress - tailOffsets[0]);
      PVector cableBotCPos = getInterpolatedVector(progress - tailOffsets[1]);
      PVector cableBotDPos = getInterpolatedVector(progress - tailOffsets[2]);
      
      stroke(255, 255, 80); // yellow
      circle(cableBotAPos.x, cableBotAPos.y, 25);
      circle(cableBotBPos.x, cableBotBPos.y, 21);
      circle(cableBotCPos.x, cableBotCPos.y, 17);
      circle(cableBotDPos.x, cableBotDPos.y, 13);
      text(deltaTime / 1000, 10, 490);
      
      tick++;
      if (tick > updateLimit) {
        tick = 0;
        sendNormPos(0, cableBotAPos.x, cableBotAPos.y);
        sendNormPos(1, cableBotBPos.x, cableBotBPos.y);
        sendNormPos(2, cableBotCPos.x, cableBotCPos.y);
        sendNormPos(3, cableBotDPos.x, cableBotDPos.y);
      }
    } else {
      isPlaying = false;
    }    
  }
}

PVector getInterpolatedVector(float progress) {
  float unitProgress = progress - int(progress);
     
  int fromIndex = int(progress);
  int toIndex = fromIndex + 1;
  
  if (progress <= 0) {
    return waypoints.get(0);
  } else if (toIndex < waypoints.size()) {
    PVector fromWaypoint = waypoints.get(fromIndex);
    PVector toWaypoint = waypoints.get(toIndex);
    PVector delta = PVector.sub(toWaypoint, fromWaypoint);
    
    return PVector.add(fromWaypoint, PVector.mult(delta, unitProgress));
  } else {
    return waypoints.get(waypoints.size() - 1);
  }  
}

/**
 *  Check if the mouse is inside the bounds rectangle.
 */
void mouseMoved() {
  is_inside = 
    (mouseX > bounds_x) & 
    (mouseX < bounds_x+bounds_width) & 
    (mouseY > bounds_y) & 
    (mouseY < bounds_y+bounds_height);
}

/**
 *  Move the koriobots if we are pressing the mouse button.
 */
void mousePressed() {
  if (is_inside){

  }
}
/*
void SendtoWaypoint() {
  if (is_inside){
    OscMessage msg = new OscMessage("/move_vel");
    msg.add(true);    
    oscP5.send(msg, server_addr);
  }
}
 */

/**
 *  add a waypoint at the mouse position
 */
void mouseReleased() {
  if (is_inside){
    waypoints.add(
      new PVector(mouseX, mouseY)
    );
  }
}

void calcWave() {
  // For every x value, calculate a y value with sine function
  float amp = 120;  // Height of wave
  for (float i = 0.0; i < TWO_PI * 6; i += PI/8.0) {
    waypoints.add(
      new PVector(
        i * 10 + bounds_x + bounds_width/2 - 200,
        sin(i) * amp + bounds_y + bounds_height/2
      )
    );
  }
}

void calcCircle() {
  // For every x value, calculate a y value with circle function
  float amp = 160;
  for (float i = 0.0; i < TWO_PI; i += PI/8.0) {
    waypoints.add(
      new PVector(
        cos(i)*amp + bounds_x + bounds_width/2, 
        sin(i)*amp + bounds_y + bounds_height/2
      )
    );
  }
}

void calcLissajous() {
  // For every x and y value, calculate the Lissajous function
  int a = 1, b = 2;
  float amp = 160;
  for (float i = 0.0; i < TWO_PI; i += PI/16.0) {
    waypoints.add(
      new PVector(
        sin(a * i + PI/2) * amp * 1.5 + bounds_x + bounds_width/2, 
        sin(b * i) * amp + bounds_y + bounds_height/2
      )
    );
  }
}

void calcRose() {
  // For every x and y value, calculate the rose function
  float a = 1.5;
  float amp = 180;
  for (float i = 0.0; i < TWO_PI * 2; i += PI/16.0) {
    waypoints.add(
      new PVector(
        cos(a * i) * cos(i) * amp + bounds_x + bounds_width/2, 
        cos(a * i) * sin(i) * amp + bounds_y + bounds_height/2
      )
    );
  }
}

void sendNormPos(int index, float x, float y) {
  float xNorm = (x - bounds_x) / bounds_width;
  float yNorm = (y - bounds_y) / bounds_height;
  OscMessage msg = new OscMessage("/norm");
  msg.add(index);
  msg.add(xNorm);
  msg.add(yNorm);
  //println(x, y, xNorm, yNorm);
  oscP5.send(msg, server_addr);
}

/**
 *  Incoming OSC message are forwarded to the oscEvent method.
 */
void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}

/**
 *  GUI Event handler
 */
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController() && millis() > 1500) {          // ignore triggers as the program loads
    OscMessage msg = new OscMessage("/test");
    String name = theEvent.getController().getName();
    switch (name) {
      case "ESTOP":
        isPlaying = false;
        msg = new OscMessage("/stop");
        oscP5.send(msg, server_addr);
        break;
      case "RESET":
        isPlaying = false;
        if (waypoints.size() >= 1) {
          // move all to starting waypoint
          println("move to starting waypoint");
          sendNormPos(-1, waypoints.get(0).x, waypoints.get(0).y);
        }
        break;
      case "CLEAR":
        isPlaying = false;
        waypoints.clear();        
        break;
      case "CIRCLE":
        calcCircle();
        break;
      case "SINE WAVE":
        calcWave();
        break;
      case "LISSAJOUS":
        calcLissajous();
        break;
      case "ROSE":
        calcRose();
        break;
      case "PLAY":       
        startTime = millis();
        isPlaying = true;     
        break;
      case "SPEED":
        isPlaying = false;
        secsPerWaypoint = theEvent.getController().getValue();
        break;
      case "M1":
        tailOffsets[0] = 1.0;
        tailOffsets[1] = 2.0;
        tailOffsets[2] = 3.0;
        break;
      case "M2":
        tailOffsets[0] = 4.0;
        tailOffsets[1] = 8.0;
        tailOffsets[2] = 12.0;
        break;
      case "M3":
        tailOffsets[0] = 0.8;
        tailOffsets[1] = 3.0;
        tailOffsets[2] = 3.8;
        break;
    }
    
    
    if (theEvent.getController().getName() == "enable_move") {
      msg = new OscMessage("/move_vel");
      msg.add(theEvent.getController().getValue());
      oscP5.send(msg, server_addr);
    } else if (theEvent.getController().getName() == "all") {
      // normalize the {X,Y} value before sending
      float x = theEvent.getController().getArrayValue()[0] / 100.0;
      float y = theEvent.getController().getArrayValue()[1] / 100.0;
      msg = new OscMessage("/norm");
      // use the -1 index to move all koriobots
      msg.add(-1);
      msg.add(x);
      msg.add(y);
    } else if (theEvent.getController().getName() == "reset") {
      msg = new OscMessage("/reset");
    } else if (theEvent.getController().getName() == "position") {
      // normalize the {X,Y} value before sending
      float x = theEvent.getController().getArrayValue()[0] / 100.0;
      float y = theEvent.getController().getArrayValue()[1] / 100.0;
      msg = new OscMessage("/bounds/pos");
      msg.add(x);
      msg.add(y);
    } else if (theEvent.getController().getName() == "width") {
      msg = new OscMessage("/bounds/width");
      msg.add(theEvent.getController().getValue());
    } else if (theEvent.getController().getName() == "height") {
      msg = new OscMessage("/bounds/height");
      msg.add(theEvent.getController().getValue());
    } else if (theEvent.getController().getName() == "vel") {
      msg = new OscMessage("/limits/velocity");
      msg.add(theEvent.getController().getValue());
    } else if (theEvent.getController().getName() == "accel") {
      msg = new OscMessage("/limits/acceleration");
      msg.add(theEvent.getController().getValue());
    }
  }
}

void setup_gui() {
  cp5 = new ControlP5(this);

  int x = 10; // left widget margin
  int y = 25; // top widget margin

  Group params = cp5.addGroup("params")
    .setLabel("Koriobot Controller")
    .setPosition(x, y)
    .setWidth(150)
    .setHeight(15)
    .activateEvent(true)
    .setBackgroundColor(color(255, 120))
    .setBackgroundHeight(450);

  cp5.addButton("ESTOP")
    .setPosition(x, 10)
    .setSize(50, 50)
    .setGroup(params)
    .setColorBackground(color(120, 0, 0))
    .setColorForeground(color(160, 0, 0))
    .setColorActive(color(250, 0, 0));  

  cp5.addToggle("enable_move")
    .setPosition(x + 60, 10)
    .setSize(25, 25)
    .setGroup(params)
    .setColorBackground(color(0, 120, 0))
    .setColorForeground(color(0, 180, 0))
    .setColorActive(color(0, 250, 0))
    .setLabelVisible(true);
    
  cp5.addButton("SINE WAVE")
    .setCaptionLabel("Wave")
    .setPosition(x, 85)
    .setSize(100, 25)
    .setGroup(params);    
    
  cp5.addButton("CIRCLE")
    .setPosition(x, 120)
    .setSize(100, 25)
    .setGroup(params);
    ;     
    
  cp5.addButton("LISSAJOUS")
    .setPosition(x, 155)
    .setSize(100, 25)
    .setGroup(params);
    
   cp5.addButton("ROSE")
    .setPosition(x, 190)
    .setSize(100, 25)
    .setGroup(params);   

  cp5.addButton("RESET")
    .setPosition(x, 260)
    .setSize(50, 50)
    .setGroup(params)
    .setColorBackground(color(180, 180, 0))
    .setColorForeground(color(180, 180, 0))
    .setColorActive(color(180, 250, 0)); 

  cp5.addButton("CLEAR")
    .setPosition(x + 60, 260)
    .setSize(50, 50)
    .setGroup(params)
    .setColorBackground(color(120, 0, 0))
    .setColorForeground(color(180, 0, 0))
    .setColorActive(color(259, 0, 0));   

  cp5.addButton("PLAY")
    .setPosition(x, 320)
    .setSize(50, 50)
    .setGroup(params)
    .setColorBackground(color(0, 120, 0))
    .setColorForeground(color(0, 180, 0))
    .setColorActive(color(0, 250, 0)); 

  cp5.addSlider("SPEED")
    .setLabel("Sec per WP")
    .setPosition(x, 380)
    .setSize(80, 25)
    .setMin(0.25)
    .setMax(3.0)
    .setValue(1.0)
    .setGroup(params);

  cp5.addButton("M1")
    .setPosition(x, 420)
    .setSize(20, 20)
    .setGroup(params);
  cp5.addButton("M2")
    .setPosition(x + 30, 420)
    .setSize(20, 20)
    .setGroup(params);
    cp5.addButton("M3")
    .setPosition(x + 60, 420)
    .setSize(20, 20)
    .setGroup(params);
/*
  // Set up MOTION parameters
  Group params_motion = cp5.addGroup("params_motion")
    .setPosition(x+160, y + 10)
    .setWidth(200)
    .setHeight(15)
    .activateEvent(true)
    .setBackgroundColor(color(255, 120))
    .setBackgroundHeight(300)
    .setLabel("Motion")
    ;

  cp5.addSlider2D("all")
    .setPosition(x, x)
    .setSize(w, w)
    .setMinMax(0.0, 0.0, 100, 100)
    .setValue(50, 50)
    .setGroup(params_motion)
    ;

  cp5.addButton("reset")
    .setPosition(x, y + w + 5)
    .setSize(h, h)
    .setGroup(params_motion)
    .setLabelVisible(false)
    ;

  cp5.addLabel("RESET")
    .setPosition(x+h, y + w + 5 + 8)
    .setGroup(params_motion)
    ;

  // Set up BOUNDS parameters
  Group params_bounds = cp5.addGroup("params_bounds")
    .setPosition(x+370, y + 10)
    .setWidth(200)
    .setHeight(15)
    .activateEvent(true)
    .setBackgroundColor(color(255, 120))
    .setBackgroundHeight(300)
    .setLabel("Bounds")
    ;

  cp5.addSlider2D("position")
    .setPosition(x, x)
    .setSize(w, w)
    .setMinMax(0.0, 100.0, 100.0, 0.0)
    .setValue(50, 50)
    .setGroup(params_bounds)
    ;

  cp5.addSlider("width")
    .setPosition(x, y+w+5 + 0*y_offset)
    .setSize(w, h)
    .setMin(0)
    .setMax(1)
    .setGroup(params_bounds)
    ;

  cp5.addSlider("height")
    .setPosition(x, y+w+5 + 1*y_offset)
    .setSize(w, h)
    .setMin(0)
    .setMax(1)
    .setGroup(params_bounds)
    ;

  // Set up LIMITS parameters
  Group params_limits = cp5.addGroup("params_limits")
    .setPosition(x+580, y + 10)
    .setWidth(200)
    .setHeight(15)
    .activateEvent(true)
    .setBackgroundColor(color(255, 120))
    .setBackgroundHeight(150)
    .setLabel("Limits")
    ;

  cp5.addSlider("vel")
    .setPosition(x, x)
    .setSize(w, h)
    .setMin(0)
    .setMax(1)
    .setGroup(params_limits)
    ;

  cp5.addSlider("accel")
    .setPosition(x, x + 1*y_offset)
    .setSize(w, h)
    .setMin(0)
    .setMax(1)
    .setGroup(params_limits)
    ;*/
}
