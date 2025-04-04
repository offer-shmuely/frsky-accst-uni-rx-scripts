-- TNS|UNI Activate v4|TNE

-- X8R, X4R configuration program for use with the firmware developed by Mike Blandford
-- V2 Activation Code numbers blinking when selected to change, Rx disconnected clears screen, Whitespace reformat, Misc cosmetic changes, Color added by MRC3742

local version = "4"

-- User adjustable settings --
local splashTime = 40 --<< Change value for splash screen display time at startup, change to 0 to disable (default value is 40 for two seconds)
local use_color = 0 --<< Changing value to 1 will use script colors instead of theme colors on 480 width LCD color screens only (default value is 0 for theme colors) experimental
local largeText = 0 --<< Changing value to 1 will allow larger text for easier readability on 480 width LCD color screens only (default value is 0)

-- For proper script operation Do NOT change values below this line
local Code = {}
local HexChars = {}
local HexText = {}
local txid = 0x17
local now = getTime() -- 50
local Page = 0
local SelectedItem = 0
local keepAlive = 1
local EditValue = 0
local midpx = LCD_W / 2
local txtSiz = 0
local start = 0
local Id0Value = 0
local Id0Read = 0
local Id1Value = 0
local Id1Read = 0
local Id2Value = 0
local Id2Read = 0
local Id3Value = 0
local Id3Read = 0
local Id4Value = 0
local Id4Read = 0
local ValidValue = 0
local ValidRead = 0
local SendingCode = 0
local UpdateValue = 0
local result = 0 -- needed global to not affect timing of refreshSetup

-- Computed depending on screen size at initialization
local wfpx, hfpx, hfpxLast, posrep, xpos_L, xpos_R, smSiz, bigSiz

local function toHex(value)
  HexText = HexChars[bit32.band(bit32.rshift(value,12), 0x000F)]            -- / 4096
  HexText = HexText .. HexChars[bit32.band(bit32.rshift(value,8), 0x000F)]  -- / 256
  HexText = HexText .. HexChars[bit32.band(bit32.rshift(value,4), 0x000F)]  -- / 16
  HexText = HexText .. HexChars[bit32.band(value, 0x000F)]
end

local function upField()
  if EditValue > 0 then
    if SelectedItem < 6 then
      local x = Code[SelectedItem]
      if x > 0 then
        x = x - 1
      end
      Code[SelectedItem] = x
    end
  else
    if SelectedItem > 0 then
      SelectedItem = SelectedItem - 1
    else
      SelectedItem = 6
    end
  end
end

local function downField()
  if EditValue > 0 then
    if SelectedItem < 6 then
      local x = Code[SelectedItem]
      if x < 15 then
        x = x + 1
      end
      Code[SelectedItem] = x
    end
  else
    SelectedItem = SelectedItem + 1
    if SelectedItem > 6 then
      SelectedItem = 0
    end
  end
end

local function sendWrite(value)
  local result = sportTelemetryPush(txid, 0x31, 0x0C20, value)
  return result
end

    -- Page-0 RX Setup --
local function changeSetup()
  if SelectedItem == 6 then
    SendingCode = 3
    now = getTime()
  elseif EditValue == 0 then
    EditValue = 1
  else
    EditValue = 0
  end
end

local function sendRead(value)
  local result = sportTelemetryPush(txid, 0x30, 0x0C20, value)
  return result
end

