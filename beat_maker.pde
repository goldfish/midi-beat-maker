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
#define progPot (1)
#define slider1 (2)
#define slider2 (3)
#define slider3 (4)
#define slider4 (5)

// define digital i/o pins
#define chan1LED (10)
#define chan1SW (5)
#define chan2LED (8)
#define chan2SW (4)
#define chan3LED (9)
#define chan3SW (3)
#define chan4LED (7)
#define chan4SW (2)
#define progVolumeSW (12)
#define progRandomSW (11)
#define progPatSW (13)
#define tempoLED (6)

// define Global variables

// stored value of programming switches. these get defined in setup()
boolean chan1;
boolean chan2;
boolean chan3;
boolean chan4;
boolean progVolume;
boolean progRandom;
boolean progPat;

// initial values of pattern pots. set at 1200 so that the polling routine will kick in.
int slider1Value = 1200;
int slider2Value = 1200;
int slider3Value = 1200;
int slider4Value = 1200;

// variables to store and control timing
int stepDelay;  // the length of the pauses between beats.
unsigned long nextBeat;    // trigger time for next beat
unsigned long stepDelayCheck;  // used to monitor tempo pot
unsigned long nextPoll;    // trigger time for next input poll
unsigned long stepTime;    // stores the time at the start of the loop(). Eliminates multiple millis() calls.

// variables related to drum patterns
int currentStep = 0;
byte kickP[] = { B00000000, B00000000, B00000000, B00000000 };
byte snareP[] = { B00000000, B00000000, B00000000, B00000000 };
byte hhopenP[] = { B00000000, B00000000, B00000000, B00000000 };
byte hhclosedP[] = { B00000000, B00000000, B00000000, B00000000 };

byte kickVolume = 100;        // volume midi values 0-127
byte snareVolume = 100;
byte hhopenVolume = 100;
byte hhclosedVolume = 100;

void setup() {
    //  Set serial rate to 31250 for MIDI
    //  Set serial rate to 9600 for testing
    Serial.begin( 31250 );
    //Serial.begin( 9600 );
    
    // set up led output pins
    pinMode( tempoLED, OUTPUT );
    pinMode( chan1LED, OUTPUT );
    pinMode( chan2LED, OUTPUT );
    pinMode( chan3LED, OUTPUT );
    pinMode( chan4LED, OUTPUT );
    
    // turn on all leds and hold them high for 2 sec
    digitalWrite( tempoLED, HIGH );  
    digitalWrite( chan1LED, HIGH );
    digitalWrite( chan2LED, HIGH );
    digitalWrite( chan3LED, HIGH );
    digitalWrite( chan4LED, HIGH );
    delay( 2000 );

    // read programming switches and set leds correctly
    chan1 = digitalRead( chan1SW );
    digitalWrite( chan1LED, chan1 );
    chan2 = digitalRead( chan2SW );
    digitalWrite( chan2LED, chan2 );
    chan3 = digitalRead( chan3SW );
    digitalWrite( chan3LED, chan3 );
    chan4 = digitalRead( chan4SW );
    digitalWrite( chan4LED, chan4 );
    
    // set up input pins. Set mode as INPUT, and then use digtalWrite HIGH to turn on the internal pull-up resistors.
    pinMode( chan1SW, INPUT );
    digitalWrite( chan1SW, HIGH ); 
    pinMode( chan2SW, INPUT );
    digitalWrite( chan2SW, HIGH ); 
    pinMode( chan3SW, INPUT );
    digitalWrite( chan3SW, HIGH ); 
    pinMode( chan4SW, INPUT );
    digitalWrite( chan4SW, HIGH ); 
    pinMode( progVolumeSW, INPUT );
    digitalWrite( progVolumeSW, HIGH );  
    pinMode( progRandomSW, INPUT );
    digitalWrite( progRandomSW, HIGH ); 
    pinMode( progPatSW, INPUT );
    digitalWrite( progPatSW, HIGH ); 
    
    // set stepDelay from tempoPot <-- yeah, it looks weird, but it gives a good range
    stepDelay = checkDelay();
    
    // set tempo trigger for next beat and next poll
    nextBeat = millis();
    nextPoll = nextBeat;
    
    // set up pattern 
    currentStep = 0;
}

