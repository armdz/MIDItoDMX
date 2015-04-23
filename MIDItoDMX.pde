import controlP5.*;

import themidibus.*;
import processing.serial.*;


Serial dmx;


DMXSender  dmxSender;
String     portName;
boolean    dmxOk = false;
ControlP5  cp5;
RadioButton  radioDmx;
MidiBus      midiBus;
ListBox      listMidi;
Slider       sliderEasing;
int          currentMidi = -1;
int          currentDmx = -1;
boolean      changeOpt = false;
boolean      signal = false;
float        buffer[];        
float        dBuffer[];
boolean      bangBuffer[];
float        easing;
float        MAX_DAMPER = .05;
float        MIN_DAMPER = .9;
String       settingsMidiPort;
String       settingsDmxPort;
float        settingsDamper;
boolean      someError;

void setup()
{
  size(300, 240);
  frameRate(30);

  cp5 = new ControlP5(this);

  settingsDamper = -1;
  settingsMidiPort = "";
  settingsDmxPort = "";
  loadSettings();

  Group  gInput = cp5.addGroup("INPUT (MIDI)")
    .setPosition(10, 20)
      .setBackgroundColor(color(255, 80))
        .setBackgroundHeight(30)
          .setWidth(width-20);

  Group  gOutput = cp5.addGroup("OUTPUT (DMX)")
    .setPosition(10, 70)
      .setBackgroundColor(color(255, 80))
        .setBackgroundHeight(30)
          .setWidth(width-20);

  Group  gEasing = cp5.addGroup("SETTINGS")
    .setPosition(10, 120)
      .setWidth(width-20)
        .setBackgroundColor(color(255, 80))
          .setBackgroundHeight(50);

  gOutput.disableCollapse();
  gInput.disableCollapse();
  gEasing.disableCollapse();

  listMidi = cp5.addListBox("MIDI PORTS")
    .setPosition(10, 20)
      .setGroup(gInput);
  listMidi.close();

  radioDmx = cp5.addRadioButton("dmxradio")
    .setPosition(10, 10)
      .setSize(20, 9)
        .setGroup(gOutput);

  sliderEasing = cp5.addSlider("DAMPER")
    .setPosition(10, 20)
      .setSize(width-40, 15)
        .setRange(0.0, 1.0)
          .setValue(settingsDamper == -1 ? .3 : settingsDamper)
            .setGroup(gEasing);

  cp5.getController("DAMPER").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE).setPaddingX(0);


  gInput.bringToFront();

  //  INPUT

  for (int i=0; i<midiBus.availableInputs ().length; i++)
  {
    listMidi.addItem(midiBus.availableInputs()[i], i);
    if (!settingsMidiPort.equals("")) {
      if (midiBus.availableInputs()[i].equals(settingsMidiPort)) {
        currentMidi = i;
        try {
          midiBus = new MidiBus(this, currentMidi, 0);
        }
        catch (Exception e)
        {
          someError = true;
        }
      }
    }
  }


  //  OUTPUT
  dmxSender = new DMXSender();

  for (int i=0; i<dmxSender.dmx.list ().length; i++)
  {
    if (dmxSender.dmx.list()[i].indexOf("tty") != -1 && dmxSender.dmx.list()[i].toLowerCase().indexOf("bluet") == -1) {
      radioDmx.addItem(dmxSender.dmx.list()[i], i);
      if (!settingsDmxPort.equals(""))
      {
        if (settingsDmxPort.equals(dmxSender.dmx.list()[i]) && !someError)
        {
          currentDmx = i;
          dmxSender.init(this, currentDmx);
        }
      }
    }
  }

  buffer = new float[dmxSender.universeSize];
  dBuffer = new float[dmxSender.universeSize];
  bangBuffer = new boolean[dmxSender.universeSize];
  for (int i=0; i<buffer.length; i++)
  {
    buffer[i] = 0.0;
    dBuffer[i] = 0.0;
    bangBuffer[i] = false;
  }
}

void draw()
{
  background(0);


  if (dmxSender.ok) {
    for (int i=0; i<dBuffer.length; i++)
    {
      buffer[i]+=(dBuffer[i]-buffer[i])*(map(sliderEasing.value(), 0.0, 1.0, MIN_DAMPER, MAX_DAMPER));
      if (bangBuffer[i]) {
        if (buffer[i] <= 0.0)
        {
          buffer[i] = 0.0;
        }

        if (bangBuffer[i])
        {
          bangBuffer[i] = false;
        }
      }
      dmxSender.setDMXChannel(i, (int)buffer[i]);
    }
  }

  if (currentMidi != -1 && currentDmx != -1) {
    fill(0);
    stroke(255);
    rect(10, 180, width-20, 30);
    fill(255);
    String  _txtOut = listMidi.getItem(currentMidi).getName() + " >>> " + dmxSender.dmx.list()[currentDmx];
    text(_txtOut, width/2-textWidth(_txtOut)/2, 195);
    textSize(10);
    if (signal)
    {
      noStroke();
      fill(0, 255, 0);
      rect(0, height-20, width, 20);
    }
  }

  if (signal)
  {
    signal = false;
  }
}

void controllerChange(int channel, int number, int value) {
  if (dmxSender.ok) {
    this.dBuffer[number-1] = (int)map(value, 0, 127, 0, 255);
    this.bangBuffer[number-1] = true;
  }
  signal = true;
}

void controlEvent(ControlEvent theEvent) {

  if (theEvent.isGroup()) {
    if (theEvent.group().getName().equals("MIDI PORTS"))
    {
      if ((int) theEvent.value() != currentMidi) {
        changeOpt = true;
        currentMidi = (int) theEvent.value();
        listMidi.setTitle(listMidi.getItem((int)theEvent.value()).getName());
        midiBus = new MidiBus(this, currentMidi, 0);
      }
      listMidi.close();
    } else {
      currentDmx = (int) theEvent.value();
      dmxSender.init(this, currentDmx);
    }
  }
}

void  loadSettings()
{
  String[]  settings = loadStrings("settings.txt");
  if (settings == null)
  {
    return;
  } else {
    settingsMidiPort = settings[0];
    settingsDmxPort = settings[1];
    settingsDamper = Float.parseFloat(settings[2]);
    println(settingsMidiPort, settingsDmxPort, settingsDamper);
  }
}

void  saveSettings()
{
  String[]  settings = new String[3];
  if (currentMidi != -1 && currentDmx != -1) {
    settings[0] = listMidi.getItem(currentMidi).getName();
    settings[1] = radioDmx.getItem(0).getCaptionLabel().getText();
    settings[2] = Float.toString(sliderEasing.value());
    saveStrings("settings.txt", settings);
  }
}

void  exit()
{
  saveSettings();
  super.exit();
}