local function refreshSetup()
  --local i = 0 -- is i used??

  if getTime() - now > 60 then
    now = now + 60
    keepAlive = 0
    if Id0Read == 0 then
      result = sendRead(0x0CFF)
    elseif Id1Read == 0 then
      result = sendRead(0x0DFF)
    elseif Id2Read == 0 then
      result = sendRead(0x0EFF)
    elseif Id3Read == 0 then
      result = sendRead(0x0FFF)
    elseif Id4Read == 0 then
      result = sendRead(0x10FF)
    elseif ValidRead == 0 then
      result = sendRead(0xEB)
    else
      --i = 0
    end
    if result == 0 then
      now = now - 60
    end
    if SendingCode > 0 then
      if SendingCode == 3 then
        UpdateValue = Code[0] + bit32.lshift(Code[1],8)  -- * 256
        UpdateValue = bit32.lshift(UpdateValue,16)       -- * 65536
        UpdateValue = UpdateValue + 0xEB
        result = sportTelemetryPush(txid, 0x31, 0x0C20, UpdateValue)
          if result ~= 0 then
            SendingCode = 2
          end
    elseif SendingCode == 2 then
      UpdateValue = Code[2] + bit32.lshift(Code[3],8)  -- * 256
      UpdateValue = bit32.lshift(UpdateValue,16)       -- * 65536
      UpdateValue = UpdateValue + 0x1EB
      result = sportTelemetryPush(txid, 0x31, 0x0C20, UpdateValue)
        if result ~= 0 then
          SendingCode = 1
        end
    elseif SendingCode == 1 then
      UpdateValue = Code[4] + bit32.lshift(Code[5],8)  -- * 256
      UpdateValue = bit32.lshift(UpdateValue,16)       -- * 65536
      UpdateValue = UpdateValue + 0x2EB
      result = sportTelemetryPush(txid, 0x31, 0x0C20, UpdateValue)
        if result ~= 0 then
          SendingCode = 0
          ValidRead = 0
        end
      end
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
        if ValidRead == 0 then
          keepAlive = 1
        end
        local x = bit32.band(value, 0x00FF)
        if x == 0x00FF then
          value = bit32.rshift(value,8) -- / 256
          x = bit32.band(value, 0x00FF)
          value = bit32.rshift(value,8) -- / 256
          if x == 12 then
            Id0Value = value
            Id0Read = 1
          end
          if x == 13 then
            Id1Value = value
            Id1Read = 1
          end
          if x == 14 then
            Id2Value = value
            Id2Read = 1
          end
          if x == 15 then
            Id3Value = value
            Id3Read = 1
          end
          if x == 16 then
            Id4Value = value
            Id4Read = 1
          end
        else
          if x == 0x00EB then
            value = bit32.rshift(value,8) -- / 256
            ValidValue = bit32.band(value, 0x00FF)
            ValidRead = 1
          end
          now = getTime() - 55
        end
      end
    end
    -- refreshState = 0
  end
end

local function page0()
  lcd.drawText( midpx-wfpx*4.4, 0,"RX  Activation", txtSiz)

  lcd.drawText(xpos_L, hfpx*2, "Rx Code:", txtSiz)
  if Id1Read == 1 then
    toHex( Id1Value )
    lcd.drawText(midpx-wfpx*2, hfpx*2, HexText, txtSiz)
  end
  if Id2Read == 1 then
    toHex( Id2Value )
    lcd.drawText(midpx+wfpx*1.5, hfpx*2, HexText, txtSiz)
  end
  if Id3Read == 1 then
    toHex( Id3Value )
    lcd.drawText(midpx+wfpx*5, hfpx*2, HexText, txtSiz)
  end

  if ValidRead == 1 then
    if ValidValue > 0 then
      lcd.drawText(midpx-wfpx*4, hfpx*3, "ACTIVATED", txtSiz)
    else
      lcd.drawText(midpx-wfpx*2.4, hfpx*3, "LOCKED", txtSiz)
      lcd.drawText(midpx-wfpx*5.4, hfpx*4, "Enter Activate Code", smSiz)
    end
  end

  lcd.drawText(xpos_L, hfpx*5, "Activate Code:", txtSiz)
  local i = 0
  while i < 6 do
    local attr = 0
    if SelectedItem == i and EditValue > 0 then
      attr = INVERS + BLINK
    elseif SelectedItem == i then
      attr = INVERS
    end
    lcd.drawText(midpx+wfpx*2 + (i*wfpx), hfpx*5, HexChars[Code[i]], attr + txtSiz)
    i = i + 1
  end

  local attr = 0
  if SelectedItem == 6 then
    attr = INVERS
  end
  lcd.drawText(xpos_L, hfpx*6, "Send", attr + txtSiz)
  if SendingCode > 0 then
    lcd.drawText(midpx-wfpx*4.2, hfpx*6, "Sending Act Code", txtSiz)
  end
  lcd.drawText(xpos_R, hfpxLast, "script ver: " ..version, smSiz + RIGHT)