void loop() {
    stepTime = millis();
    if( stepTime > nextBeat ) {
        // set time for next beat
        nextBeat = stepTime + stepDelay;
                
        // play beats for current step
        int patternByte = (int)( currentStep / 8 );
        int byteStep = currentStep % 8;
        
        if( bitRead( byteStep, kickP[ patternByte ] ) ) {
            midiSend( NOTEON, KICK, kickVolume );
        }
        if( bitRead( byteStep, snareP[ patternByte ] ) ) {
            midiSend( NOTEON, SNARE, snareVolume );
        }

        // increment step
        currentStep++;
        if( currentStep == 32 ){ // 32 steps in the pattern
            currentStep = 0;
        }
    }
    
    if( stepTime > nextPoll ){
        // set time for next poll
        nextPoll = pollInputs( stepTime );
    }
}  

//  Set the kick pattern
void setKickPattern( int patternValue ) {
    switch( patternValue ){
        case 0:
            kickP[ 0 ] = B00000000;
            kickP[ 0 ] = B00000000;
            kickP[ 0 ] = B00000000;
            kickP[ 0 ] = B00000000;
            break;
        case 1:
            kickP[ 0 ] = B10000000;
            kickP[ 0 ] = B10000000;
            kickP[ 0 ] = B10000000;
            kickP[ 0 ] = B10000000;
            break;
    }
}

void setSnarePattern( int patternValue ) {
}
void setTomsPattern( int patternValue ) {
}
void setCymbalsPattern( int patternValue ) {
}

unsigned long pollInputs( unsigned long pollTime ){
    // poll pattern inputs
    int slider1Read = analogRead( slider1 );
    if( abs( slider1Read - slider1Value ) > 3 ){
        slider1Value = slider1Read;
        setKickPattern( slider1Value );
    }
    
    int slider2Read = analogRead( slider2 );
    if( abs( slider2Read - slider2Value ) > 3 ){
        slider2Value = slider2Read;
        setSnarePattern( slider2Value );
    }
    
    int slider3Read = analogRead( slider3 );
    if( abs( slider3Read - slider3Value ) > 3 ){
        slider3Value = slider3Read;
        setTomsPattern( slider3Value );
    }
    
    int slider4Read = analogRead( slider4 );
    if( abs( slider4Read - slider4Value ) > 3 ){
        slider4Value = slider4Read;
        setCymbalsPattern( slider4Value );
    }

    // poll programming keys
    int chan1Read = digitalRead( chan1SW );
    if( chan1 != chan1Read ){
        chan1 = chan1Read;
        digitalWrite( chan1LED, chan1 );
    }

    int chan2Read = digitalRead( chan2SW );
    if( chan2 != chan2Read ){
        chan2 = chan2Read;
        digitalWrite( chan2LED, chan2 );
    }
    
    int chan3Read = digitalRead( chan3SW );
    if( chan3 != chan3Read ){
        chan3 = chan3Read;
        digitalWrite( chan3LED, chan3 );
    }
    
    int chan4Read = digitalRead( chan4SW );
    if( chan4 != chan4Read ){
        chan4 = chan4Read;
        digitalWrite( chan4LED, chan4 );
    }
    
    // poll programming inputs
    int progReadValue = analogRead( progPot );
    int prog128Value = ( progReadValue * 0.124  );
    
    if ( !(digitalRead( progRandomSW )) ){   // set randomness
        if( chan1 ){
            //kickRandomness = progReadValue;
        }
        if( chan2 ){
            //snareRandomness = progReadValue;
        }
        if( chan3 ){
            //tomsRandomness = progReadValue;
        }
        if( chan4 ){
            //cymbalsRandomness = progReadValue;
        }
    }
    
    if ( !(digitalRead( progVolumeSW )) ){   // set volume level to 0-127
        if( chan1 ){
            kickVolume = prog128Value;
        }
        if( chan2 ){
            snareVolume = prog128Value;
        }
        if( chan3 ){
            //tomsVolume = prog128Value;
        }
        if( chan4 ){
            //cymbalsVolume = prog128Value;
        }
    }

    if ( !(digitalRead( progPatSW )) ){   // set beats into the pattern
        if( chan1 ){
            //
        }
        if( chan2 ){
            //
        }
        if( chan3 ){
            //
        }
        if( chan4 ){
            //
        }
    }

    // check and update stepDelay if needed  
    stepDelayCheck = checkDelay();
    if( abs( stepDelay - stepDelayCheck ) > 10 ){ 
        stepDelay = stepDelayCheck;
    }
    
    return( pollTime + 75 ); // 75 is the poll interval
}

unsigned long checkDelay( ) {
    return( 2 * ( 1100 - analogRead( tempoPot ) ) );
}

//  Send a three byte midi message  
void midiSend(char status, char data1, char data2) {
    Serial.print(status, BYTE); // type of message usually noteon/off and channel
    Serial.print(data1, BYTE);  // usually note
    Serial.print(data2, BYTE);  // usually velocity
}
