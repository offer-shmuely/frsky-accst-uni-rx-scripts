-- TNS|UNI Setup v7|TNE

-- X8R, X4R configuration program for use with the firmware developed by Mike Blandford
-- V3 RX8RPRO corrected, RX8R added, whitespace reformat-Mike Blandford
-- V4 RX4R/6R and XSR added,options Invert SBUS,CPPM Enable added,New page-Rx Servo Rates,Misc options as N/A by RX firmware detected,Color added,D8/D4 now work need ver_57 by MikeB + MRC3742
-- V4b 21.06.2023 R-XSR receiver added with options to include Invert SBUS and CPPM Enable

version = "7"

-- User adjustable settings --
splashTime = 30 --<< Change value for splash screen display time at startup, change to 0 to disable (default value is 40 for two seconds)
use_color = 0 --<< Changing value to 1 will use script colors instead of theme colors on 480 width LCD color screens only (default value is 0 for theme colors) experimental
largeText = 0 --<< Changing value to 1 will allow larger text for easier readability on 480 width LCD color screens only (default value is 0)

-- For proper script operation Do NOT change values below this line
Bits = {}
OnOff = {}
RxType = {}
Mode = {}
Map = {}
MapText = {}
ResetText = {}
txid = 0x17
now = getTime() -- 50
item = 0
Sbus4Value = -1
InvSbusValue = -1
TuneOffset = -1
Page = 0
SelectedItem = 1
keepAlive = 1
skipCrates = 0
MapEnable = -1
EditValue = 0
OldValue = 0
midpx = LCD_W / 2
txtSiz = 0
start = 0
Resetting = 0
Fbus = {}
Fbus.Value = -1
Fbus.id = 0xEC
Stat7Value = -1
Stat8Value = -1
Stat9Value = -1
Chans9_16 = -1
D8cppmValue = -1
CppmValue = -1
Sbus8Value = -1
TuneValue = -1
Rate = -1
Crates = -1
FbusOK = 0

local function upField()
  if Page == 0 then
    limit = 6
	 if FbusOK == 0 then
	   limit = 5
	 end
	 if t == 0 then
	   limit = 7
	 end
    if SelectedItem > 0 then
      SelectedItem = SelectedItem - 1
    else
      SelectedItem = limit
    end
  elseif Page == 1 then
    if SelectedItem > 0 then
      SelectedItem = SelectedItem - 1
    else
      SelectedItem = 9
      if skipCrates == 1 and SelectedItem > 0 then
        SelectedItem = 0
      end
    end
  elseif Page == 2 then
    if EditValue > 0 then
      x = Map[SelectedItem-2]
      if x >1 then
        x = x - 1
      end
      Map[SelectedItem-2] = x
    else
      if SelectedItem > 0 then
        SelectedItem = SelectedItem - 1
      else
        SelectedItem = 17
      end
    end
  end
end

local function downField()
  if Page == 0 then
    limit = 6
	 if FbusOK == 0 then
	   limit = 5
	 end
	 if t == 0 then
	   limit = 7
	 end
    SelectedItem = SelectedItem + 1
    if SelectedItem > limit then
      SelectedItem = 0
    end
  elseif Page == 1 then
    SelectedItem = SelectedItem + 1
    if skipCrates == 1 and SelectedItem > 0 then
      SelectedItem = 0
    end
    if SelectedItem > 9 then
      SelectedItem = 0
    end
  elseif Page == 2 then
    if EditValue > 0 then
      x = Map[SelectedItem-2]
      if x < 15 then
        x = x + 1
      end
      Map[SelectedItem-2] = x
    else
      SelectedItem = SelectedItem + 1
      if SelectedItem > 17 then
        SelectedItem = 0
      end
    end
  end
end

local function sendWrite(value)
  result = sportTelemetryPush(txid, 0x31, 0x0C20, value)
  return result
end

local function updateValue(condition, code)
  if condition == 0 then
    code = code + 0x100
  end
  sendWrite(code)
end

