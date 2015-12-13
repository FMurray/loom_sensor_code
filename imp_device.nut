// My version 1.3 of BME280 code
// I'm pretty sure temp and humidity are working 
// (although the math for humidity may need to be reviewed again)
// Gets the temp; pressure and humidity from BME280 over i2c


//these Registurs are lifted from Adafruit_BME280.h. There they use enum() 

const	   BME280_ADDRESS					   = 0x77;

const BME280_DIG_T1_LSB_REG			= "\x88";
const BME280_DIG_T1_MSB_REG			="\x89";
const BME280_DIG_T2_LSB_REG			="\x8A";
const BME280_DIG_T2_MSB_REG			="\x8B";
const BME280_DIG_T3_LSB_REG			="\x8C";
const BME280_DIG_T3_MSB_REG			="\x8D";
const BME280_DIG_P1_LSB_REG			="\x8E";
const BME280_DIG_P1_MSB_REG			="\x8F";
const BME280_DIG_P2_LSB_REG			="\x90";
const BME280_DIG_P2_MSB_REG			="\x91";
const BME280_DIG_P3_LSB_REG			="\x92";
const BME280_DIG_P3_MSB_REG			="\x93";
const BME280_DIG_P4_LSB_REG			="\x94";
const BME280_DIG_P4_MSB_REG			="\x95";
const BME280_DIG_P5_LSB_REG			="\x96";
const BME280_DIG_P5_MSB_REG			="\x97";
const BME280_DIG_P6_LSB_REG			="\x98";
const BME280_DIG_P6_MSB_REG			="\x99";
const BME280_DIG_P7_LSB_REG			="\x9A";
const BME280_DIG_P7_MSB_REG			="\x9B";
const BME280_DIG_P8_LSB_REG			="\x9C";
const BME280_DIG_P8_MSB_REG			="\x9D";
const BME280_DIG_P9_LSB_REG			="\x9E";
const BME280_DIG_P9_MSB_REG			="\x9F";
const BME280_DIG_H1_REG				="\xA1";
const BME280_DIG_H2_LSB_REG			="\xE1";
const BME280_DIG_H2_MSB_REG			="\xE2";
const BME280_DIG_H3_REG				="\xE3";
const BME280_DIG_H4_MSB_REG			="\xE4";
const BME280_DIG_H4_LSB_REG			="\xE5";
const BME280_DIG_H5_MSB_REG			="\xE6";
const BME280_DIG_H6_REG				="\xE7";

// register command values are supposed to be "\x00" formatted according to TSL2561 example
const      BME280_REGISTER_SOFTRESET          = "\xE0";
const      BME280_REGISTER_CAL26              = "\xE1";  // R calibration stored in 0xE1-0xF0
const      BME280_REGISTER_CONTROLHUMID       = "\xF2";
const      BME280_CTRL_MEAS_REG               = "\xF3";
const      BME280_REGISTER_CHIPID             = "\xD0";
const      BME280_REGISTER_CONTROL            = "\xF4";
const      BME280_CONFIG_REG                  = "\xF5";
const      BME280_PRESSURE_MSB_REG    = "\xF7";
const      BME280_PRESSURE_LSB_REG    = "\xF8";
const      BME280_PRESSURE_XLSB_REG   = "\xF9";
const      BME280_TEMPERATURE_MSB_REG        = "\xFA";
const      BME280_TEMPERATURE_LSB_REG        = "\xFB";
const      BME280_TEMPERATURE_XLSB_REG       = "\xFC";
const      BME280_HUMIDITY_MSB_REG          = "\xFD";
const      BME280_HUMIDITY_LSB_REG			 = "\xFE";

const TSL2561_COMMAND_BIT = "\x80";         // Command register. Bit 7 must be 1
const TSL2561_CONTROL_POWERON = "\x03";     // Power on setting
const TSL2561_CONTROL_POWEROFF = "\x00";    // Power off setting
const TSL2561_REGISTER_TIMING = "\x81";     // Access timing register
const TSL2561_REGISTER_ADC0_LSB = "\xAC";   // LSB of sensor's two-byte ADC value
const TSL2561_REGISTER_ADC1_LSB = "\xAE";   // LSB of sensor's two-byte ADC value
const TSL2561_GAIN_LOW_INT_10 = "\x01";     // Gain to low, integration timing to 101ms
const TSL2561_GAIN_LOW_INT_13 = "\x00";     // Gain to low, integration timing to 13.7ms
const TSL2561_GAIN_HI_INT_10 = "\x11";     // Gain to low, integration timing to 101ms
const TSL2561_GAIN_HI_INT_13 = "\x10";     // Gain to low, integration timing to 13.7ms

