{
MCP9808 Digital Temperature Sensor Demo
J.R. Leeman
kd5wxb@gmail.com

This demos/tests all the functionality in the driver for the MCP9808.
}

CON
_clkmode = xtal1 + pll16x                                                      
_xinfreq = 5_000_000

SCL = 28
SDA = 29
ADR = $18

VAR
  byte testsPassed, testsFailed
  
OBJ
  PST : "Parallax Serial Terminal"
  MCP9808 : "MCP9808"

PUB go : t 
  PST.Start(115200)
  PAUSE_MS(3000)
  PST.Str(String("PST Started: NOTE - TEST MUST BE PERFORMED ON FRESHLY REPOWERED SENSOR"))     
  PST.Str(String(13))

  PST.Str(String("Starting MCP9808....."))
  MCP9808.start(ADR, SDA, SCL)
  PST.Str(String("Complete"))      
  PST.Str(String(13))

  PST.Str(String("Testing MFG ID (should be 0x0054)....."))
  t := MCP9808.getMfgId
  passfail(t,$0054)

  PST.Str(String("Testing DEV ID (should be 0x0400)....."))
  t := MCP9808.getDevId
  passfail(t,$0400)
  
  PST.Str(String("Testing Configuration Register Defaults (should be 0x0000)....."))
  t :=  MCP9808.readWordReg($01)
  passfail(t,$0000)

  PST.Str(String("Testing TUpper Register Defaults (should be 0x0000)....."))
  t :=  MCP9808.readWordReg($02)
  passfail(t,$0000)

  PST.Str(String("Testing TLower Register Defaults (should be 0x0000)....."))
  t :=  MCP9808.readWordReg($03)
  passfail(t,$0000)

  PST.Str(String("Testing TCrit Register Defaults (should be 0x0000)....."))
  t :=  MCP9808.readWordReg($04)
  passfail(t,$0000)

  PST.Str(String("Testing Resolution Register Defaults (should be 0x03)....."))
  t :=  MCP9808.readByteReg($08)
  passfail(t,$03)

  {
  Test reading/writing the alert registers for upper, lower, and critical
  temperatures.
  }
  
  PST.Str(String("Testing TUpper Writing (should be 0x00F0)....."))
  MCP9808.setTempHigh($00F0)
  t :=  MCP9808.readWordReg($02)
  passfail(t,$00F0)

  PST.Str(String("Testing TLower Writing (should be 0x0F00)....."))
  MCP9808.setTempLow($0F00)
  t :=  MCP9808.readWordReg($03)
  passfail(t,$0F00)

  PST.Str(String("Testing TCrit Writing (should be 0x03C0)....."))
  MCP9808.setTempCrit($03C0)
  t :=  MCP9808.readWordReg($04)
  passfail(t,$03C0)
  
  {
  Test working with the resolution register.
  }
  
  PST.Str(String("Set resolution to low....."))
  MCP9808.setLowRes 
  t :=  MCP9808.readByteReg($08)
  passfail(t,$00)

  PST.Str(String("Set resolution to medium....."))
  MCP9808.setMedRes 
  t :=  MCP9808.readByteReg($08)
  passfail(t,$01)

  PST.Str(String("Set resolution to high....."))
  MCP9808.setHighRes 
  t :=  MCP9808.readByteReg($08)
  passfail(t,$02)

  PST.Str(String("Set resolution to ultra-high....."))
  MCP9808.setUHighRes 
  t :=  MCP9808.readByteReg($08)
  passfail(t,$03)
  
 {
 Test all of the methods to change the configuration register. We test the
 locks absolutely last since they can only be reset by a power cycle. This
 is also why the power must be cycled for all tests to pass.
 }
 
  PST.Str(String("Testing Thyst (setting to +1.5 C)....."))
  MCP9808.setTHyst(%01)
  t :=  MCP9808.readWordReg($01) & %0000_0110_0000_0000 
  passfail(t,$200)

  PST.Str(String("Testing shutdown (monitor power for 0.5 sec)....."))
  MCP9808.shutdown(1)
  t :=  MCP9808.readWordReg($01) & %0000_0001_0000_0000 
  passfail(t,$100)
  PAUSE_MS(500)

  PST.Str(String("Waking up MCP9808....."))
  MCP9808.shutdown(0)
  t :=  MCP9808.readWordReg($01) & %0000_0001_0000_0000 
  passfail(t,$00)

  ' I don't like this test, since the chip clears the interrupt bit apparently
  ' there isn't really a way to make sure we set it, but at least it verifies
  ' that the function does run and should be useful later.
  PST.Str(String("Testing interrupt clear....."))
  MCP9808.IntClear
  t :=  MCP9808.readWordReg($01) & %0000_0000_0010_0000 
  passfail(t,$00)

  PST.Str(String("Testing alert control....."))
  MCP9808.alertControl(1)
  t :=  MCP9808.readWordReg($01) & %0000_0000_0000_1000 
  passfail(t,$08)

  PST.Str(String("Testing alert select....."))
  MCP9808.alertSelect(1)
  t :=  MCP9808.readWordReg($01) & %0000_0000_0000_0100 
  passfail(t,$04)

  PST.Str(String("Testing alert polarity....."))
  MCP9808.alertPolarity(1)
  t :=  MCP9808.readWordReg($01) & %0000_0000_0000_0010 
  passfail(t,$02)

  PST.Str(String("Testing alert mode....."))
  MCP9808.alertMode(1)
  t :=  MCP9808.readWordReg($01) & %0000_0000_0000_0001 
  passfail(t,$01)
  
  repeat 5
    PST.Str(String("Requesting Temperature.....")) 
    t := MCP9808.getTempC
    PST.dec(t)
    PST.Str(String(13))
    PAUSE_MS(300)

  PST.Str(String("Total Tests Passed: "))
  PST.dec(testsPassed)
  PST.Str(String(13))

  PST.Str(String("Total Tests Failed: "))
  PST.dec(testsFailed)
  PST.Str(String(13))

PUB passfail(data, truth) | passes
  if (data == truth)
    PST.Str(String("PASS"))
    PST.Str(String(13))
    passes := TRUE
    testsPassed += 1

  else
    PST.Str(String("FAIL"))
    PST.Str(String(13))
    passes := FALSE
    testsFailed += 1

PUB PAUSE_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)

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