------------ Page-0 Receiver Setup ------------
local function changeSetup()
  if SelectedItem == 0 then
    if Stat9Value ~= -1 then
      Resetting = 1
      now = getTime()
    end

  elseif SelectedItem == 1 then
    updateValue(TuneValue, 0xE5)
	 TuneValue = -1

  elseif SelectedItem == 2 then
    if t == 7 then
      updateValue(Fbus.Value, Fbus.id)
      Fbus.Value = -1
	 else
      updateValue(Chans9_16, 0xE0)
      Chans9_16 = -1
	 end

  elseif SelectedItem == 3 then
    if t == 0 then
      updateValue(CppmValue, 0xE3)
		CppmValue = -1
	 else
      updateValue(Sbus4Value, 0xE2)
		Sbus4Value = -1
    end

  elseif SelectedItem == 4 then
   if t == 0 or t == 3 or t == 5 or t == 7 then
      updateValue(InvSbusValue, 0xEA)
		InvSbusValue = -1
	end
    
  elseif SelectedItem == 5 then
    if t == 0 then
      updateValue(D8cppmValue, 0xED)
		D8cppmValue = -1
	 elseif t == 2 or t == 7 then
      updateValue(CppmValue, 0xE3)
		CppmValue = -1
	 end 

  elseif SelectedItem == 6 then
    if t == 0 then
      updateValue(Sbus4Value, 0xE2)
		Sbus4Value = -1
	 elseif FbusOK ~= 0 then
      updateValue(Fbus.Value, Fbus.id)
      Fbus.Value = -1
    end
	 
  elseif SelectedItem == 7 then
    if t == 0 then --D8R/D4R Receivers
      updateValue(Sbus8Value, 0xE1)
	   Sbus8Value = -1
    end
  end
  now = now + 60
end

local function sendRead(value)
  result = sportTelemetryPush(txid, 0x30, 0x0C20, value)
  return result
end

local function displayOption(vert, name, item, value, text)
  lcd.drawText(xpos_L, vert, name, txtSiz)
  attr = txtSiz_R
  if SelectedItem == item then attr = INVERS + txtSiz_R end
  if value ~= -1 then
    lcd.drawText(xpos_R, vert, text[value], attr)
  end
end

