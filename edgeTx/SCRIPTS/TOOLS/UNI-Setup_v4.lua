-- X8R, X4R configuration program for use with the firmware developed by Mike Blandford
-- V3 RX8RPRO corrected, RX8R added, whitespace reformat-Mike Blandford
-- V4 RX4R/6R and XSR added,options Invert SBUS,CPPM Enable added,New page-Rx Servo Rates,Misc options as N/A by RX firmware detected,Color added,D8/D4 now work need ver_57 by MikeB + MRC3742

local toolName = "TNS|UNI-Setup V4|TNE"

local version = "4"
local splashTime = 40 --<< Change value for splash screen timeout at startup (value of 20 = 1 second)
local color = 1 --<< Changing value to 0 will disable color on 480 wide screens
local Bits = {}
local Statistics = {}
local StatRead = {}
local OnOff = {}
local RxType = {}
local Mode = {}
local Map = {}
local MapRead = {}
local txid = 0x17
local now = getTime() -- 50
local item = 0
local Rate = 0
local Crates = 0
local Chans9_16 = 0
local Sbus4Value = 0
local Sbus8Value = 0
local CppmValue = 0
local InvSbusValue = 0
local TuneValue = 0
local TuneOffset = 0
local Stat7Value = 0 -- Firmware Version
local Stat8Value = 0 -- Bind Mode
local Stat9Value = 0 -- Receiver Model Type
local NineMsRead = 0
local CratesRead = 0
local ChansRead = 0
local Sbus4Read = 0
local Sbus8Read = 0
local CppmRead = 0
local InvSbusRead = 0
local TuneRead = 0
local TuneOffRead = 0
local Stat7Read = 0
local Stat8Read = 0
local Stat9Read = 0
local Page = 0
local SelectedItem = 0
local keepAlive = 1
local skipCrates = 0
local MapEnable = 0
local EnableMapRead = 0
local EditValue = 0
local OldValue = 0
local midpx = LCD_W / 2
local txtSiz = 0
local start = 0
local Resetting = 0

local function upField()
  if Page == 0 then
    if SelectedItem > 0 then
      SelectedItem = SelectedItem - 1
    else
      SelectedItem = 6
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
    SelectedItem = SelectedItem + 1
    if SelectedItem > 6 then
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
    if Stat9Value ~= 0 then
      Resetting = 1
      now = getTime()
    end

  elseif SelectedItem == 1 then
    TuneRead = 0
    updateValue(TuneValue, 0xE5)

  elseif SelectedItem == 2 then
    ChansRead = 0
    updateValue(Chans9_16, 0xE0)

  elseif SelectedItem == 3 then
    if t ~= 6 then --D8R/D4R, X8R/X6R, X4R/X4R-SB, RX8R-PRO, RX8R, G-RX6/8 Receivers
      Sbus4Read = 0
      updateValue(Sbus4Value, 0xE2)
    end

  elseif SelectedItem == 4 then
    if t == 0 then  --D8R/D4R Receiver
      Sbus8Read = 0
      updateValue(Sbus8Value, 0xE1)
    end

  elseif SelectedItem == 5 then
    if t == 0 or t == 3 or t == 5 then  --D8R/D4R or RX8R-PRO Receivers or RX4R/6R
      InvSbusRead = 0
      updateValue(InvSbusValue, 0xEA)
    end

  elseif SelectedItem == 6 then
    if t == 0 or t == 2 then  --D8R/D4R or X4R/X4R-SB Receivers
      CppmRead = 0
      updateValue(CppmValue, 0xE3)
    end
  end
  now = now + 60
end

local function sendRead(value)
  result = sportTelemetryPush(txid, 0x30, 0x0C20, value)
  return result
end

