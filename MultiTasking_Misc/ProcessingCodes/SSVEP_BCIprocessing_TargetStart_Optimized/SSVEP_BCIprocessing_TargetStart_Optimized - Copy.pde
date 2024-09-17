
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

boolean F_State = false;
boolean Target_State = false;
boolean Running_State = false;

boolean TargetNum_updated;

boolean is_flashing = false;

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
    myArduino.write('0');
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
  String data_str=new String(data);
  String parts[] = data_str.split("[ ]");
  
  String status = parts[0];
  //println(parts[1]);

  /*   Reads the Feedback Status from BCI 2000
  ==================================================*/
  if (status.equals("Feedback"))
  {
    int feed = getValue(parts[1]);
    // F_State is true if feed is 1
    F_State = (feed == 1);
    
  /*   Reads the Target Status from BCI 2000
  ==================================================*/
  } else if (status.equals("TargetCode")) {
    // tnum is target number
   
    int tnum = getValue(parts[1]);
    println("TargetCode: " + tnum);
    
    Target_State = (tnum >= 1);
    TargetNum_updated = true;
  
  
  /*   Reads the Running state of Cursor application from BCI2000
  ==================================================*/
  } else if (status.equals("Running")) {
    int value = getValue(parts[1]);
    Running_State = (value == 1);
    
    if (!Running_State)
    {
      Target_State = false;
      F_State = false;
    }
  
  
  /*   Reads the Position of Cursor on Y-axis
  ==================================================*/
  } else {
    //println("Unrecognised UDP message: " + parts[0]);
  }
  
  // at this point, pose_x, pose_y, F_State, User_State, and mode_state are all "up to date"
  
  if(F_State && Running_State)
  {
      if (!is_flashing)
      {
        println("flash on");
        myArduino.write('1');
        is_flashing = true;
      }
  }
  else if (is_flashing)
  {
    println("flash off");
    myArduino.write('0');
    is_flashing = false;
  }
  
  //TODO: find out whether one particular message is always "last" in sequence of updates to see if that can conclusively trigger an update,
  // rather than updating message as soon as Pos_x changes, even though an updated Pos_y is likely about to arrive.
  
}

int getValue(String data)
{
   return int(Integer.parseInt(data.trim())); 
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

 
