// beat.maker
// random midi drum beat generator
// written by goldfish
// 

// Constants
// midi drum note bytes
#define KICK (0x24)
#define SNARE (0x26)
#define HHOPEN (0x2E)
#define HHCLOSED (0x2A)
#define TOM1 (0x29)
#define TOM2 (0x2B)
#define TOM3 (0x2D)
#define TOM4 (0x2F)
#define TOM5 (0x30)
#define TOM6 (0x32)
#define CRASH1 (0x31)
#define CRASH2 (0x39)
#define RIDE1 (0x33)
#define RIDE2 (0x3B)
#define SPLASH (0x37)

// midi status bytes for channel 10
#define NOTEON (0x99) 
#define NOTEOFF (0x89)
#define PAN (0xB9) 

// define analog input pins
#define tempoPot (0)
#define kickPot (1)
#define snarePot (2)
#define tomsPot (3)
#define cymbalsPot (4)
#define progPot (5)

// define digital i/o pins
#define pKickLED (5)
#define pKickSW (2)
#define pSnareLED (9)
#define pSnareSW (3)
#define pTomsLED (10)
#define pTomsSW (6)
#define pCymbalsLED (11)
#define pCymbalsSW (8)

#define progVolumeSW (4)
#define progRandomSW (7)
#define progPanSW (12)

#define tempoLED (13)

#define minTempo (200)

#define debounceTime (2)

// define Global variables
boolean pKick = 0;
boolean pSnare = 0;
boolean pToms = 0;
boolean pCymbals = 0;
boolean progVolume = 0;
boolean progRandom = 0;
boolean progPan = 0;

int tempo = minTempo;
unsigned long nextBeat;
unsigned long tempoCheck;
unsigned long nextPoll;

int currentStep = 0;
boolean kPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
boolean sPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
boolean tPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
boolean cPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

void setup() {
  //  Set MIDI baud rate:
  //Serial.begin( 31250 );

  //  Set serial link baud rate - for testing
  Serial.begin( 9600 );
  
  // define switch and led pin modes
  pinMode( tempoLED, OUTPUT );
  
  pinMode( pKickLED, OUTPUT );
  pinMode( pSnareLED, OUTPUT );
  pinMode( pTomsLED, OUTPUT );
  pinMode( pCymbalsLED, OUTPUT );
  
  pinMode( pKickSW, INPUT );
  pinMode( pSnareSW, INPUT );
  pinMode( pTomsSW, INPUT );
  pinMode( pCymbalsSW, INPUT );
  
  pinMode( progVolumeSW, INPUT );
  pinMode( progRandomSW, INPUT );
  pinMode( progPanSW, INPUT );
  
  // turn on all leds
  digitalWrite( tempoLED, HIGH );  
  digitalWrite( pKickLED, HIGH );
  digitalWrite( pSnareLED, HIGH );
  digitalWrite( pTomsLED, HIGH );
  digitalWrite( pCymbalsLED, HIGH );
  
  // read prog switches and set leds correctly
  pKick = digitalRead( pKickSW );
  digitalWrite( pKickLED, pKick );
  pSnare = digitalRead( pSnareSW );
  digitalWrite( pSnareLED, pSnare );
  pToms = digitalRead( pTomsSW );
  digitalWrite( pTomsLED, pToms );
  pCymbals = digitalRead( pCymbals );
  digitalWrite( pCymbalsLED, pCymbals );
  
  // set tempo from tempoPot 
  tempo = minTempo + analogRead( tempoPot );
  
  // set tempo trigger for next beat
  nextBeat = millis();
  
  // set up pattern 
  currentStep = 0;
}

void loop() {
  if( millis() > nextBeat ) {
    // set time for next beat
    nextBeat = millis() + tempo;
    
    // play beats for current step
    
    midiSend( NOTEON, KICK, 0x64 ); // note on channel 10, velocity 100
    delay( 20 );
    midiSend( NOTEOFF, KICK, 0x00 ); // note off channel 10
    
    // increment step
    currentStep++;
    if( currentStep == 32 ){
      currentStep = 0;
    }
  }
  
  // poll programming keys
  if( pKick != digitalRead( pKickSW ) || pSnare != digitalRead( pSnareSW ) || pToms != digitalRead( pTomsSW ) || pCymbals != digitalRead( pCymbals ) ){
    delay( debounceTime ); // debounce pause
    pKick = digitalRead( pKickSW );
    digitalWrite( pKickLED, pKick );
    pSnare = digitalRead( pSnareSW );
    digitalWrite( pSnareLED, pSnare );
    pToms = digitalRead( pTomsSW );
    digitalWrite( pTomsLED, pToms );
    pCymbals = digitalRead( pCymbals );
    digitalWrite( pCymbalsLED, pCymbals );
  }
  if( progVolume != digitalRead( progVolumeSW ) || progRandom != digitalRead( progRandomSW ) || progPan != digitalRead( progPanSW ) ){
    delay( debounceTime ); //debounce pause
    int NEWprogVolume = digitalRead( progVolumeSW );
    int NEWprogRandom = digitalRead( progRandomSW );
    int NEWprogPan = digitalRead( progPanSW );
    if( NEWprogVolume != progVolume ){
      // set volume based on prog pot
      int newValue = analogRead( progPot );
    }
    if( NEWprogRandom != progRandom ){
      // set randomness based on prog pot
      int newValue = analogRead( progPot );
    }
    if( NEWprogPan != progPan ){
      // set pan based on prog pot
      int newValue = analogRead( progPot );
    }
  }
    
  // check and update tempo if needed
  tempoCheck = minTempo + analogRead( tempoPot );
  if( abs( tempo - tempoCheck ) > 10 ){ 
    tempo = tempoCheck;
  }
}

//  Send a three byte midi message  
void midiSend(char status, char data1, char data2) {
  Serial.print(status, BYTE); // type of message usually noteon/off and channel
  Serial.print(data1, BYTE);  // usually note
  Serial.print(data2, BYTE);  // usually velocity
}

//  Send a two byte midi message  
void midiProg(char status, int data ) {
  Serial.print(status, BYTE);
  Serial.print(data, BYTE);
}
