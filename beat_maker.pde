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

// define remaining global constants
#define minTempo (1100)
#define pollInterval (75)

// define Global variables

// stored value of programming switches. these get defined in setup()
boolean pKick;
boolean pSnare;
boolean pToms;
boolean pCymbals;
boolean progVolume;
boolean progRandom;
boolean progPan;

// initial values of pattern pots. set at 1200 so that the polling routine will kick in.
int kickPotValue = 1200;
int snarePotValue = 1200;
int tomsPotValue = 1200;
int cymbalsPotValue = 1200;

// variables to store and control timing
int tempo = minTempo;  // int tempo doesn't really mean the tempo. It is the length of the pauses between beats.
unsigned long nextBeat;    // trigger time for next beat
unsigned long tempoCheck;  // used to monitor tempo pot
unsigned long nextPoll;    // trigger time for next input poll
unsigned long stepTime;    // stores the time at the start of the loop(). Eliminates multiple millis() calls.
unsigned long tempoLEDoff; // stores the trigger time for tempo LED to turn off

// variables related to drum patterns
int currentStep = 0;
byte kPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
byte sPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
byte tPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
byte cPattern[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

int kickRandomness = 0; 
int kickVolume = 100;        // volume and pan are midi values 0-127
int kickPan = 64;
int snareRandomness = 0;
int snareVolume = 100;
int snarePan = 64;
int tomsRandomness = 0;
int tomsVolume = 100;
int tomsPan = 64;
int cymbalsRandomness = 0;
int cymbalsVolume = 100;
int cymbalsPan = 64;

void setup() {
    //  Set MIDI baud rate:
    //Serial.begin( 31250 );
  
    //  Set serial link baud rate - for testing
    Serial.begin( 9600 );
    
    // set up led output pins
    pinMode( tempoLED, OUTPUT );
    pinMode( pKickLED, OUTPUT );
    pinMode( pSnareLED, OUTPUT );
    pinMode( pTomsLED, OUTPUT );
    pinMode( pCymbalsLED, OUTPUT );
    
    // turn on all leds and hold them high for 2 sec
    digitalWrite( tempoLED, HIGH );  
    digitalWrite( pKickLED, HIGH );
    digitalWrite( pSnareLED, HIGH );
    digitalWrite( pTomsLED, HIGH );
    digitalWrite( pCymbalsLED, HIGH );
    delay( 2000 );

    // read programming switches and set leds correctly
    pKick = digitalRead( pKickSW );
    digitalWrite( pKickLED, pKick );
    pSnare = digitalRead( pSnareSW );
    digitalWrite( pSnareLED, pSnare );
    pToms = digitalRead( pTomsSW );
    digitalWrite( pTomsLED, pToms );
    pCymbals = digitalRead( pCymbals );
    digitalWrite( pCymbalsLED, pCymbals );
    
    // set up input pins. Set mode as INPUT, and then use digtalWrite HIGH to turn on the internal pull-up resistors.
    pinMode( pKickSW, INPUT );
    digitalWrite( pKickSW, HIGH ); 
    pinMode( pSnareSW, INPUT );
    digitalWrite( pSnareSW, HIGH ); 
    pinMode( pTomsSW, INPUT );
    digitalWrite( pTomsSW, HIGH ); 
    pinMode( pCymbalsSW, INPUT );
    digitalWrite( pCymbalsSW, HIGH ); 
    pinMode( progVolumeSW, INPUT );
    digitalWrite( progVolumeSW, HIGH );  
    pinMode( progRandomSW, INPUT );
    digitalWrite( progRandomSW, HIGH ); 
    pinMode( progPanSW, INPUT );
    digitalWrite( progPanSW, HIGH ); 
    
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
        tempoLEDoff = stepTime + 125;
                
        // play beats for current step
        if( kPattern[ currentStep ] ){
            midiSend( NOTEON, KICK, 0x64 ); // note on channel 10, velocity 100
            delay( 20 );
            midiSend( NOTEOFF, KICK, 0x00 ); // note off channel 10
        }
        if( sPattern[ currentStep ] ){
            // 0 - no drum
            // 1 - snare
            // 2 - closed 
            // 3 - snare and close hh
            // 4 - open hh
            // 5 - snare and open hh
            switch( sPattern[ currentStep ] ){
                case 1:
                    midiSend( NOTEON, SNARE, 0x64 ); // note on channel 10, velocity 100
                    delay( 20 );
                    midiSend( NOTEOFF, SNARE, 0x00 ); // note off channel 10
                    break;
                case 2:
                    midiSend( NOTEON, HHCLOSED, 0x64 ); // note on channel 10, velocity 100
                    delay( 20 );
                    midiSend( NOTEOFF, HHCLOSED, 0x00 ); // note off channel 10
                    break;
                case 3:
                    midiSend( NOTEON, SNARE, 0x64 ); // note on channel 10, velocity 100
                    midiSend( NOTEON, HHCLOSED, 0x64 ); // note on channel 10, velocity 100
                    delay( 20 );
                    midiSend( NOTEOFF, SNARE, 0x00 ); // note off channel 10
                    midiSend( NOTEOFF, HHCLOSED, 0x00 ); // note off channel 10
                    break;
                case 4:
                    midiSend( NOTEON, HHOPEN, 0x64 ); // note on channel 10, velocity 100
                    delay( 20 );
                    midiSend( NOTEOFF, HHOPEN, 0x00 ); // note off channel 10
                    break;
                case 5:
                    midiSend( NOTEON, SNARE, 0x64 ); // note on channel 10, velocity 100
                    midiSend( NOTEON, HHOPEN, 0x64 ); // note on channel 10, velocity 100
                    delay( 20 );
                    midiSend( NOTEOFF, SNARE, 0x00 ); // note off channel 10
                    midiSend( NOTEOFF, HHOPEN, 0x00 ); // note off channel 10
                    break;
                default:
                    break;
            }
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
        
        int snarePotRead = analogRead( snarePot );
        if( abs( snarePotRead - snarePotValue ) > 10 ){
            snarePotValue = snarePotRead;
            setSnarePattern( snarePotValue );
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
        
        // poll programming inputs
        int progReadValue = analogRead( progPot );
        
        if ( digitalRead( progRandomSW ) ){   // set randomness
            if( pKick ){
                kickRandomness = progReadValue;
            }
            if( pSnare ){
                snareRandomness = progReadValue;
            }
            if( pToms ){
                tomsRandomness = progReadValue;
            }
            if( pCymbals ){
                cymbalsRandomness = progReadValue;
            }
        }
        
        if ( digitalRead( progVolumeSW ) ){   // set volume level to 0-127
            if( pKick ){
                kickVolume = ( ( progReadValue / 1024 ) * 127 );
            }
            if( pSnare ){
                snareVolume = ( ( progReadValue / 1024 ) * 127 );
            }
            if( pToms ){
                tomsVolume = ( ( progReadValue / 1024 ) * 127 );
            }
            if( pCymbals ){
                cymbalsVolume = ( ( progReadValue / 1024 ) * 127 );
            }
        }

        if ( digitalRead( progPanSW ) ){   // set pan level to 0-127
            if( pKick ){
                kickPan = ( ( progReadValue / 1024 ) * 127 );
            }
            if( pSnare ){
                snarePan = ( ( progReadValue / 1024 ) * 127 );
            }
            if( pToms ){
                tomsPan = ( ( progReadValue / 1024 ) * 127 );
            }
            if( pCymbals ){
                cymbalsPan = ( ( progReadValue / 1024 ) * 127 );
            }
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
    if( patternValue < 30 ){ // empty pattern
        for( int i = 0; i < 32; i++ ){
            kPattern[ i ] = 0;
        }
    }
    else if( patternValue < 100 ){
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
    else if( patternValue < 300 ){
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

//  Set the Snare pattern
void setSnarePattern( int patternValue ) {
    // 0 - no drum
    // 1 - snare
    // 2 - closed hh
    // 3 - snare and close hh
    // 4 - open hh
    // 5 - snare and open hh
    if( patternValue < 30 ){ // empty pattern
        for( int i = 0; i < 32; i++ ){
            sPattern[ i ] = 0;
        }
    }
    else if( patternValue < 100 ){
        for( int i = 0; i < 32; i++ ){
            if( i%8 == 0 ){ // hit every 8th beat
                sPattern[i] = 1;
            }
            else{
                sPattern[i] = 0;
            }
            if( random(1024) < snareRandomness ){  // applies randomness to each beat.
                sPattern[i] = !( sPattern[i] );  
            }
            // add random closed hh
            if( random( 512 ) < snareRandomness ){
                sPattern[i] = sPattern[i] + 2;
            }
        }
    }
    else if( patternValue < 300 ){
        for( int i = 0; i < 32; i++ ){
            if( i%4 == 0 ){ // hit every 4th beat
                sPattern[i] = 1;
            }
            else{
                sPattern[i] = 0;
            }
            if( i > 23 ){  // only randomise the last 8 beats
                if( random(1024) < snareRandomness ){  // applies randomness to each beat.
                    sPattern[i] = !( sPattern[i] );  
                }
            }
        }
    }
    else{ // full pattern - hit on every beat
        for( int i = 0; i < 32; i++ ){
            sPattern[ i ] = 1;
            if( random(1024) < snareRandomness ){  // applies randomness to each beat.
                sPattern[i] = !( sPattern[i] );  
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
