const int LED_LEFT = D1;
const int LED_RIGHT = D0;
const int FREQ_CAM = 30; // FPS
const int CYCLES = 4; // 4
const int SYNC_OFFSET = 9.01111119; // Oneplus camera: 12µs, OpenCamera: 16µs, Canon EOS 1100D: 11µs, Logitech C920: 42µs, iPhone11: 9.0111111119

bool sync_left = false;
bool sync_right = false;

//String bitstring = "11111111111111111111111111111111";
//String bitstring = "11001100110011001100110011001100";
//String bitstring = "00000000000000000000000000000000";
//String bitstring = "0101010001100101011100110111010000100000"; //ASCI: Test 
//String bitstring = "0101010001100101011100110111010000100000010101000110010101110011011101000010000001010100011001010111001101110100001000000101010001100101011100110111010000100000"; //ASCI: Test Test Test Test 
//String bitstring = "0101011001100101011100100110100101100110011010010110001101100001011101000110100101101111011011100010000001000011011011110110010001100101"; //ASCI: Verification Code
String bitstring = "0100000101110101011101000110111101101101011011110111010001101001011101100110010100100000010000110110111101101101011100000111010101110100011010010110111001100111"; //ASCI: Automotive Computing
int shift = 0;

void setup() {
  pinMode(LED_LEFT, OUTPUT);
  pinMode(LED_RIGHT, OUTPUT);

  //bitstring = convertToBitString("Test");
}

void loop() {
  nextBits();  
  modulate_frame();
}

String convertToBitString(String text) {
  String bitString = "";  // Initialize the bit string
  for (int i = 0; i < text.length(); i++) {
    char c = text[i];
    for (int bit = 7; bit >= 0; bit--) {
      if (c & (1 << bit)) {  // Check if the bit is 1
        bitString += "1";
      } else {
        bitString += "0";
      }
    }
  }
  return bitString;
}

void nextBits(){
  //left
  int next = bitstring.charAt(shift) == '0' ? 0 : 1;
  shift = ++shift % bitstring.length();
  if(next == 1){
    sync_left = !sync_left;
  } else {
    sync_left = sync_left;
  }  
  //right
  next = bitstring.charAt(shift) == '0' ? 0 : 1;
  shift = ++shift % bitstring.length();
  if(next == 1){
    sync_right = !sync_right;
  } else {
    sync_right = sync_right;
  }  
}

void modulate_frame() {
  for (int i = 0; i <= CYCLES; i++) {
    if (sync_left) {
      digitalWrite(LED_LEFT, HIGH);
    } else {
      digitalWrite(LED_LEFT, LOW);
    }
    if (sync_right) {
      digitalWrite(LED_RIGHT, HIGH);
    } else {
      digitalWrite(LED_RIGHT, LOW);
    }

    if (i == 0 || i == CYCLES) {
      delayMicroseconds(500000 / (FREQ_CAM * CYCLES * 2) - SYNC_OFFSET);
    } else {
      delayMicroseconds(500000 / (FREQ_CAM * CYCLES) - SYNC_OFFSET);
    }

    if (i < CYCLES) {
      if (sync_left) {
        digitalWrite(LED_LEFT, LOW);
      } else {
        digitalWrite(LED_LEFT, HIGH);
      }
      if (sync_right) {
        digitalWrite(LED_RIGHT, LOW);
      } else {
        digitalWrite(LED_RIGHT, HIGH);
      }

      delayMicroseconds(500000 / (FREQ_CAM * CYCLES) - SYNC_OFFSET);
    }
  }
}