// Note: Imp i2c_lux address values are integers

const TSL2561_ADDR_LOW = 0x29;              // ADDR pin ground
const TSL2561_ADDR_HIGH = 0x49;             // ADDR pin 3v3
const TSL2561_ADDR_FLOAT = 0x39;            // ADDR pin floating

// Lux calculation constants

const LUX_SCALE = 14;                       // scale by 2^14        
const RATIO_SCALE = 9;                      // scale ratio by 2^9

const B1C = 0x0204;
const M1C = 0x01ad;
const B2C = 0x0228;
const M2C = 0x02c1;
const B3C = 0x0253;
const M3C = 0x0363;
const B4C = 0x0282;
const M4C = 0x03df;
const B5C = 0x0177;
const M5C = 0x01dd;
const B6C = 0x0101;
const M6C = 0x0127;
const B7C = 0x0037;
const M7C = 0x002b;
const B8C = 0x0000;
const M8C = 0x0000;
const K1C = 0x0043;
const K2C = 0x0085;
const K3C = 0x00c8;
const K4C = 0x010a;
const K5C = 0x014d;
const K6C = 0x019a;
const K7C = 0x029a;
const K8C = 0x029a;

t_fine <- 0.00;

function write8(REG_ADDR, REG_VAL) {
	i2c.write(i2cAddr, REG_ADDR);
	i2c.write(i2cAddr, REG_VAL);
}

function read16(REG_ADDR) {
	//server.log("I2C read error: " + i2c.readerror());
    local word = i2c.read(i2cAddr, REG_ADDR, 2);
    // local intVal = hexStringToInt(word);
    // server.log("intVal =" + intVal);
    local REG_VAL = (word[0] << 8) + word[1];
    //server.log(REG_VAL);
    return REG_VAL;
}

// read16 little endian
function read16_LE(REG_ADDR) {
	//server.log("I2C read error: " + i2c.readerror());
    local word = i2c.read(i2cAddr, REG_ADDR, 2);
    // local intVal = hexStringToInt(word);
    // server.log("intVal =" + intVal);
    local REG_VAL = (word[1] << 8 ) + word[0];
    //server.log(REG_VAL);
    return REG_VAL;
}

function read8(REG_ADDR) {
	//server.log("I2C read error: " + i2c.readerror());
    local word = i2c.read(i2cAddr, REG_ADDR, 1);
    // local intVal = hexStringToInt(word);
    // server.log("intVal =" + intVal);
    local REG_VAL = word[0];
    //server.log(REG_VAL);
    return REG_VAL;
}