local function refreshSetup()
  FbusOK = 0
  if t and Stat7Value >= 80 then
    FbusOK = 1
  end
  if getTime() - now > 50 then
    now = now + 60
    keepAlive = 0
    if Stat7Value == -1 then
      sendRead(0x7FF)
    elseif Stat8Value == -1 then
      sendRead(0x8FF)
    elseif Stat9Value == -1 then
      sendRead(0x9FF)
    elseif Chans9_16 == -1 then
      sendRead(0xE0)
    elseif Sbus8Value == -1 then
      sendRead(0xE1)
    elseif Sbus4Value == -1 then
      sendRead(0xE2)
    elseif CppmValue == -1 then
      sendRead(0xE3)
    elseif TuneOffset == -1 then
      sendRead(0xE4)
    elseif TuneValue == -1 then
      sendRead(0xE5)
    elseif InvSbusValue == -1 then
      sendRead(0xEA)
    else
	   if t == 0 then
	     if D8cppmValue == -1 then
          sendRead(0xED)
		  end
      elseif Fbus.Value == -1 then
        sendRead(Fbus.id)
      end
    end
  else
    if keepAlive ~= 0 then
      sportTelemetryPush(txid, 0, 0, 0)
    end
  end

  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId == 0x32 then
    if dataId == 0x0C20 then
      if TuneValue == -1 then
        keepAlive = 1
      end
      x = bit32.band(value, 0x00FF)
      value = value / 256
      if x == 0x00FF then
        x = bit32.band(value, 0x00FF)
        value = value / 256
        if x == 7 then
          Stat7Value = value
        end
        if x == 8 then
          Stat8Value = value
        end
        if x == 9 then
          Stat9Value = value
        end
      else
        value = bit32.band(value, 0x00FF)
        if x == 0xE0 then
          Chans9_16 = value
        elseif x == 0xE1 then
          Sbus8Value = value
        elseif x == 0xE2 then
          Sbus4Value = value
        elseif x == 0xE3 then
          CppmValue = value
        elseif x == 0xE4 then
          TuneOffset = value
        elseif x == 0xE5 then
          TuneValue = value
        elseif x == 0xEA then
          InvSbusValue = value
        elseif x == 0xED then
          D8cppmValue = value
        elseif x == 0xEC then
          Fbus.Value = value
        end
      end
      now = getTime() - 55
    end
    refreshState = 0
  end

  attr = 0
  lcd.drawText(midpx-wfpx*5.4, 0, "RX SETUP", txtSiz)
  if SelectedItem == 0 then attr = INVERS end
  lcd.drawText( midpx+wfpx*2, 0, "RESET", attr)

  ty = hfpx
  attr = 0
  if Stat9Value > 0 then
    if Stat9Value < 10 then
      t = math.floor(Stat9Value-0.5) -- Determine Receiver Type for Setup Options
      if t == 5 then
        lcd.drawText(xpos_L, ty, RxType[t], smSiz)
      else
        attr = BLINK
        lcd.drawText(xpos_L, ty, "~", attr + smSiz)
        lcd.drawText(midpx-wfpx*7, ty, RxType[t], smSiz)
      end
    end
  end
  if Stat7Value > 2 then
    s7v = math.floor(Stat7Value+0.5)
    lcd.drawText( midpx+wfpx*2.2, ty, "v"..s7v, smSiz + LEFT)
  else
    Stat7Value = -1
  end
  if Stat8Value > 0 then
    if Stat8Value < 5 then
      m = math.floor(Stat8Value+0.5)
 	   x = 8.2
      lcd.drawText(midpx+wfpx*x, ty, Mode[m], smSiz + RIGHT)
    end
  end

  ty = hfpx*2
  displayOption(ty, "Auto Tuning", 1, TuneValue, OnOff)
  if TuneOffset ~= -1 then
    tvalue = TuneOffset
    if tvalue > 128 then
      tvalue = tvalue - 256
    end
    lcd.drawNumber(midpx+wfpx*3, ty, tvalue, txtSiz_R)
  end

  ty = hfpx*3
  cvalue = Chans9_16
  if MapEnable == 1 or MapEnable == 3 then
    cvalue = 2
  end
  displayOption(ty, "Servo Outputs", 2, cvalue, MapText)

  ty = hfpx*4
  if t == 0 then --D8R/D4R Receivers
    displayOption(ty, "S.Port Enabled", 3, CppmValue, OnOff)
  else
    displayOption(ty, "Servo on SBUS", 3, Sbus4Value, OnOff)
  end

  ty = hfpx*5
  value = 2
  if t == 0 or t == 3 or t == 5 or t == 7 then --RX8R-PRO or RX4R/6R or R-XSR Receiver
    value = InvSbusValue
  end
  displayOption(ty, "Invert SBUS", 4, value, OnOff)

  ty = hfpx*6
  value = 2
  if t == 0 then
    value = D8cppmValue
  elseif t == 2 or t == 7 then
    value = CppmValue
  end
  displayOption(ty, "CPPM Enable", 5, value, OnOff)

  attr = 0
  ty = hfpx*7
  if SelectedItem == 6 then attr = INVERS end
  if t == 0 then
    lcd.drawText(xpos_L, ty, "SBUS on C4     C8", txtSiz)
    if Sbus4Value ~= -1 then
      x = 2.8
		if LCD_W >= 480 then
		  x = 1.8
		end
      lcd.drawText(midpx+wfpx*x, ty, OnOff[Sbus4Value], attr + txtSiz_R)
	 end
    attr = 0
    if SelectedItem == 7 then attr = INVERS end
    if Sbus8Value ~= -1 then
      lcd.drawText(xpos_R, ty, OnOff[Sbus8Value], attr + txtSiz_R)
	 end
  elseif FbusOK ~= 0 then
    displayOption(ty, "FBUS", 6, bit32.band(Fbus.Value, 0x0001), OnOff )
  end

  lcd.drawText(LCD_W, 0, "1/3", smSiz + RIGHT)
end ---- END Receiver Setup Page-0 ----