local function refreshSetup()
  if getTime() - now > 50 then
    now = now + 60
    keepAlive = 0
    if Stat7Read == 0 then
      result = sendRead(0x07FF)
    elseif Stat8Read == 0 then
      result = sendRead(0x08FF)
    elseif Stat9Read == 0 then
      result = sendRead(0x09FF)
    elseif ChansRead == 0 then
      result = sendRead(0xE0)
    elseif Sbus8Read == 0 then
      result = sendRead(0xE1)
    elseif Sbus4Read == 0 then
      result = sendRead(0xE2)
    elseif CppmRead == 0 then
      result = sendRead(0xE3)
    elseif TuneOffRead == 0 then
      result = sendRead(0xE4)
    elseif TuneRead == 0 then
      result = sendRead(0xE5)
    elseif InvSbusRead == 0 then
      result = sendRead(0xEA)
    end
  else
    if keepAlive ~= 0 then
      result = sportTelemetryPush(txid, 0, 0, 0)
    end
  end

  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId ~= nil then
    if primId == 0x32 then
      if dataId == 0x0C20 then
        if TuneRead == 0 then
          keepAlive = 1
        end
        x = bit32.band(value, 0x00FF)
        if x == 0x00FF then
          value = value / 256
          x = bit32.band(value, 0x00FF)
          value = value / 256
          if x == 7 then
            Stat7Value = value
            Stat7Read = 1
          end
          if x == 8 then
            Stat8Value = value
            Stat8Read = 1
          end
          if x == 9 then
            Stat9Value = value
            Stat9Read = 1
          end
        else
          if x == 0x00E0 then
            value = value / 256
            Chans9_16 = bit32.band(value, 0x00FF)
            ChansRead = 1
          elseif x == 0x00E1 then
            value = value / 256
            Sbus8Value = bit32.band(value, 0x00FF)
            Sbus8Read = 1
          elseif x == 0x00E2 then
            value = value / 256
            Sbus4Value = bit32.band(value, 0x00FF)
            Sbus4Read = 1
          elseif x == 0x00E3 then
            value = value / 256
            CppmValue = bit32.band(value, 0x00FF)
            CppmRead = 1
          elseif x == 0x00E4 then
            value = value / 256
            TuneOffset = bit32.band(value, 0x00FF)
            TuneOffRead = 1
          elseif x == 0x00E5 then
            value = value / 256
            TuneValue = bit32.band(value, 0x00FF)
            TuneRead = 1
          elseif x == 0x00EA then
            value = value / 256
            InvSbusValue = bit32.band(value, 0x00FF)
            InvSbusRead = 1
          end
          now = getTime() - 55
        end
      end
      refreshState = 0
    end
  end

  lcd.drawText(midpx-wfpx*5.4, 0, "RECEIVER  SETUP", txtSiz)

  ty = hfpx*1.1
  attr = 0
  if Stat9Read == 1 then
    if Stat9Value > 0 then
      if Stat9Value < 10 then
        t = math.floor(Stat9Value-0.5)
        if t == 5 then
          lcd.drawText(xpos_L, ty, RxType[t], smSiz)
        else
          attr = BLINK
          lcd.drawText(xpos_L, ty, "~", attr + smSiz)
          lcd.drawText(midpx-wfpx*7, ty, RxType[t], smSiz)
        end
      end
    end
  end

  attr = 0
  if Stat7Read == 1 then
    if Stat7Value > 2 then
      s7v = math.floor(Stat7Value+0.5)
      lcd.drawText(midpx+wfpx*1.8, ty, "V_"..s7v, smSiz + LEFT)
    else
      Stat7Read = 0
    end
  end
  if Stat8Read == 1 then
    if Stat8Value > 0 then
      if Stat8Value < 5 then
        m = math.floor(Stat8Value+0.5)
        lcd.drawText(midpx+wfpx*8.2, ty, Mode[m], smSiz + RIGHT)
      end
    end
  end

  ty = hfpx*2
  lcd.drawText(xpos_L, ty, "Default Settings", txtSiz)
  attr = 0
  if SelectedItem == 0 then
    attr = INVERS
  end
  if Stat9Read == 1 then
    lcd.drawText(xpos_R, ty, "RESET", attr + txtSiz_R)
  end

  ty = hfpx*3
  lcd.drawText(xpos_L, ty, "Tuning", txtSiz)
  if TuneOffRead == 1 then
    tvalue = TuneOffset
    if tvalue > 128 then
      tvalue = tvalue - 256
    end
    lcd.drawNumber(midpx+wfpx, ty, tvalue, txtSiz_R)
  end
  attr = 0
  if SelectedItem == 1 then
    attr = INVERS
  end
  if TuneRead == 1 then
    lcd.drawText(xpos_R, ty, OnOff[TuneValue], attr + txtSiz_R)
  end

  ty = hfpx*4
  lcd.drawText(xpos_L, ty, "Servo Outputs", txtSiz)
  attr = 0
  if SelectedItem == 2 then
    attr = INVERS
    skipItem = 0
  end
  if ChansRead == 1 then
    if MapEnable == 1 or MapEnable == 3 then
      lcd.drawText(xpos_R,ty,"MAPPED", attr + txtSiz_R)
    elseif Chans9_16 == 0 then
      lcd.drawText(xpos_R, ty,"1- 8", attr + txtSiz_R)
    elseif Chans9_16 == 1 then
      lcd.drawText(xpos_R,ty,"9-16", attr + txtSiz_R)
    end
  end

  ty = hfpx*5
  if t == 0 then --D8R/D4R Receivers
    lcd.drawText(xpos_L, ty, "SBUS on Channel", txtSiz)
  else
    lcd.drawText(xpos_L, ty, "Servo on SBUS", txtSiz)
  end
  attr = 0
  if SelectedItem == 3 then
    attr = INVERS
  end
  if Sbus4Read == 1 then
    if t ~= 6 then --X8R/X6R, X4R/X4R-SB, RX8R-PRO, RX8R, G-RX6/8 Receivers
      if t == 0 then --D8R/D4R Receiver
        lcd.drawText(midpx+wfpx*3.8, ty, "4", attr + txtSiz)
        skipItem = 1
      end
      lcd.drawText(xpos_R, ty, OnOff[Sbus4Value], attr + txtSiz_R)
    else
      lcd.drawText(xpos_R, ty, "N/A", attr + txtSiz_R)
    end
    if SelectedItem == 4 and skipItem == 0 then
      skipItem = 1
      SelectedItem = 5
    end
  end

  attr = 0
  advRow = 0
  if Sbus8Read == 1 then
    if t == 0 and LCD_H == 272 then --D8R/D4R Receivers and LCD Screen Height allows Two extra lines available
      advRow = hfpx
      lcd.drawText(xpos_L, ty + advRow, "SBUS on Channel  8", txtSiz)
      lcd.drawText(xpos_R, ty + advRow, OnOff[Sbus8Value], attr + txtSiz_R)
    end
    if SelectedItem == 4 then
      attr = INVERS
      if t == 0 then --D8R/D4R Receivers
        if Sbus8Read == 1 then
          lcd.drawText(midpx+wfpx*3.8, ty + advRow, "8", attr + txtSiz)
          lcd.drawText(xpos_R, ty + advRow, OnOff[Sbus8Value], attr + txtSiz_R)
        end
      end
    end
  end

  ty = hfpx*6
  lcd.drawText(xpos_L, ty + advRow, "Invert SBUS", txtSiz)
  attr = 0
  if SelectedItem == 5 then
    attr = INVERS
  end
  if InvSbusRead == 1 then
    if t == 0 then --D8R/D4R Receiver
      lcd.drawText(xpos_R, ty + advRow, OnOff[InvSbusValue], attr + txtSiz_R)
      skipItem = 0
    elseif t == 3 or t == 5 then --RX8R-PRO Receiver or RX4R/6R
      if Sbus4Value == 1 and InvSbusValue == 1 then
        sendWrite(0x00EA)
        InvSbusValue = 0
      elseif Sbus4Value == 1 then
        lcd.drawText(xpos_R, ty, "N/A", attr + txtSiz_R)
      else
        lcd.drawText(xpos_R, ty, OnOff[InvSbusValue], attr + txtSiz_R)
      end
    else
      lcd.drawText(xpos_R, ty, "N/A", attr + txtSiz_R)
    end
    if SelectedItem == 4 and skipItem == 1 then
      skipItem = 0
      SelectedItem = 3
    end
  end

  ty = hfpx*7
  if t == 0 then
    lcd.drawText(xpos_L, ty + advRow, "S.Port Enabled", txtSiz)
  else
    lcd.drawText(xpos_L, ty, "CPPM Out Enable", txtSiz)
  end
  attr = 0
  if SelectedItem == 6 then
    attr = INVERS
    skipItem = 1
  end
  if CppmRead == 1 then
    if t == 0 or t == 2 then --D8R/D4R, X4R/X4R-SB Receivers
      lcd.drawText(xpos_R, ty + advRow, OnOff[CppmValue], attr + txtSiz_R)
    elseif t == 6 then  -- XSR Receiver - Software set to always ON
      lcd.drawText(xpos_R, ty, " ON ", attr + txtSiz_R)
    else
      lcd.drawText(xpos_R, ty, "N/A", attr + txtSiz_R)
    end
  end

  lcd.drawText(LCD_W, 0, "1/3", smSiz + RIGHT)
