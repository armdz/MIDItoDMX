//  the code to format message to enttec is from https://processing.org/discourse/beta/num_1128939792.html
//  author : rrrufusss

static byte DMX_PRO_MESSAGE_START = byte(0x7E);
static byte DMX_PRO_MESSAGE_END = byte(0xE7);
static byte DMX_PRO_SEND_PACKET = byte(6);

class DMXSender
{

  int universeSize = 128;
  byte[] channelValues;
  Serial  dmx;
  PApplet  parent;
  boolean  ok = false;
  DMXSender()
  {
  }

  void  init(PApplet  _parent, int port)
  {
    parent = _parent;
    dmx = new Serial(parent, dmx.list()[port], 115200);
    channelValues = new byte[universeSize];
    for (int i = 0; i < universeSize; i++)
    {
      channelValues[i] = byte(0);
    }
    ok = true;
  }

  String  resolvePortName()
  {
    String[]  ports = dmx.list();
    String    ret = "";
    int ok = -1;
    int i = 0;
    println(ports);
    while (ok == -1 && i < ports.length)
    {
      if (ports[i].toLowerCase().indexOf("8133") != -1 && ports[i].toLowerCase().indexOf("tty") != -1)
      {
        ok = i;
      }
      i++;
    }
    return i != -1 ? ret = ports[ok] : "";
  }

  void setDMXChannel(int channel, int value)
  {
    if (channelValues[channel] != byte(value))
    {
      channelValues[channel] = byte(value);
      byte[] data = new byte[universeSize+1];

      data[0] = 0; // DMX command byte..

      for (int i = 0; i < universeSize; i++)
      {
        data[i+1] = channelValues[i];
      }
      dmxMessage( DMX_PRO_SEND_PACKET, data );
    }
  }

  void dmxMessage( byte messageType, byte[] data )
  {
    byte[] message;
    int dataSize = data.length;
    message = new byte[5 + dataSize];

    message[0] = DMX_PRO_MESSAGE_START;

    message[1] = messageType;

    message[2] = byte(dataSize & 255);
    message[3] = byte((dataSize >> 8) & 255);

    // there's probably a faster way to do this...
    for (int i = 0; i < dataSize; i++)
    {
      message[i+4] = data[i];
    }

    message[4 + dataSize] = DMX_PRO_MESSAGE_END;

    dmx.write(message);
  }
}