---------- Page-1 RX Servo Rates ----------
local function display9_18(item)
  svalue = 18
  if bit32.band(Crates,Bits[item]) == Bits[item] then
    svalue = 9
  end

  if LCD_W == 128 then
    dSx = (posrep / 7)
  else
    dSx = (posrep / 4.1)
  end
  dSx = (item*dSx) + (midpx-dSx*3.7)

  attr = txtSiz_R
  if MapEnable == 1 or MapEnable == 3 then
    thisitem = Map[item]+1
  else
    if Chans9_16 == 1 then
	   thisitem = item+9 
    else
	   thisitem = item+1
    end
  end
  lcd.drawNumber(dSx, hfpx*4, thisitem, attr)
  if SelectedItem == item + 1 then attr = attr + INVERS end
  lcd.drawNumber(dSx, hfpx*5, svalue, attr)
end

local function refreshServoRates()
  if getTime() - now > 60 then
    now = now + 60
    keepAlive = 0
    if Rate == -1 then
      result = sendRead(0xE6)
    elseif Crates == -1 then
      result = sendRead(0xE7)
    end
    if result == 0 then
      now = now - 60
    end
  else
    if keepAlive ~= 0 then
      sportTelemetryPush(txid, 0, 0, 0)
    end
  end

  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId == 0x32 then
    if dataId == 0x0C20 then
      if TuneValue == -1 then
        keepAlive = 1
      end
      x = bit32.band(value, 0x00FF)
      value = bit32.band(value / 256, 0x00FF)
      if x == 0x00E6 then
        Rate = value
      elseif x == 0x00E7 then
        Crates = value
      end
      now = getTime() - 65
    end
    refreshState = 0
  end

  lcd.drawText(midpx-wfpx*5.2, 0, "RX SERVO RATES", txtSiz)
  ty = hfpx*2
  lcd.drawText(midpx-wfpx*7.5, ty, "Enable 9mS Rates", txtSiz)
  attr = txtSiz
  if SelectedItem == 0 then attr = INVERS + txtSiz end
  if Rate == 0 then
    lcd.drawText(midpx+wfpx*5.1, ty, "OFF", attr)
    lcd.drawText(midpx-wfpx*6.6, ty+hfpx, "All Servos Now 18mS", txtSiz)
    skipCrates=1
  else
    if Crates ~= -1 then
      lcd.drawText(midpx+wfpx*5.1, ty, " ON ", attr)
      skipCrates=0
      for item = 0, 8 do
        display9_18(item)
      end
    end
  end
  lcd.drawText(midpx+wfpx*8, hfpxLast, "script ver: " ..version, smSiz + RIGHT)
  lcd.drawText(LCD_W, 0, "2/3", smSiz + RIGHT)
end ---- END RX Servo Rates Page-1 ----

---------- Page-2 Channel Mapping ----------
local function displayMap(item)
  dMx = item + 1
  dMy = hfpx*4
  if item > 7 then
    dMy = hfpx*7
    dMx = dMx - 8
  end
  if LCD_W == 128 then
    dMx = dMx * (posrep / 6)
  else
    dMx = dMx * (posrep / 3.9)
  end
  attr = 0
  if SelectedItem - 2 == item then
    attr = INVERS
    if EditValue > 0 then
      attr = BLINK
    end
  end
  lcd.drawNumber(dMx,dMy-hfpx,item+1, txtSiz_R)
  if Map[item] ~= -1 then
    lcd.drawNumber(dMx, dMy, Map[item]+1, attr + txtSiz_R)
  end
end

local function changeMap()
  if SelectedItem == 0 then
    if bit32.band(MapEnable, 1) > 0 then
      MapEnable = bit32.band(MapEnable, 2)
    else
      MapEnable = bit32.bor(MapEnable, 1)
    end
    newValue = bit32.bor(MapEnable * 256, 0xE8)
    sendWrite(newValue)
    MapEnable = -1
  elseif SelectedItem == 1 then
    if bit32.band(MapEnable, 2) > 0 then
      MapEnable = bit32.band(MapEnable, 1)
    else
      MapEnable = bit32.bor(MapEnable, 2)
    end
    newValue = bit32.bor((MapEnable * 256), 0xE8)
    sendWrite(newValue)
    MapEnable = -1
  else
    if EditValue == 0 then
      EditValue = 1
      OldValue = Map[SelectedItem-2]
    else
      EditValue = 0
      index = SelectedItem - 2
      if OldValue ~= Map[index] then
        newValue = bit32.bor(0xE9, index * 256)
        newValue = bit32.bor(newValue, Map[index] * 65536)
        sendWrite(newValue)
        Map[index] = -1
      end
    end
    now = now + 60
  end