end ---- END Receiver Setup Page-0 ----

---------- Page-1 RX Servo Rates ----------
local function changeServoRates()
  if SelectedItem == 0 then
    NineMsRead = 0
    updateValue(Rate, 0xE6)
  else
    bit = Bits[SelectedItem - 1]
    newValue = bit32.bxor(Crates,bit)
    newValue = newValue * 256
    newValue = bit32.bor(newValue,0xE7)
    CratesRead = 0
    result = sendWrite(newValue)
  end
end

local function display9_18(item)
  if bit32.band(Crates,Bits[item]) == Bits[item] then
    svalue = 9
  else
    svalue = 18
  end

  if LCD_W == 128 then
    dSx = (posrep / 7)
  else
    dSx = (posrep / 4.1)
  end

  attr = txtSiz_R
  if MapEnable == 1 or MapEnable == 3 then
    lcd.drawNumber((item*dSx) + (midpx-dSx*3.7), hfpx*4, Map[item]+1, attr)
  else
    if Chans9_16 == 1 then
      lcd.drawNumber((item*dSx) + (midpx-dSx*3.7), hfpx*4, item+9, attr)
    else
      lcd.drawNumber((item*dSx) + (midpx-dSx*3.7), hfpx*4, item+1, attr)
    end
  end
  lcd.drawNumber((item*dSx) + (midpx-dSx*3.7), hfpx*5, svalue, attr)
  if SelectedItem == item + 1 then
    attr = attr + INVERS
    lcd.drawNumber((item*dSx) + (midpx-dSx*3.7), hfpx*5, svalue, attr)
  end