end -- END RX Setup Page-0 --

local function splash()
  lcd.drawText(midpx-wfpx*5.8, hfpx,"RX Activation", bigSiz)
  lcd.drawText(midpx-wfpx*3.2, hfpx*3, "(Version: " ..version ..")", smSiz)
  lcd.drawText(midpx-wfpx*6.4, hfpx*4.8,"for UNI-RX Firmware", txtSiz)
  lcd.drawText(xpos_L, hfpxLast, "Developer MikeBlandford", txtSiz)
  start = start + 1
end

local function change()
  changeSetup()
end

  -- Initialization table --
local function init()
  HexChars[0] = "0"
  HexChars[1] = "1"
  HexChars[2] = "2"
  HexChars[3] = "3"
  HexChars[4] = "4"
  HexChars[5] = "5"
  HexChars[6] = "6"
  HexChars[7] = "7"
  HexChars[8] = "8"
  HexChars[9] = "9"
  HexChars[10] = "A"
  HexChars[11] = "B"
  HexChars[12] = "C"
  HexChars[13] = "D"
  HexChars[14] = "E"
  HexChars[15] = "F"

  Code[0] = 8
  Code[1] = 8
  Code[2] = 8
  Code[3] = 8
  Code[4] = 8
  Code[5] = 8

  if LCD_H == 64 then
    hfpx = 8
    hfpxLast = hfpx*7
  elseif largeText == 1 then
    hfpx = LCD_H/10
    hfpxLast = hfpx*9
  else
    hfpx = LCD_H/12
    hfpxLast = hfpx*11
  end

  if LCD_W >= 480 then
    posrep = LCD_W*0.425
    if LCD_W == 800 then
      wfpx = 28
      largeText = 0
    else
      wfpx = 18
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
      lcd.setColor(CUSTOM_COLOR, GREEN1)
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
      if ValidRead == 1 and ValidValue ==0 then
        lcd.setColor(CUSTOM_COLOR, RED)                             --Title Bar for LOCKED
      else
        lcd.setColor(CUSTOM_COLOR, GREEN1)
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
    elseif event == EVT_VIRTUAL_PREV then upField()
    elseif event == EVT_VIRTUAL_PREV_REPT then upField()
    elseif event == EVT_VIRTUAL_NEXT then downField()
    elseif event == EVT_VIRTUAL_NEXT_REPT then downField()
    end
  else
    -- X9D
    if event == EVT_ENTER_BREAK then change()
    elseif event == EVT_PLUS_FIRST then upField()
    elseif event == EVT_PLUS_REPT then upField()
    elseif event == EVT_MINUS_FIRST then downField()
    elseif event == EVT_MINUS_REPT then downField()
    -- X10, X7
    elseif event == EVT_ROT_LEFT then upField()
    elseif event == EVT_ROT_RIGHT then downField()
    -- X-Lite
    elseif event == 100 then upField()
    elseif event == 68 then upField()
    elseif event == 99 then downField()
    elseif event == 67 then downField()
    end
  end

  if start < splashTime then
    splash()
  else
    refreshSetup()
    page0()
  end

  local rssi, low, crit = getRSSI()
  if rssi == 0 then
    Id0Read = 0
    Id1Read = 0
    Id2Read = 0
    Id3Read = 0
    Id4Read = 0
    ValidRead = 0
  end

  return 0
end
return {run=run, init=init}