end

local function refreshMap()
  if getTime() - now > 60 then
    now = now + 60
    if MapEnable == -1 then
      sendRead(0xE8)
    else
      i = 0
      ::loop1::
      if Map[i] == -1 then
        sendRead(bit32.bor(0xE9, i*256))
        goto break1
      end
      i = i + 1
      if i < 16 then
        goto loop1
      end
    end
  end
  ::break1::
  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId == 0x32 then
    if dataId == 0x0C20 then
      x = bit32.band(value, 0x00FF)
      value = value / 256
      if x == 0x00E8 then
        MapEnable = bit32.band(value, 0x00FF)
        now = getTime() - 55
      elseif x == 0x00E9 then
        x = bit32.band(value, 0x00FF)
        if x < 16 then
          Map[x] = value / 256
        end
      end
      now = getTime() - 65
    end
  end

  lcd.drawText(midpx-wfpx*4.4, 0, "CHANNEL MAP", txtSiz)
  lcd.drawText(midpx-wfpx*7.5, hfpx, "Enable Servo Map", txtSiz)
  lcd.drawText(midpx-wfpx*7.5, hfpx*2, "Enable S.BUS Map", txtSiz)
  attr = 0
  if SelectedItem == 0 then attr = INVERS end
  if MapEnable ~= -1 then
    lcd.drawText(midpx+wfpx*5.2, hfpx, OnOff[bit32.band(MapEnable, 1)], attr + txtSiz)
  end

  attr = 0
  if SelectedItem == 1 then attr = INVERS end
  if MapEnable ~= -1 then
    lcd.drawText(midpx+wfpx*5.2, hfpx*2, OnOff[bit32.band(MapEnable, 2)/2], attr + txtSiz)
  end

  for item = 0 , 15 do
    displayMap(item)
  end
  lcd.drawText(LCD_W, 0, "3/3", smSiz + RIGHT)
end ---- END Channel Mapping Page-2 ----

local function refreshresetting()
  ty = hfpx*2
  lcd.drawText(midpx-wfpx*5.4, 0, "RECEIVER  RESET", txtSiz)
  lcd.drawText(midpx-wfpx*3, ty, "Resetting", txtSiz)
  lcd.drawNumber(midpx+wfpx*.8, ty+hfpx, 28-Resetting, txtSiz_R)
  if getTime() - now > 50 then
    now = now + 60
    if Resetting == 5 then
      Resetting = 6
      sendWrite(0x1E5)
    elseif Resetting < 5 then
      sendWrite(0xDF+Resetting)
      Resetting = Resetting + 1
    elseif Resetting < 9 then
      sendWrite(0xE0+Resetting)
      Resetting = Resetting + 1
    elseif Resetting == 9 then
      Resetting = 10
      sendWrite(0xEA)
    elseif Resetting == 10 then
      Resetting = 11
      sendWrite(0xED)
    elseif Resetting < 27 then
      ti = Resetting - 11
      Resetting = Resetting + 1
		ti = ti + ti * 256
      newValue = 0xE9 + ti * 256
      sendWrite(newValue)
    elseif Resetting == 27 and FbusOK ~= 0 then
      Resetting = 28
      sendWrite(0xEC)
    else
      Resetting = 0
      TuneValue = -1
      Sbus4Value = -1
      Sbus8Value = -1
      CppmValue = -1
      D8cppmValue = -1
      InvSbusValue = -1
      Rate = -1
      Crates = -1
		MapEnable = -1
      Fbus.Value = -1
      D8cppmValue = -1
      CppmValue = -1
      Chans9_16 = -1
      for i = 0, 15 do
        Map[i] = -1
      end
    end
  end
end