end

local function refreshServoRates()
  if getTime() - now > 60 then
    now = now + 60
    keepAlive = 0
    if NineMsRead == 0 then
      result = sendRead(0xE6)
    elseif CratesRead == 0 then
      result = sendRead(0xE7)
    end
    if result == 0 then
      now = now - 60
    end
  else
    if keepAlive ~= 0 then
      result = sportTelemetryPush(txid, 0, 0, 0)
    end
  end

  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId ~= nil then
    if primId == 0x32 then
      if dataId == 0x0C20 then
        if TuneRead == 0 then
          keepAlive = 1
        end
        x = bit32.band(value, 0x00FF)
        if x == 0x00E6 then
          value = value / 256
          Rate = bit32.band(value, 0x00FF)
          NineMsRead = 1
        elseif x == 0x00E7 then
          value = value / 256
          Crates = bit32.band(value, 0x01FF)
          CratesRead = 1
        end
        now = getTime() - 55
      end
      refreshState = 0
    end
  end

  lcd.drawText(midpx-wfpx*5.2, 0, "RX SERVO RATES", txtSiz)
  ty = hfpx*2
  lcd.drawText(midpx-wfpx*7.5, ty, "Enable 9mS Rates", txtSiz)
  attr = 0
  if SelectedItem == 0 then
    attr = INVERS
  end
  if Rate == 0 then
    if CratesRead == 1 then
      lcd.drawText(midpx+wfpx*5.2, ty, "OFF", attr + txtSiz)
      lcd.drawText(midpx-wfpx*6.6, ty+hfpx, "All Servos Now 18mS", txtSiz)
    end
    skipCrates=1
  else
    if CratesRead == 1 then
      lcd.drawText(midpx+wfpx*5.2, ty, " ON ", attr + txtSiz)
      skipCrates=0
      for item = -1, 7 do
        item = item + 1
        display9_18(item)
      end
    end
  end
  lcd.drawText(midpx+wfpx*8, hfpxLast, "UNI-RX Setup lua Ver_" ..version, smSiz + RIGHT)
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
  if MapRead[item] > 0 then
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
    newValue = bit32.bor(MapEnable * 256, 0x00E8)
    EnableMapRead = 0
    result = sendWrite(newValue)
  elseif SelectedItem == 1 then
    if bit32.band(MapEnable, 2) > 0 then
      MapEnable = bit32.band(MapEnable, 1)
    else
      MapEnable = bit32.bor(MapEnable, 2)
    end
    newValue = bit32.bor((MapEnable * 256), 0x00E8)
    EnableMapRead = 0
    result = sendWrite(newValue)
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
        MapRead[index] = 0
        result = sendWrite(newValue)
      end
    end
    now = now + 60
  end
