/*

    Rotilio Thermo
    by techmakers srl
    
    Step: 01

*/

bool    heaterOn    = true  ;    // running mode
double  T           = 0.0   ;    // temperature from sensor °C
double  Ts          = 18.0  ;    // temperature setup °C
int     period      = 30000 ;    // milliseconds between each loop
int     relaisAorB  = 0     ;    // relais position: A=1, B=0, default B

void setup(){
	pinMode(D3,OUTPUT);
	pinMode(D4,OUTPUT);
	Wire.begin();
}

void loop(){
	
	T = readTemperatureFromSensor() ;  // acquire actual temperature
	
	if (heaterOn && T < Ts) {
		relaisAorB = 1 ;       // actual temperature lower than desired, enable heating system
	} else {
		relaisAorB = 0 ;       // actual temperature ok, disable heating system
	}
	
	if (relaisAorB == 1) {
		relaisSet();           // switch relais to position A
	} else {
		relaisReset();         // switch ralais to position B
	}
	
	delay(period);            // wait for the next cycle
	
}

void relaisSet(){
	digitalWrite(D4,HIGH);    // set PIN D4 high
	delay(100);
	digitalWrite(D4,LOW);     // set PIN D4 low
}

void relaisReset(){
	digitalWrite(D3,HIGH);    // set PIN D3 high
	delay(100);
	digitalWrite(D4,LOW);     // set PIN D3 low
}

int readRawDataFromI2C(int address,int command){

	// send read command to sensor over I2C bus
	Wire.beginTransmission(address);
	Wire.write(command);
	Wire.endTransmission();	
	
	// wait some time to let the sensor sense
	delay(20);
	
	// read three bytes from sensor
	Wire.requestFrom(address, 3);
	
	// compose a 16 bit value from 2 (msb and lsb) received bytes
	unsigned char msb = Wire.read();
	unsigned char lsb = Wire.read();
	unsigned char chk = Wire.read(); // checksum, not used
	int data = (((int) msb<<8) + (int) lsb);
	
	return data ;
}

#define Si7020_ADDRESS              0x40
#define TEMPERATURE_READ_COMMAND    0xF3

double readTemperatureFromSensor(void){

	// read raw data from temperature sensor Si7020
	int data = readRawDataFromI2C(Si7020_ADDRESS, TEMPERATURE_READ_COMMAND);
	
	// convert raw data in celsius degrees
    double celsiusdegree = 175.72 * data / 65536 - 46.85;
    
    // round to first decimal
    double roundedcelsiusdegree = round(celsiusdegree*10)/10 ;
    
    return roundedcelsiusdegree ;
}