local function change()
  if Page == 0 then
    changeSetup()
  elseif Page == 1 then
    if SelectedItem == 0 then
      updateValue(Rate, 0xE6)
	   Rate = -1
    else
      bit = Bits[SelectedItem - 1]
      newValue = bit32.bxor(Crates,bit)
      newValue = newValue * 256
      newValue = bit32.bor(newValue,0xE7)
      sendWrite(newValue)
      Crates = -1
    end
  elseif Page == 2 then
    changeMap()
  end
end

local function pageSwap(event)
  if Page == 2 then
    if EditValue > 0 then  --force channel map write if needed before page change to prevent error
      changeMap()
    end
    Page = 0
  else
    Page = Page + 1
  end
  event = 0
  SelectedItem = 0
end

local function pageBack(event)
  if Page == 0 then
    Page = 2
    killEvents(event)
  else
    if Page == 2 and EditValue > 0 then  --force channel map write if needed before page change to prevent error
      changeMap()
    end
    Page = Page - 1
    killEvents(event)
  end
  event = 0
  SelectedItem = 0
end

-- Initialization table --
local function init()
  OnOff[0]= "OFF"
  OnOff[1]= " ON "
  OnOff[2]= "N/A"

  RxType[0] = "D8R/D4R"
  RxType[1] = "X8R/X6R"
  RxType[2] = "X4R/X4R-SB"
  RxType[3] = "RX8R-PRO"
  RxType[4] = "RX8R"
  RxType[5] = "RX4R/6  G-RX6/8"
  RxType[6] = "XSR"
  RxType[7] = "R-XSR"
  RxType[8] = "S8R/S6R"
  RxType[9] = "Type[10]"  --Future Placeholder

  Mode[0] = "V1FCC"
  Mode[1] = "V1-EU"
  Mode[2] = "V2FCC"
  Mode[3] = "V2-EU"

  MapText[0] = "1- 8"
  MapText[1] = "9-16"
  MapText[2] = "MAPPED"

  ResetText[0] = "RESET"


  for i = 0, 9 do
    Bits[i]=math.pow(2,i)
  end

  for i = 0, 15 do
    Map[i] = -1
  end

  if LCD_H == 64 then
    hfpx = 8
    hfpxLast = hfpx*7
--  elseif largeText == 1 then
--    hfpx = LCD_H/10
--    hfpxLast = hfpx*9
  else
    hfpx = LCD_H/10
    hfpxLast = hfpx*9
  end

  if LCD_W >= 480 then
    posrep = LCD_W*0.425
    if LCD_W == 800 then
      wfpx = 28
      largeText = 0
    else
      wfpx = 18.35
    end
      if largeText == 1 then
        txtSiz = MIDSIZE
      else
        txtSiz = 0
      end
    smSiz = 0
    bigSiz = DBLSIZE
  else
    posrep = 90
    wfpx = 8
    txtSiz = 0
    smSiz = SMLSIZE
    bigSiz = MIDSIZE
  end

  xpos_L = (midpx-wfpx*7.8)  -- Left Side alignment position
  xpos_R = (midpx+wfpx*7.9)  -- Right Side alignment position
  txtSiz_R = txtSiz + RIGHT
end