end

local function refreshMap()
  if getTime() - now > 60 then
    now = now + 60
    if EnableMapRead == 0 then
      result = sendRead(0xE8)
    else
      i = 0
      ::loop1::
      if MapRead[i] == 0 then
        result = sendRead(bit32.bor(0xE9, i*256))
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
  if primId ~= nil then
    if primId == 0x32 then
      if dataId == 0x0C20 then
        x = bit32.band(value, 0x00FF)
        if x == 0x00E8 then
          value = value / 256
          MapEnable = bit32.band(value, 0x00FF)
          EnableMapRead = 1
          now = getTime() - 55
        else
          if x == 0x00E9 then
            value = value / 256
            x = bit32.band(value, 0x00FF)
            value = value / 256
            if x < 16 then
              Map[x] = value
              MapRead[x] = 1
              now = getTime() - 55
            end
          end
        end
      end
    end
  end

  lcd.drawText(midpx-wfpx*4.4, 0, "CHANNEL MAP", txtSiz)
  lcd.drawText(midpx-wfpx*7.5, hfpx, "Enable Servo Map", txtSiz)
  lcd.drawText(midpx-wfpx*7.5, hfpx*2, "Enable S.BUS Map", txtSiz)
  attr = 0
  if SelectedItem == 0 then
    attr = INVERS
  end
  if EnableMapRead > 0 then
    lcd.drawText(midpx+wfpx*5.2, hfpx, OnOff[bit32.band(MapEnable, 1)], attr + txtSiz)
  end

  attr = 0
  if SelectedItem == 1 then
    attr = INVERS
  end
  if EnableMapRead > 0 then
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
  lcd.drawNumber(midpx+wfpx*.8, ty+hfpx, 27-Resetting, txtSiz_R)
  if getTime() - now > 50 then
    now = now + 60
    if Resetting == 1 then
      Resetting = 2
      sendWrite(0x00E0)
    elseif Resetting == 2 then
      Resetting = 3
      sendWrite(0x00E1)
    elseif Resetting == 3 then
      Resetting = 4
      sendWrite(0x00E2)
    elseif Resetting == 4 then
      Resetting = 5
      sendWrite(0x00E3)
    elseif Resetting == 5 then
      Resetting = 6
      sendWrite(0x01E5)
    elseif Resetting == 6 then
      Resetting = 7
      sendWrite(0x00E6)
    elseif Resetting == 7 then
      Resetting = 8
      sendWrite(0x00E7)
    elseif Resetting == 8 then
      Resetting = 9
      sendWrite(0x00E8)
    elseif Resetting == 9 then
      Resetting = 10
      sendWrite(0x00EA)
    elseif Resetting < 26 then
      ti = Resetting - 10
      Resetting = Resetting + 1
      newValue = bit32.bor(0xE9, ti * 256)
      newValue = bit32.bor(newValue, ti * 65536)
      sendWrite(newValue)
    else
      Resetting = 0
      TuneRead = 0
      ChansRead = 0
      Sbus4Read = 0
      Sbus8Read = 0
      CppmRead = 0
      InvSbusRead = 0
      NineMsRead = 0
      CratesRead = 0
      EnableMapRead = 0
      MapEnable = 0
      for i = 0, 15 do
        Map[i] = 0
        MapRead[i] = 0
      end
    end
  end
