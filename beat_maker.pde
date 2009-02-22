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
#define kickPot (2)
#define snarePot (3)
#define tomsPot (4)
#define cymbalsPot (5)

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

#define minTempo (1100)

// define Global variables
boolean pKick = 0;  // initial value of programming switches
boolean pSnare = 0;
boolean pToms = 0;
boolean pCymbals = 0;
boolean progVolume = 0;
boolean progRandom = 0;
boolean progPan = 0;

int kickPotValue = 0;
int snarePotValue = 0;
int tomsPotValue = 0;
int cymbalsPotValue = 0;

int tempo = minTempo;
unsigned long nextBeat;
unsigned long tempoCheck;
unsigned long nextPoll;
unsigned long stepTime;
unsigned long tempoLEDoff;
int pollInterval = 50;

int currentStep = 0;
byte kPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
byte sPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
byte tPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
byte cPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

int kickRandomness = 0;
int snareRandomness = 0;
int tomsRandomness = 0;
int cymbalsRandomness = 0;

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
    digitalWrite( pKickSW, HIGH );  // turn on internal pull-up
    pinMode( pSnareSW, INPUT );
    digitalWrite( pSnareSW, HIGH ); // turn on internal pull-up
    pinMode( pTomsSW, INPUT );
    digitalWrite( pTomsSW, HIGH );  // turn on internal pull-up
    pinMode( pCymbalsSW, INPUT );
    digitalWrite( pCymbalsSW, HIGH ); // turn on internal pull-up
    
    pinMode( progVolumeSW, INPUT );
    digitalWrite( progVolumeSW, HIGH );  // turn on internal pull-up
    pinMode( progRandomSW, INPUT );
    digitalWrite( progRandomSW, HIGH );  // turn on internal pull-up
    pinMode( progPanSW, INPUT );
    digitalWrite( progPanSW, HIGH );  // turn on internal pull-up
    
    // turn on all leds and hold them high for 2 sec
    digitalWrite( tempoLED, HIGH );  
    digitalWrite( pKickLED, HIGH );
    digitalWrite( pSnareLED, HIGH );
    digitalWrite( pTomsLED, HIGH );
    digitalWrite( pCymbalsLED, HIGH );
    delay( 2000 );
    
    // read prog switches and set leds correctly
    pKick = digitalRead( pKickSW );
    digitalWrite( pKickLED, pKick );
    pSnare = digitalRead( pSnareSW );
    digitalWrite( pSnareLED, pSnare );
    pToms = digitalRead( pTomsSW );
    digitalWrite( pTomsLED, pToms );
    pCymbals = digitalRead( pCymbals );
    digitalWrite( pCymbalsLED, pCymbals );
  
    // ***************************************************************************
    Serial.print( "Prog Switches " );
    Serial.print( pKick, BIN );
    Serial.print( pSnare, BIN );
    Serial.print( pToms, BIN );
    Serial.print( pCymbals, BIN );
    
    // set tempo from tempoPot <-- yeah, it looks weird, but it gives a good range
    tempo = 2 * ( minTempo - analogRead( tempoPot ) );
    
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
        nextBeat = stepTime + tempo;
        
        digitalWrite( tempoLED, HIGH );
                
        // play beats for current step
        if( kPattern[ currentStep ] ){
            midiSend( NOTEON, KICK, 0x64 ); // note on channel 10, velocity 100
            delay( 20 );
            midiSend( NOTEOFF, KICK, 0x00 ); // note off channel 10
        }
        if( sPattern[ currentStep ] ){
            midiSend( NOTEON, SNARE, 0x64 ); // note on channel 10, velocity 100
            delay( 20 );
            midiSend( NOTEOFF, SNARE, 0x00 ); // note off channel 10
        }
        if( tPattern[ currentStep ] ){
            // toms pattern
        }
        if( cPattern[ currentStep ] ){
            // cymbals pattern
        }
        
        // increment step
        currentStep++;
        if( currentStep == 32 ){ // 32 steps in the pattern
            currentStep = 0;
        }
        tempoLEDoff = stepTime + 125;
    }
    
    if( stepTime > tempoLEDoff ){
        digitalWrite( tempoLED, LOW );
        tempoLEDoff += 5000; // set this above the next possible led off so we don't keep hammering it down.
    }
    
    if( stepTime > nextPoll ){
        // set time for next beat
        nextPoll = stepTime + pollInterval;
        
        // poll pattern inputs
        int kickPotRead = analogRead( kickPot );
        if( abs( kickPotRead - kickPotValue ) > 10 ){
            kickPotValue = kickPotRead;
            setKickPattern( kickPotValue );
        }
        
        // poll programming keys
        int pKickRead = digitalRead( pKickSW );
        if( pKick != pKickRead ){
            pKick = pKickRead;
            digitalWrite( pKickLED, pKick );
        }

        int pSnareRead = digitalRead( pSnareSW );
        if( pSnare != pSnareRead ){
            pSnare = pSnareRead;
            digitalWrite( pSnareLED, pSnare );
        }
        
        int pTomsRead = digitalRead( pTomsSW );
        if( pToms != pTomsRead ){
            pToms = pTomsRead;
            digitalWrite( pTomsLED, pToms );
        }
        
        int pCymbalsRead = digitalRead( pCymbals );
        if( pCymbals != pCymbalsRead ){
            pCymbals = pCymbalsRead;
            digitalWrite( pCymbalsLED, pCymbals );
        }
    
        // check and update tempo if needed  <-- yeah, it looks weird, but it gives a good range
        tempoCheck = 2 * ( minTempo - analogRead( tempoPot ) );
        if( abs( tempo - tempoCheck ) > 10 ){ 
            tempo = tempoCheck;
        }
    }
}  

//  Set the kick pattern
void setKickPattern( int patternValue ) {
    if( patternValue < 50 ){ // empty pattern
        for( int i = 0; i < 32; i++ ){
            kPattern[ i ] = 0;
        }
    }
    else if( patternValue < 250 ){
        for( int i = 0; i < 32; i++ ){
            if( i%8 == 0 ){ // hit every 8th beat
                kPattern[i] = 1;
            }
            else{
                kPattern[i] = 0;
            }
            if( random(1024) < kickRandomness ){  // applies randomness to each beat.
                kPattern[i] = !( kPattern[i] );  
            }
        }
    }
    else if( patternValue < 500 ){
        for( int i = 0; i < 32; i++ ){
            if( i%4 == 0 ){ // hit every 4th beat
                kPattern[i] = 1;
            }
            else{
                kPattern[i] = 0;
            }
            if( i > 23 ){  // only randomise the last 8 beats
                if( random(1024) < kickRandomness ){  // applies randomness to each beat.
                    kPattern[i] = !( kPattern[i] );  
                }
            }
        }
    }
    else{ // full pattern - hit on every beat
        for( int i = 0; i < 32; i++ ){
            kPattern[ i ] = 1;
            if( random(1024) < kickRandomness ){  // applies randomness to each beat.
                kPattern[i] = !( kPattern[i] );  
            }
        }
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