function begin(){
	dig_T1 <- (((read8(BME280_DIG_T1_MSB_REG) << 8) + read8(BME280_DIG_T1_LSB_REG)));
	dig_T2 <- (((read8(BME280_DIG_T2_MSB_REG) << 8) + read8(BME280_DIG_T2_LSB_REG)));
	dig_T3 <- (((read8(BME280_DIG_T3_MSB_REG) << 8) + read8(BME280_DIG_T3_LSB_REG)));

	dig_P1 <- (((read8(BME280_DIG_P1_MSB_REG) << 8) + read8(BME280_DIG_P1_LSB_REG)));
	dig_P2 <- (((read8(BME280_DIG_P2_MSB_REG) << 8) + read8(BME280_DIG_P2_LSB_REG)));
	dig_P3 <- (((read8(BME280_DIG_P3_MSB_REG) << 8) + read8(BME280_DIG_P3_LSB_REG)));
	dig_P4 <- (((read8(BME280_DIG_P4_MSB_REG) << 8) + read8(BME280_DIG_P4_LSB_REG)));
	dig_P5 <- (((read8(BME280_DIG_P5_MSB_REG) << 8) + read8(BME280_DIG_P5_LSB_REG)));
	dig_P6 <- (((read8(BME280_DIG_P6_MSB_REG) << 8) + read8(BME280_DIG_P6_LSB_REG)));
	dig_P7 <- (((read8(BME280_DIG_P7_MSB_REG) << 8) + read8(BME280_DIG_P7_LSB_REG)));
	dig_P8 <- (((read8(BME280_DIG_P8_MSB_REG) << 8) + read8(BME280_DIG_P8_LSB_REG)));
	dig_P9 <- (((read8(BME280_DIG_P9_MSB_REG) << 8) + read8(BME280_DIG_P9_LSB_REG)));

	dig_H1 <- ((read8(BME280_DIG_H1_REG)));
	dig_H2 <- (((read8(BME280_DIG_H2_MSB_REG) << 8) + read8(BME280_DIG_H2_LSB_REG)));
	dig_H3 <- ((read8(BME280_DIG_H3_REG)));
	dig_H4 <- (((read8(BME280_DIG_H4_MSB_REG) << 4) + (read8(BME280_DIG_H4_LSB_REG) & 0x0F)));
	dig_H5 <- (((read8(BME280_DIG_H5_MSB_REG) << 4) + ((read8(BME280_DIG_H4_LSB_REG) >> 4) & 0x0F)));
	dig_H6 <- (read8(BME280_DIG_H6_REG));    

	//Set the oversampling control words.
	//config will only be writeable in sleep mode, so first insure that.
	i2c.write(i2cAddr, BME280_CTRL_MEAS_REG + "\x00");
	
	//Set the config word
	local dataToWrite = (0 << 0x5) & 0xE0;
	dataToWrite = dataToWrite | (0 << 0x02) & 0x1C;
	i2c.write(i2cAddr, BME280_CONFIG_REG + dataToWrite);
	
	//Set ctrl_hum first, then ctrl_meas to activate ctrl_hum
	dataToWrite = 1 & 0x07; //all other bits can be ignored
	i2c.write(i2cAddr, BME280_REGISTER_CONTROLHUMID + dataToWrite);
	
	//set ctrl_meas
	//First, set temp oversampling
	dataToWrite = (1 << 0x5) & 0xE0;
	//Next, pressure oversampling
	dataToWrite = dataToWrite | (1 << 0x02) & 0x1C;
	//Last, set mode
	dataToWrite = dataToWrite| (3) & 0x03;
	//Load the byte
	i2c.write(i2cAddr, BME280_CTRL_MEAS_REG + dataToWrite);
	

}

function readTemperature() {

// Returns temperature in DegC, resolution is 0.01 DegC. Output value of “5123” equals 51.23 DegC.
	// t_fine carries fine temperature as global value

	//get the reading (adc_T);
    local adc_T = (read8(BME280_TEMPERATURE_MSB_REG) << 12) | (read8(BME280_TEMPERATURE_LSB_REG) << 4) | ((read8(BME280_TEMPERATURE_XLSB_REG) >> 4) & 0x0F);

	local var1, var2;
	
	var1 = ((((adc_T>>3) - (dig_T1<<1))) * (dig_T2)) >> 11;
    var2 = (((((adc_T>>4) - (dig_T1)) * ((adc_T>>4) - (dig_T1))) >> 12) *
	(dig_T3)) >> 14;

	::t_fine = var1 + var2;
    local t = (t_fine * 5 + 128) >> 8;
    local cast = t.tofloat();
    cast = cast / 100;
    cast = (cast * 9) / 5 + 32;
    server.log("temp:" + cast);
    return cast;
}