end

local function splash()
  lcd.drawText(midpx-wfpx*4.8, hfpx,"RX Setup", bigSiz)
  lcd.drawText(midpx-wfpx*3.2, hfpx*3, "(Version " ..version ..")", smSiz)
  lcd.drawText(midpx-wfpx*6.4, hfpx*4.8,"for UNI-RX Firmware", txtSiz)
  lcd.drawText(xpos_L, hfpxLast, "Developer MikeBlandford", txtSiz)
  start = start + 1
end

local function change()
  if Page == 0 then
    changeSetup()
  elseif Page == 1 then
    changeServoRates()
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

  RxType[0] = "D8R/D4R"
  RxType[1] = "X8R/X6R"
  RxType[2] = "X4R/X4R-SB"
  RxType[3] = "RX8R-PRO"
  RxType[4] = "RX8R"
  RxType[5] = "RX4R/6  G-RX6/8"
  RxType[6] = "XSR"
  RxType[7] = "Type[7]"  --Future Placeholder
  RxType[8] = "Type[8]"  --Future Placeholder
  RxType[9] = "Type[9]"  --Future Placeholder

  Mode[0] = "V1FCC"
  Mode[1] = "V1_EU"
  Mode[2] = "V2FCC"
  Mode[3] = "V2_EU"

  for i = 0, 9 do
    Bits[i]=math.pow(2,i)
  end

  for i = 0, 9 do
    Statistics[i] = 0
    StatRead[i] = 0
  end

  for i = 0, 15 do
    Map[i] = 0
    MapRead[i] = 0
  end

  if LCD_H == 64 then
    hfpx = 8
    hfpxLast = hfpx*7
  else hfpx = LCD_H/10
    hfpxLast = hfpx*9
  end

  if LCD_W == 480 then
    posrep = 204
    wfpx = 18
    txtSiz = MIDSIZE
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
  if LCD_W == 480 and color ~= 0 then
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
    splash()
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
    Stat7Read = 0
    Stat8Read = 0
    Stat9Read = 0
    NineMsRead = 0
    CratesRead = 0
    ChansRead = 0
    Sbus4Read = 0
    Sbus8Read = 0
    CppmRead = 0
    InvSbusRead = 0
    TuneRead = 0
    TuneOffRead = 0
    EnableMapRead = 0
    for i = 0, 15 do
      Map[i] = 0
      MapRead[i] = 0
    end
  end

  return 0
end
return {run=run, init=init}