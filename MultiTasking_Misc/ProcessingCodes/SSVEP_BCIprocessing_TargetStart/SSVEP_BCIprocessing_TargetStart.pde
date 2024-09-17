
/*
====================================================================================================                                                                                    
 
 SSVEP blinking matrix LED for BCI
 Developed by Jianjun Meng - March 2017.
 This was adapted from Emal Alwis, May 2013 - February 2014.
 And Angeliki Beyo, Shuying Zhang, and Chris Cline, 2014 - 2015.
 Copyright (c) 2017 Biomedical Functional Imaging and Neuroengineering Lab, UMN
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
 
 ====================================================================================================
 */

/*                         LIBRARIES
 ==================================================================================================== */
//import g4p_controls.*; // Need G4P library
import hypermedia.net.*; // related to udp
import processing.serial.*;
//import controlP5.*;     // import controlP5 library

/*                    VARIABLE INITIALIZATION
 ==================================================================================================== */
//ControlP5 controlP5;   // controlP5 object

String Feed = "Feedback";
String Target = "TargetCode";
String Running = "Running";

boolean F_State = false;
boolean Target_State = false;
boolean Running_State = false;

volatile int TargetNum;
boolean TargetNum_updated;

/*                     SERIAL & UDP COMM INITIALIZATION
 ==================================================================================================== */
int PORT_RX=45443; //
String HOST_IP = "localhost";//IP Address of the PC in which this App is running
UDP udp;//Create UDP object for receiving
Serial myArduino;


/*                    SETUP / SOFTWARE INITIALIZATION
 ==================================================================================================== */
public void setup() {
  
  size(640, 400, JAVA2D);

  // Begin UDP Read Protocol  
  udp= new UDP(this, PORT_RX, HOST_IP);
  udp.log(false);
  udp.listen(true);

  // Define a new COM port to be the first port available
  if (Serial.list().length > 0) { // check if serial port available
    myArduino = new Serial(this, Serial.list()[0], 9600);
    myArduino.bufferUntil('\n');
  } else {
    //none available
    println("No serial port available!");
    delay(100);
    //exit();// throw exception
  }

  F_State = false;
  Target_State = false;
  Running_State = false;

  //noLoop(); // Required for UDP from BCI 2000???

  delay(10);

  // Initialize GUI
  //createGUI();
  customGUI();
  smooth(); 
}

/*                      MAIN PROGRAM
 ====================================================================================================
 ==================================================================================================== */
/*
        This subroutine handles the reading of the UDP data from BCI 2000, 
 and tells various subroutines to send commands to the gloves.
 */
void receive(byte[] data, String HOST_IP, int PORT_RX)
{
  String value=new String(data);
  String parts[] = value.split("[ ]");

  /*   Reads the Feedback Status from BCI 2000
  ==================================================*/
  if (Feed.equals(parts[0]) == true)
  {
    String feed_str = parts[1].trim();
    int feed_int = Integer.parseInt(feed_str);    
    int feed = int(feed_int);
    if (feed == 1)
    {
      //println("Feedback: " + "ON");
      F_State = true;
    }
    else
    {
      //println("Feedback: " + "OFF");
      F_State = false;
    }
    
  /*   Reads the Target Status from BCI 2000
  ==================================================*/
  } else if (Target.equals(parts[0]) == true) {
    String targ_str = parts[1].trim();
    int targ_int = Integer.parseInt(targ_str);    
    int targ = int(targ_int);

    TargetNum = targ;
    println("TargetCode: " + TargetNum);
    if (TargetNum >= 1)
    {
      Target_State = true;
    }
    else
    {
      Target_State = false;
    }
    
    TargetNum_updated = true;
  
  
  /*   Reads the Running state of Cursor application from BCI2000
  ==================================================*/
  } else if (Running.equals(parts[0]) == true) {
    String running_str = parts[1].trim();
    int running_int = Integer.parseInt(running_str);    
    int running = int(running_int);

    //println("Running: " + running);
    if (running == 1)
    {
      Running_State = true;
    }
    else
    {
      Running_State = false;
      Target_State = false;
      F_State = false;
    }
  
  
  /*   Reads the Position of Cursor on Y-axis
  ==================================================*/
  }else {
    //println("Unrecognised UDP message: " + parts[0]);
  }
  
  // at this point, pose_x, pose_y, F_State, User_State, and mode_state are all "up to date"
  
  if(Target_State && Running_State)
  {
    myArduino.write('1');
  }
  else
  {
    myArduino.write('0');
  }
  
  //TODO: find out whether one particular message is always "last" in sequence of updates to see if that can conclusively trigger an update,
  // rather than updating message as soon as Pos_x changes, even though an updated Pos_y is likely about to arrive.
  
}

/*                      END OF MAIN PROGRAM
 ====================================================================================================
 ==================================================================================================== */


/*                    ADDITIONAL SUBROUTINES
 ==================================================================================================== */

public void draw()
{
  background(255);
}

// Use this method to add additional statements
// to customise the GUI controls
public void customGUI()
{
}

void serialEvent(Serial port)
{
}

/*                    
 ==================================================================================================== */

 