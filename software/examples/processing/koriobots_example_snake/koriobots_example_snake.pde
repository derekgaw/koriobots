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

// Change these to match the koriobot server osc settings
String host = "127.0.0.1";   // ip address of the koriobot server
int port_send = 55555;       // receiving port of the koriobot server
int port_receive = 55556;    // sending port of the koriobot server

// Setup the bounds
float bounds_x = 0;
float bounds_y = 0;
float bounds_width = 0;
float bounds_height = 0;

boolean is_inside = false;

void setup() {
  size(800, 1000);
  oscP5 = new OscP5(this, port_receive);
  server_addr = new NetAddress(host, port_send);
  setup_gui();

  // Create the safety boundary rectangle
  bounds_width = width/2;
  bounds_height = bounds_width;
  bounds_x = width/2 - bounds_width/2;
  bounds_y = height/2 - bounds_width/3;
}

void draw() {
  background(0);

  // move the koriobot's target with the mouse if we are inside the safety bounds
  if (is_inside) {
    // normalize the mouse position based on the safety bounds
    float x = map(mouseX, bounds_x, bounds_x+bounds_width, 0, 1);
    float y = map(mouseY, bounds_y, bounds_y+bounds_height, 0, 1);
    OscMessage msg = new OscMessage("/norm");
    msg.add(-1);    // use the -1 index to move all koriobots
    msg.add(x);
    msg.add(y);
    oscP5.send(msg, server_addr);

    // highlight the bounds when the mouse is inside 
    fill(250, 0, 250, 80);
    rect(bounds_x, bounds_y, bounds_width, bounds_height);
    fill(255, 0, 255);
    ellipse(mouseX, mouseY, 10, 10);
    line(mouseX, bounds_y, mouseX, bounds_y+bounds_height);
    line(bounds_x, mouseY, bounds_x+bounds_width, mouseY);
    if (mousePressed){
      fill(255, 60);
      ellipse(mouseX, mouseY, 25, 25);
    }
  }

  // draw the bounds
  noFill();
  stroke(250, 0, 250);
  rect(bounds_x, bounds_y, bounds_width, bounds_height);
}

/**
 *  Check if the mouse is inside the bounds rectangle.
 */
void mouseMoved() {
  is_inside = (mouseX > bounds_x) & (mouseX < bounds_x+bounds_width) & (mouseY > bounds_y) & (mouseY < bounds_y+bounds_height);
}

/**
 *  Move the koriobots if we are pressing the mouse button.
 */
void mousePressed() {
  if (is_inside){
    OscMessage msg = new OscMessage("/move_vel");
    msg.add(true);    
    oscP5.send(msg, server_addr);
  }
}

/**
 *  Stop moving the koriobots if we released the mouse button.
 */
void mouseReleased() {
  if (is_inside){
    OscMessage msg = new OscMessage("/move_vel");
    msg.add(false);    
    oscP5.send(msg, server_addr);
  }
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
    if (theEvent.getController().getName() == "stop!") {
      msg = new OscMessage("/stop");
    } else if (theEvent.getController().getName() == "enable_move") {
      msg = new OscMessage("/move_vel");
      msg.add(theEvent.getController().getValue());
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
    oscP5.send(msg, server_addr);
  }
}


void setup_gui() {
  cp5 = new ControlP5(this);

  int x = 10;
  int y = 25;
  int h = 25;
  int w = 150;
  int y_offset = 30;

  Group params = cp5.addGroup("params")
    .setPosition(x, y + 10)
    .setWidth(150)
    .setHeight(15)
    .activateEvent(true)
    .setBackgroundColor(color(255, 120))
    .setBackgroundHeight(150)
    .setLabel("Koriobot Controller")
    ;

  cp5.addButton("stop!")
    .setPosition(x, x)
    .setSize(h*2, h*2)
    .setGroup(params)
    .setColorBackground(color(120, 0, 0))
    .setColorForeground(color(160, 0, 0))
    .setColorActive(color(250, 0, 0))
    ;

  cp5.addToggle("enable_move")
    .setPosition(x, x + h*3)
    .setSize(h, h)
    .setGroup(params)
    .setColorBackground(color(0, 120, 0))
    .setColorForeground(color(0, 180, 0))
    .setColorActive(color(0, 250, 0))
    .setLabelVisible(false)
    ;

  cp5.addLabel("ENABLE_MOVE")
    .setPosition(x+h, x + h*3 + 8)
    .setGroup(params)
    ;

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
    ;
}