function readHumidity() {

	// Returns humidity in %RH as unsigned 32 bit integer in Q22. 10 format (22 integer and 10 fractional bits).
	// Output value of “47445” represents 47445/1024 = 46. 333 %RH
	local adc_H = (read8(BME280_HUMIDITY_MSB_REG) << 8) | (read8(BME280_HUMIDITY_LSB_REG));
	
	local var1;
	var1 = (::t_fine - (76800));
	var1 = (((((adc_H << 14) - ((dig_H4) << 20) - ((dig_H5) * var1)) +
	(16384)) >> 15) * (((((((var1 * (dig_H6)) >> 10) * (((var1 * (dig_H3)) >> 11) + (32768))) >> 10) + (2097152)) *
	(dig_H2) + 8192) >> 14));
	var1 = (var1 - (((((var1 >> 15) * (var1 >> 15)) >> 7) * (dig_H1)) >> 4));
	var1 = (var1 < 0 ? 0 : var1);
	var1 = (var1 > 419430400 ? 419430400 : var1);
	
	local hum = ((var1>>12) >> 10);
	local output = hum.tofloat();
    server.log("humidity = " + output);
	return output;
}

function readPressure() {

local adc_P = (read8(BME280_PRESSURE_MSB_REG) << 12) | (read8(BME280_PRESSURE_LSB_REG) << 4) | ((read8(BME280_PRESSURE_XLSB_REG) >> 4) & 0x0F);

server.log("adc_P = " + adc_P);

local var1, var2, p_acc, p;
var1 = (::t_fine) - 64000;
server.log("t_fine = " + ::t_fine);
var2 = var1 * var1 * dig_P6;
var2 = (((var1>>2) * (var1>>2)) >> 11 ) * dig_P6;
server.log("var 2 " + var2);
var2 = var2 + ((var1*dig_P5)<<1);
var2 = (var2>>2)+(dig_P4<<16);
var1 = (((dig_P3 * (((var1>>2) * (var1>>2)) >> 13 )) >> 3) + (((dig_P2) * var1)>>1))>>18;

var1 =((((32768+var1))*(dig_P1))>>15);
if (var1 == 0)
{
return 0; // avoid exception caused by division by zero
}
p = ((((1048576)-adc_P)-(var2>>12)))*3125;

if (p < 0x80000000)
{
p = (p << 1) / var1;
}
else
{
p = (p / var1) * 2;
}

var1 = ((dig_P9) * ((((p>>>3) * (p>>>3))>>>13)))>>>12;
var2 = (((p>>>2)) * (dig_P8))>>>13;
p = (p + ((var1 + var2 + dig_P7) >> 4));

p_acc = p >>> 8; // /256
p_acc = p_acc.tofloat();
server.log("pressure = " + p_acc);
return p_acc;
}

function calculateLux(ch0, ch1) {
	// Calculate the luminosity based on ADC Channel 0 (visible + IR) and 
	// Channel 1 (IR) values. Returns the luminosity. Assumes sensor 
	// integration time is 13ms, gain is 16x
	
	local chScale = 29975;
	local channel0 = (ch0 * chScale) >> 10;
	local channel1 = (ch1 * chScale) >> 10;
	local ratio1 = 0;
	
	if (channel0 != 0) ratio1 = (channel1 << (RATIO_SCALE + 1)) / channel0;
	
	// Round the ratio value
	local ratio = (ratio1 + 1) >> 1;
	local b = 0;
	local m = 0;
	
	if ((ratio >= 0) && (ratio <= K1C))
	{b=B1C; m=M1C;}
	else if (ratio <= K2C)
	{b=B2C; m=M2C;}
	else if (ratio <= K3C)
	{b=B3C; m=M3C;}
	else if (ratio <= K4C)
	{b=B4C; m=M4C;}	
	else if (ratio <= K5C)
	{b=B5C; m=M5C;}
	else if (ratio <= K6C)
	{b=B6C; m=M6C;}
	else if (ratio <= K7C)
	{b=B7C; m=M7C;}	
	else if (ratio > K8C)
	{b=B8C; m=M8C;}
	
	local temp = ((channel0 * b) - (channel1 * m));
	
	// Do not allow a negative lux value
	if (temp < 0) temp = 0;
	temp += (1 << (LUX_SCALE - 1));
	
	// Strip off fractional portion
	local lux = temp >> LUX_SCALE;
	return lux;
}

function readSensorAdc0() {
    // server.log("i2c_lux read error: " + i2c_lux.readerror());
    local word = i2c_lux.read(i2c_luxAddr, TSL2561_REGISTER_ADC0_LSB, 2);
    local lumo = (word[1] << 8) + word[0];
    return lumo;
}

