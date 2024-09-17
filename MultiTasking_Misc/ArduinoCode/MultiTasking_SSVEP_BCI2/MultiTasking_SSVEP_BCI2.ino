#include <LedControl.h>

byte max_units = 3;

int DIN = 12;
int CLK = 11;
int CS = 10;

LedControl lc=LedControl(DIN,CLK,CS,max_units); // Pins: DIN, CLK, CS, # of Display connected

// Generally, you should use "unsigned long" for variables that hold time
// The value will quickly become too large for an int to store
unsigned long previousMillis1 = 0;        // will store last time LED was updated
unsigned long previousMillis2 = 0;        // will store last time LED was updated
unsigned long previousMillis3 = 0;        // will store last time LED was updated

void set_unit(byte number_of_unit){
   /* Wake up displays */
     lc.shutdown(number_of_unit-1,false);//The MAX72XX is in power-saving mode on startup
  /* Set the brightness to a medium values */
  lc.setIntensity(number_of_unit-1,5);
  /* and clear the display */
  lc.clearDisplay(number_of_unit-1);
   
   }
   
void setup() {
  // put your setup code here, to run once:

   for(byte i=1;i<max_units+1;i++)
{
  set_unit(i);
  }

  // start serial port at 9600 bps:
  Serial.begin(9600);

  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
}

byte FirstDisplay[8] = {0x00,0x00,0xFF,0xFF,0xFF,0xFF,0x00,0x00};
byte SecondDisplay[8] = {0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C};
byte ThirdDisplay[8] = {0x0F,0x1F,0x3F,0x7F,0xFE,0xFC,0xF8,0xF0};
byte NoDisplay[8] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};

int FirstFreq = 8; // 651 cycles of 192
int SecondFreq = 10; //521 cycles of 192
int ThirdFreq = 13; // 401 cycles of 192

// constants won't change :
const long Firstinterval = 63;           // interval at which permanent LEDS to blink really fast(milliseconds)
const long Secondinterval = 50;     // interval at which the blinking LEDS will blink (milliseconds)
const long Thirdinterval = 39;     // interval at which the blinking LEDS will blink (milliseconds)

int MatrixOneState = LOW;
int MatrixTwoState = LOW;
int MatrixThreeState = LOW;

// the least common multiple is 520,

char val;

int FeedbackState = false;
   
void loop() {
  // put your main code here, to run repeatedly:
if (Serial.available() > 0)
{
  val = Serial.read();
  }

  if(val == '1')

{
unsigned long currentMillis1 = millis();
unsigned long currentMillis2 = millis();
unsigned long currentMillis3 = millis();

FeedbackState = true;

/*For the first Matrix LED max7219*/
if (currentMillis1 - previousMillis1 >= Firstinterval) {
  // save the last time you blinked the LED
  previousMillis1 = currentMillis1;
  if(MatrixOneState == LOW)
  {
    printFirstDisplay();
    MatrixOneState = HIGH;
    }
    else
    {
      ShutDownFirstDisplay();
      MatrixOneState = LOW;
      }
}

/*For the second Matrix LED max7219*/
if (currentMillis2 - previousMillis2 >= Secondinterval) {
  // save the last time you blinked the LED
  previousMillis2 = currentMillis2;
  if(MatrixTwoState == LOW)
  {
    printSecondDisplay();
    MatrixTwoState = HIGH;
    }
    else
    {
      ShutDownSecondDisplay();
      MatrixTwoState = LOW;
      }
}

/*For the third Matrix LED max7219*/
if (currentMillis3 - previousMillis3 >= Thirdinterval) {
  // save the last time you blinked the LED
  previousMillis3 = currentMillis3;
  if(MatrixThreeState == LOW)
  {
    printThirdDisplay();
    MatrixThreeState = HIGH;
    }
    else
    {
      ShutDownThirdDisplay();
      MatrixThreeState = LOW;
      }
}
}

if(val == '0')
{
  if(FeedbackState == true)
  {
  ShutDownFirstDisplay();
  ShutDownSecondDisplay();
  ShutDownThirdDisplay();
  FeedbackState = false;
  }
  delay(5);// wait for 5ms
  }

}

/*For the first Matrix LED max7219*/
void printFirstDisplay()

{
  printByte(FirstDisplay, 0);
  }

void ShutDownFirstDisplay()

{
  printByte(NoDisplay, 0);
  }

/*For the second Matrix LED max7219*/
void printSecondDisplay()

{
  printByte(SecondDisplay, 1);
  }

void ShutDownSecondDisplay()

{
  printByte(NoDisplay, 1);
  }

/*For the Third Matrix LED max7219*/
void printThirdDisplay()

{
  printByte(ThirdDisplay, 2);
  }

void ShutDownThirdDisplay()

{
  printByte(NoDisplay, 2);
  }

/*Lighting individual LED for LED max7219*/  
void printByte(byte character [],byte number_of_unit)
{
  int i = 0;
  for(i=0;i<8;i++)
  {
    lc.setRow(number_of_unit,i,character[i]);
  }
}

