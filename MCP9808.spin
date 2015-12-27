{
MCP9808 Digital Temperature Sensor
J.R. Leeman
kd5wxb@gmail.com

This is a thorough driver for the Microchip MCP9808 that encompasses most of the
useful functionality of this high-precision temperature sensor chip. An example of
using the driver is available and the code is thoroughly documented.

Resolution settings

| Resolution | tconv (ms) | sps |  
|  +0.5 C    |     30     | 33  |
|  +0.25 C   |     65     | 15  |
|  +0.1255 C |     130    | 7   |  
|  +0.0625 C |     250    | 4   |  

TODO:
- Possibly improve setting temps by doing the 2's compliment for the user
- Ensure that temperature values are correct
- Spell check and optimize where possible
- Abort trapping
}

CON

ConfigReg = $01
AltUpReg = $02
AltLowReg = $03
TempCritReg = $04
TempReg = $05
MfgIdReg = $06
DevIdReg = $07
ResReg = $08

VAR
  word started
  byte DevAdr

OBJ
  I2C : "I2C SPIN driver v1.4od"

PUB start(adr, data_pin, clk_pin)
  DevAdr := adr
  I2C.init(clk_pin, data_pin)
  started ~~ 'Flag that sensor startup has been completed

PUB getTempC : temp | upper,lower
  ' Read ambient temperature register
  ' bit 15 -> 1 if Ta >= Tcrit, 0 otherwise
  ' bit 14 -> 1 if Ta > Tupper, 0 otherwise
  ' bit 13 -> 1 if Ta < Tlower, 0 otherwise
  ' bit 12 -> 1 if Ta < 0C, 0 if Ta >= 0C
  ' bit 11-0 -> 12 bit temperature value in two's compliment format
  temp := I2C.readWordB(DevAdr, TempReg)
  temp := temp & ($FFF) 'Mask out everything but the last 12 bits
  upper := temp & ($FF00)
  lower := temp & ($00FF)

  temp := (upper >> 4 + lower << 4)

  if (temp & $1000)
    temp := 256 - temp

PUB getAlerts : alerts | temp
  ' Read ambient temperature register, parses out the alerts
  ' and returns the results
  ' bit 15 -> 1 if Ta >= Tcrit, 0 otherwise
  ' bit 14 -> 1 if Ta > Tupper, 0 otherwise
  ' bit 13 -> 1 if Ta < Tlower, 0 otherwise
  temp := I2C.readWordB(DevAdr, TempReg)
  alerts := (temp & $E000) >> 13

PUB readWordReg(reg)
  RESULT := I2C.readWordB(DevAdr, reg)

PUB readByteReg(reg)
  RESULT := I2C.readByte(DevAdr, reg)
  
PUB setTempHigh(limit)
  ' Sets the upper temperature alert limit
  ' Alerts if temperature > limit
  I2C.writeWordB(DevAdr, AltUpReg, limit)

PUB setTempLow(limit)
  ' Sets the lower temperature alert limit
  ' Alerts if temperature < limit
  I2C.writeWordB(DevAdr, AltLowReg, limit)

PUB setTempCrit(limit)
  ' Sets the critical temperature limit
  ' Alerts if temperature >= limit
  I2C.writeWordB(DevAdr, TempCritReg, limit)

PUB getTempHigh : limit
  ' Gets the upper temperature alert limit
  limit := I2C.readWordB(DevAdr, AltUpReg)
  limit := limit << 16
  limit := limit ~> 16

PUB getTempLow : limit
  ' Gets the lower temperature alert limit
  limit := I2C.readWordB(DevAdr, AltLowReg)
  limit := limit << 16
  limit := limit ~> 16

PUB getTempCrit : limit
  ' Gets the critical temperature limit
  limit := I2C.readWordB(DevAdr, TempCritReg)
  limit := limit << 16
  limit := limit ~> 16

PUB getMfgId : id
  ' Gets the manufacturer ID from the chip
  ' Should be 0x0054
  id := I2C.readWordB(DevAdr, MfgIdReg)

PUB getDevId : id
  ' Gets the device ID from the chip
  ' Should be 0x0400
  id := I2C.readWordB(DevAdr, DevIdReg)