function readSensorAdc1() {
    local word = i2c_lux.read(i2c_luxAddr, TSL2561_REGISTER_ADC1_LSB, 2);
    local lumo = (word[1] << 8) + word[0];
    return lumo;
}

function getLumo(boolValue) {
    if (boolValue) {
        // Set command focus to ADC 0
        i2c_lux.write(i2c_luxAddr, TSL2561_REGISTER_ADC0_LSB);
        local lumo0 = readSensorAdc0();
        server.log("Light level: " + lumo0);
        
        i2c_lux.write(i2c_luxAddr, TSL2561_REGISTER_ADC1_LSB);
        local lumo1 = readSensorAdc1();
        server.log("IR level: " + lumo1);
        
        local lux = calculateLux(lumo0, lumo1);
        server.log("Lux: " + lux);
        // local data = { "Light level: ": lumo0, "IR Level: ": lumo1, "Lux: ": lux}
        // agent.send("sendData", data);
    }
}

function readSensors() {
    local lumo0 = readSensorAdc0();
    local lumo1 = readSensorAdc1();
    // readTemperature();
    // readHumidity();
    // calculateLux(lumo0, lumo1);
    local data = { "sensorId": 1, "timestamp": time(), 
    "temp": readTemperature(), "humidity": readHumidity(), 
    "lux": calculateLux(lumo0, lumo1)};
    agent.send("senddata", data);
}

waterLow <- hardware.pin1;
waterMed <- hardware.pin2;
waterHigh <- hardware.pin5;

waterLow.configure(ANALOG_IN);
waterMed.configure(ANALOG_IN);
waterHigh.configure(ANALOG_IN);

function poll()   {
    low <- waterLow.read();
    med <- waterMed.read();
    high <- waterHigh.read();
    // server.log("low val " + low);
    // server.log("med val " + med);
    // server.log("high val " + high);
    
    if((high < 1000) && (med < 1000) && (low < 1000)) {
        server.log ("the reservoir is full!");
    }
    
    if((high > 1000) && (med < 1000) && (low < 1000)) {
        server.log ("the reservoir is half full")
    }
    
    if((high > 1000) && (med > 1000) && (low < 1000)) {
        server.log ("the reservoir is low!")
    }
    
    if((high > 1000) && (med > 1000) && (low > 1000)) {
        server.log ("the reservoir is empty!")
    }


}


// Set up alias for i2c and set bus to 100kHz
i2c <- hardware.i2c89;
i2c.configure(CLOCK_SPEED_10_KHZ);
i2c_lux <- hardware.i2c89;
i2c_lux.configure(CLOCK_SPEED_100_KHZ);

// Set sensor's address by shifting 7-bit address 1 bit leftward as per imp I2C spec
i2cAddr <- BME280_ADDRESS << 1;
i2c_luxAddr <- TSL2561_ADDR_FLOAT << 1;                                

// Set command focus to the control register
i2c.write(i2cAddr, BME280_REGISTER_CONTROL); 
i2c_lux.write(i2c_luxAddr, TSL2561_COMMAND_BIT);  
write8(BME280_REGISTER_CONTROL, "\x3F");
// write8(BME280_REGISTER_CONTROLHUMID, "\x03");
i2c.write(i2cAddr, BME280_REGISTER_CONTROL);
local result = i2c.write(i2cAddr, BME280_REGISTER_CONTROL + "\x3F");
i2c_lux.write(i2c_luxAddr, TSL2561_CONTROL_POWERON);

// Issue command: write (0x80) to the timing register (0x01)
// ie. TSL2561_REGISTER_TIMING = 0x81
i2c_lux.write(i2c_luxAddr, TSL2561_REGISTER_TIMING);

// Set gain to low by writing a byte to the timing register
// bit 4 to the gain: 1 or 0 (gain high or low)
// bits 1,0 to the integration timing: 0,0 or 1,0 (timing 13.7ms or 101ms)
i2c_lux.write(i2c_luxAddr, TSL2561_GAIN_LOW_INT_10);


begin();

readSensors();
// readTemperature();
// readHumidity();
// // readPressure();
// getLumo(true);
// poll();

imp.onidle(function(){ server.sleepfor(3600); });


