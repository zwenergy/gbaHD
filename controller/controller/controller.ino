// Pin definitions.
// GBA outputs.
// These definitions are just for reference. If other pins should be used,
// the updateGBASignals function needs to be adjusted.
#define DUP 2
#define DDOWN 3
#define DLEFT 4
#define DRIGHT 5
#define BUTA 6
#define BUTB 7
#define BUTL 8
#define BUTR 9
#define BUTSTART 10
#define BUTSELECT 11

// SNES controller.
#define SNESLATCH A0
#define SNESCLK A1
#define SNESSERIAL A2

// Communication port
#define COMPIN A3

// Polling interval in ms.
#define POLLINT 10

// Some NOP definitions.
// Yes, this is very pretty. But we do not have code size problems,
// hence using stupid sequences of NOPs makes it nicely timing 
// predictable.
#define NOP1 asm volatile( "nop\n" )
#define NOP5 NOP1; NOP1; NOP1; NOP1; NOP1
#define NOP10 NOP5; NOP5
#define NOP20 NOP10; NOP10
#define NOP40 NOP20; NOP20
#define NOP80 NOP40; NOP40

#define WAIT2US NOP20; NOP10; NOP1
#define WAIT8US NOP80; NOP40; NOP5; NOP1; NOP1; NOP1

// The latest controller state.
uint8_t conA;
uint8_t conB;
uint8_t conDUp;
uint8_t conDDown;
uint8_t conDLeft;
uint8_t conDRight;
uint8_t conL;
uint8_t conR;
uint8_t conStart;
uint8_t conSelect;

uint8_t gotCombo;


// Read the controller.
void readController() {
  // Set the latch to high for 12 us.
  digitalWrite( SNESLATCH, 1 );
  delayMicroseconds( 12 );
  digitalWrite( SNESLATCH, 0 );
  delayMicroseconds( 6 );

  // Init A and B.
  conB = 0;
  conA = 0;

  // Shift in the controller data.
  for ( uint8_t i = 0; i < 16; ++i ) {
    digitalWrite( SNESCLK, 0 );
    delayMicroseconds( 6 );
    // We only care about the first 12 bits.
    if ( i < 12 ) {
      uint8_t curDat = !digitalRead( SNESSERIAL );
      switch ( i ) {
        case 0:
          conB |= curDat;
          break;
        case 1:
          conB |= curDat;
          break;
        case 2:
          conSelect = curDat;
          break;
        case 3:
          conStart = curDat;
          break;
        case 4:
          conDUp = curDat;
          break;
        case 5:
          conDDown = curDat;
          break;
        case 6:
          conDLeft = curDat;
          break;
        case 7:
          conDRight = curDat;
          break;
        case 8:
          conA |= curDat;
          break;
        case 9:
          conA |= curDat;
          break;
        case 10:
          conL = curDat;
          break;
        case 11:
          conR = curDat;
          break;
        default:
          break;
        
      }
    }
    digitalWrite( SNESCLK, 1 );
    delayMicroseconds( 6 );
  }
}


// Drive GBA controller signals.
void updateGBASignals() {
  // In case a button is pressed, we pull the signal to ground.
  // Otherwise, we set it to high Z.
  // Since all output registers are already set to 0, we only need
  // to toggle the port direction.
  // Get D0 and D1 directions.
  uint8_t d1d0 = DDRD;
  d1d0 = d1d0 & 0b00000011;
  uint8_t dir = d1d0 | ( conDUp << 2 ) | ( conDDown << 3 ) | ( conDLeft << 4 ) |
    ( conDRight << 5 ) | ( conA << 6 ) | ( conB << 7 );
  // Write them.
  DDRD = dir;

  // The next ones.
  dir = ( conL ) | ( conR << 1 ) | ( conStart << 2 ) | ( conSelect << 3 );
  DDRB = dir; 
}

void setup() {
  // DEBUG.
  Serial.begin(9600);
  Serial.println( "Startup" );
  
  // Set up pin modes.
  // First set all output registers of GBA buttons to 0.
  pinMode( DUP, OUTPUT );
  digitalWrite( DUP, 0 );
  pinMode( DDOWN, OUTPUT );
  digitalWrite( DDOWN, 0 );
  pinMode( DLEFT, OUTPUT );
  digitalWrite( DLEFT, 0 );
  pinMode( DRIGHT, OUTPUT );
  digitalWrite( DRIGHT, 0 );
  pinMode( BUTA, OUTPUT );
  digitalWrite( BUTA, 0 );
  pinMode( BUTB, OUTPUT );
  digitalWrite( BUTB, 0 );
  pinMode( BUTL, OUTPUT );
  digitalWrite( BUTL, 0 );
  pinMode( BUTR, OUTPUT );
  digitalWrite( BUTR, 0 );
  pinMode( BUTSTART, OUTPUT );
  digitalWrite( BUTSTART, 0 );
  pinMode( BUTSELECT, OUTPUT );
  digitalWrite( BUTSELECT, 0 );

  // Then GBA pins are set to input to hold
  // them as high Z.
  pinMode( DUP, INPUT );
  pinMode( DLEFT, INPUT );
  pinMode( DRIGHT, INPUT );
  pinMode( DDOWN, INPUT );
  pinMode( BUTA, INPUT );
  pinMode( BUTB, INPUT );
  pinMode( BUTL, INPUT );
  pinMode( BUTR, INPUT );
  pinMode( BUTSTART, INPUT );
  pinMode( BUTSELECT, INPUT );

  // And the SNES controller pins.
  pinMode( SNESLATCH, OUTPUT );
  digitalWrite( SNESLATCH, 0 );
  pinMode( SNESCLK, OUTPUT );
  digitalWrite( SNESCLK, 1 );
  pinMode( SNESSERIAL, INPUT_PULLUP );

  // Communication pin.
  pinMode( COMPIN, OUTPUT );
  digitalWrite( COMPIN, 1 );

}

void sendPacket( uint8_t p ) {
  uint8_t curPort = PINC;
  for ( uint8_t i = 0; i < 8; ++i ) {
    uint8_t curBit = p & ( 1 << i );
    if ( curBit ) {
      curPort &= B11110111;
      PORTC = curPort;
      WAIT2US;
      curPort |= B00001000;
      PORTC = curPort;
      WAIT8US;
    } else {
      curPort &= B11110111;
      PORTC = curPort;
      WAIT8US;
      curPort |= B00001000;
      PORTC = curPort;
      WAIT2US;
    }
  }
}

void noButtons() {
  conA = 0;
  conB = 0;
  conDUp = 0;
  conDDown = 0;
  conDLeft = 0;
  conDRight = 0;
  conR = 0;
  conL = 0;
  conStart = 0;
  conSelect = 0;
}

uint8_t showOSD = 0;

void loop() {
  readController();

  // Button combination L+R+SELECT+RIGHT send a communcation pulse.
  if ( conSelect && conL && conR && conDRight ) {
    if ( gotCombo == 0 ) {
      showOSD = !showOSD;
      gotCombo = 1;

      // Set the buttons to off once.
      noButtons();
      updateGBASignals();
    }
  } else if ( gotCombo == 1 ) {
    gotCombo = 0;
  }

  // Only update GBA signals if the menu is not active.
  if ( !showOSD ) {
    updateGBASignals();  
  }

  // Prepare packet to send.
  uint8_t packet = ( conB << 7 ) | ( conA << 6 ) | ( conDLeft << 5 ) | ( conDRight << 4 ) | ( conDDown << 3 ) | ( conDUp << 2 ) | ( showOSD << 1 );
  sendPacket( packet );

  delay( POLLINT );

}