PUB setTHyst(value) : mask
  ' Sets the device hysteresis value
  ' 00 -> 0 C (default)
  ' 01 -> +1.5 C
  ' 10 -> +3.0 C
  ' 11 -> +6.0 C
  ' Can be programmed in shutdown
  ' Cannot be programmed with either lock bit set
  mask := %0000_0110_0000_0000
  value := value << 9
  changeRegister(ConfigReg, mask, value)

PUB shutdown(status) | value, mask
  ' Shuts down device, reading and writing still enabled,
  ' but no power consuming activities running. Cannot be
  ' set with lock bits set, but can be cleared.
  mask := %0000_0001_0000_0000
  value := status << 8
  changeRegister(ConfigReg, mask, value)

PUB TcritLock | value, mask
  ' Unlocked (0), Tcrit register can be written. Tcrit register
  ' cannot be written when locked (1). Lock is cleared by an internal reset.
  ' Can be programmed in shutdown mode
  mask := %0000_0000_1000_0000
  value := %1000_0000
  changeRegister(ConfigReg, mask, value)

PUB WinLock | value, mask
  ' Unlocked (0), Tupper and Tlower registers can be written.
  ' Cannot be written when locked (1). Lock is cleared by
  ' a power on reset.
  ' Can be programmed in shutdown mode
  mask := %0000_0000_0100_0000
  value := %0100_0000
  changeRegister(ConfigReg, mask, value)

PUB IntClear | value, mask
  ' Interrupt clear bit
  ' (0) - No effect (default)
  ' (1) - Clear interrupt output; when read returns to 0
  ' Bit can not be set in shutdown mode, but could be cleared in shutdown mode
  ' Here we always set it, not sure why the clearing would be very useful.
  mask := %0000_0000_0010_0000
  value := %0000_0000_0010_0000
  changeRegister(ConfigReg, mask, value)

PUB getAlertStatus : status | mask
  ' Read Alert Output Status Bit
  ' (0) - Alert output is not asserted by the device (default)
  ' (1) - Alert output is asserted
  ' Cannot be set or cleared in shutdown mode
  status := I2C.readWordB(DevAdr, ConfigReg)
  mask := %0000_0000_0001_0000
  status := status & mask
  status := status >> 4

PUB alertControl(status) | value, mask
  ' Alert Output Control Bit
  ' (0) - Disabled (default)
  ' (1) - Enabled
  ' Cannot be altered when any lock bits are set
  ' Can be altered in shutdown mode. but will not assert
  mask := %0000_0000_0000_1000
  value := status << 3
  changeRegister(ConfigReg, mask, value)

PUB alertSelect(status) | value, mask
  ' Alert Output Select Bit
  ' (0) - Alert output for Tupper, Tlower, and Tcrit (default)
  ' (1) - Alert output for Ta>Tcrit ONLY
  ' Cannot be altered when alarm window lock bit is set
  ' Can be altered in shutdown mode. but will not assert
  mask := %0000_0000_0000_0100
  value := status << 2
  changeRegister(ConfigReg, mask, value)

PUB alertPolarity(status) | value, mask
  ' Alert Output Polarity Bit
  ' (0) - Active-low, pull-up required (default)
  ' (1) - Active-high
  ' Cannot be altered when either of the lock bits are set
  ' Can be altered in shutdown mode. but will not assert
  mask := %0000_0000_0000_0010
  value := status << 1
  changeRegister(ConfigReg, mask, value)

PUB alertMode(status) | value, mask
  ' Alert Output Mode Bit
  ' (0) - Comparator output (default)
  ' (1) - Interrupt output
  ' Cannot be altered when either of the lock bits are set
  ' Can be altered in shutdown mode. but will not assert
  mask := %0000_0000_0000_0001
  value := status 
  changeRegister(ConfigReg, mask, value)

PUB changeRegister(register, mask, value) | data
  ' Changes part of a given register with the given
  ' mask and value. Data should be same size as
  ' register.
  data := I2C.readWordB(DevAdr, register)
  data := data & !mask
  data := data | value
  I2C.writeWordB(DevAdr, register, data)

PUB setLowRes
  I2C.writeByte(DevAdr, ResReg, $00)

PUB setMedRes
  I2C.writeByte(DevAdr, ResReg, $01)

PUB setHighRes
  I2C.writeByte(DevAdr, ResReg, $02)

PUB setUHighRes
  I2C.writeByte(DevAdr, ResReg, $03)

DAT                     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}            