local function run(event)
  lcd.clear()
  if LCD_W >= 480 and use_color ~= 0 then
    local BLUE1 = lcd.RGB(0x1E, 0x88, 0xE5)
    local GOLD1 = lcd.RGB(0xF9, 0xC4, 0x40)
    local GRAY1 = lcd.RGB(0x90, 0xA4, 0xAE)
    local GREEN1 = lcd.RGB(0x7C, 0xB3, 0x42)
    if start == 0 then
      ThmTexCol = lcd.getColor(TEXT_COLOR)
      ThmTexInvCol = lcd.getColor(TEXT_INVERTED_COLOR)
      ThmTexInvBgCol = lcd.getColor(TEXT_INVERTED_BGCOLOR)
    end
    if start < splashTime then
      lcd.setColor(CUSTOM_COLOR, GOLD1)
      lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H, CUSTOM_COLOR)     --Splash Page
      lcd.setColor(TEXT_COLOR, BLACK)
      lcd.setColor(TEXT_INVERTED_COLOR, WHITE)
      lcd.setColor(TEXT_INVERTED_BGCOLOR, BLACK)
    elseif event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT then--Restores Theme Colors - short press RTN Key before exit
      lcd.setColor(TEXT_COLOR, ThmTexCol)
      lcd.setColor(TEXT_INVERTED_COLOR, ThmTexInvCol)
      lcd.setColor(TEXT_INVERTED_BGCOLOR, ThmTexInvBgCol)
    else
      lcd.setColor(CUSTOM_COLOR, GRAY1)
      lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H, CUSTOM_COLOR)     --Background Area
      if Resetting > 0 then
        lcd.setColor(CUSTOM_COLOR, RED)                             --Title Bar for Reset
      else
        lcd.setColor(CUSTOM_COLOR, GOLD1)
      end
      lcd.drawFilledRectangle(0, 0, LCD_W, 25, CUSTOM_COLOR)        --Title Bar
      lcd.setColor(CUSTOM_COLOR, BLACK)
      lcd.drawRectangle(0, 25, LCD_W, 2, CUSTOM_COLOR, 2)           --Separator Line
    end
  end

  local ver, radio, maj, minor, rev = getVersion()
  if minor >= 3 then
      -- All Radios - Virtual Events
    if event == EVT_VIRTUAL_ENTER then change()
    elseif event == EVT_VIRTUAL_NEXT_PAGE then pageSwap(event)
    elseif event == EVT_VIRTUAL_PREV_PAGE then pageBack(event)
    elseif event == EVT_VIRTUAL_PREV then upField()
    elseif event == EVT_VIRTUAL_PREV_REPT then upField()
    elseif event == EVT_VIRTUAL_NEXT then downField()
    elseif event == EVT_VIRTUAL_NEXT_REPT then downField()
    end
  else
      -- X9D
    if event == EVT_ENTER_BREAK then change()
    elseif event == EVT_PAGE_BREAK then pageSwap(event)
    elseif event == EVT_PAGE_LONG then pageBack(event)
    elseif event == EVT_PLUS_FIRST then upField()
    elseif event == EVT_PLUS_REPT then upField()
    elseif event == EVT_MINUS_FIRST then downField()
    elseif event == EVT_MINUS_REPT then downField()
      -- X10, X7
    elseif event == EVT_PAGEDN_BREAK then pageSwap(event)
    elseif event == EVT_PAGEDN_LONG then pageBack(event)
    elseif event == EVT_ROT_LEFT then upField()
    elseif event == EVT_ROT_RIGHT then downField()
      -- X-Lite
    elseif event == 101 then pageSwap(event)
    elseif event == 102 then pageBack(event)
    elseif event == 100 then upField()
    elseif event == 68 then upField()
    elseif event == 99 then downField()
    elseif event == 67 then downField()
    end
  end

  if start < splashTime then
    lcd.drawText(midpx-wfpx*4.8, hfpx,"RX Setup", bigSiz)
    lcd.drawText(midpx-wfpx*3.2, hfpx*3, "(Version: " ..version ..")", smSiz)
    lcd.drawText(midpx-wfpx*6.4, hfpx*4.8,"for UNI-RX Firmware", txtSiz)
    lcd.drawText(xpos_L, hfpxLast, "Developer MikeBlandford", txtSiz)
    start = start + 1
  elseif Resetting > 0 then
    refreshresetting()
  elseif Page == 0 then
    refreshSetup()
  elseif Page == 1 then
    refreshServoRates()
  else
    refreshMap()
  end

  local rssi, low, crit = getRSSI()
  if rssi == 0 then
    Stat7Value = -1
    Stat8Value = -1
    Stat9Value = -1
    TuneValue = -1
    Chans9_16 = -1
    Sbus4Value = -1
    Sbus8Value = -1
    CppmValue = -1
    D8cppmValue = -1
    InvSbusValue = -1
    Rate = -1
    Crates = -1
	 MapEnable = -1
	 Fbus.Value = -1
	 TuneOffset = -1
    for i = 0, 15 do
      Map[i] = -1
    end
  end

  return 0
end
return {run=run, init=init}