-- TNS|UNI Sxr v1a|TNE

-- SxR, configuration program for use with the firmware developed by Mike Blandford

local version = "1a"

-- User adjustable settings --
local splashTime = 30 --<< Change value for splash screen display time at startup, change to 0 to disable (default value is 40 for two seconds)
local use_color = 0 --<< Changing value to 1 will use script colors instead of theme colors on 480 width LCD color screens only (default value is 0 for theme colors) experimental
local largeText = 0 --<< Changing value to 1 will allow larger text for easier readability on 480 width LCD color screens only (default value is 0)

-- For proper script operation Do NOT change values below this line
local txid = 0x17
local midpx = LCD_W / 2
local start = 0
local State = 0
local EnterPressed = 0


local hfpx, hfpxLast, posrep, wfpx, smSiz, bigSiz, txtSiz, xpos_L, xpos_R, txtSiz_R

local function sendWrite(value)
  local result = sportTelemetryPush(txid, 0x31, 0x0C30, value)
  return result
end

local function refreshSetup()
  lcd.drawText(midpx-wfpx*4.4, 0, "CALIBRATION", txtSiz)
  if State == 0 then
    lcd.drawText(midpx-wfpx*6.9, hfpx*2, "Place Horizontally", txtSiz)
    lcd.drawText(1, hfpx*4, "Press Enter to start", txtSiz)
    if EnterPressed == 1 then
	   EnterPressed = 0
     State = 1
	   sendWrite(0x01AF)
	 end
  end
  if State == 1 then
    lcd.drawText(midpx-wfpx*3.4, hfpx*2, "Calibrating", txtSiz)
    local physicalId, primId, dataId, value = sportTelemetryPop()
    if primId == 0x32 then
      if dataId == 0x0C30 then
        local x = bit32.band(value, 0x00FF)
        value = bit32.rshift(value,8)   -- / 256
        if x == 0x00AF then
          x = bit32.band(value, 0x00FF)
          if x == 1 then
			   State = 2
          end
        end
      end
    end
  end
  if State == 2 then
    lcd.drawText(midpx-wfpx*5.4, hfpx*2, "Place Vertically", txtSiz)
    lcd.drawText(1, hfpx*4, "Press Enter", txtSiz)
    if EnterPressed == 1 then
	   EnterPressed = 0
     State = 3
	   sendWrite(0x02AF)
	 end
  end
  if State == 3 then
    lcd.drawText(midpx-wfpx*3.4, hfpx*2, "Calibrating", txtSiz)
    local physicalId, primId, dataId, value = sportTelemetryPop()
    if primId == 0x32 then
      if dataId == 0x0C30 then
        local x = bit32.band(value, 0x00FF)
        value = bit32.rshift(value,8)   -- / 256
        if x == 0x00AF then
          x = bit32.band(value, 0x00FF)
          if x == 2 then
			   State = 4
	   		sendWrite(0x03AF)
          end
        end
      end
    end
  end
  if State == 4 then
	 lcd.drawText(midpx-wfpx*3.4, hfpx*2, "Centre Sticks", txtSiz)
    lcd.drawText(1, hfpx*4, "Press Enter", txtSiz)
    if EnterPressed == 1 then
	   EnterPressed = 0
     State = 5
	   sendWrite(0x04AF)
	 end
  end
  if State == 5 then
	 lcd.drawText(midpx-wfpx*5.4, hfpx*2, "Calibrate Channels", txtSiz)
	 lcd.drawText(1, hfpx*3, "Move sticks to give", txtSiz)
	 lcd.drawText(1, hfpx*4, "Full Servo Deflection", txtSiz)
    lcd.drawText(1, hfpx*6, "Press Enter", txtSiz)
    if EnterPressed == 1 then
	   EnterPressed = 0
     State = 6
	   sendWrite(0x05AF)
	 end
  end
  if State == 6 then
	 lcd.drawText(midpx-wfpx*3.0, hfpx*2, "Completed", txtSiz)
  end
end

local function change()
  EnterPressed = 1
end

-- Initialization table --
local function init()
--
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
--    elseif event == EVT_VIRTUAL_NEXT_PAGE then pageSwap(event)
--    elseif event == EVT_VIRTUAL_PREV_PAGE then pageBack(event)
--    elseif event == EVT_VIRTUAL_PREV then upField()
--    elseif event == EVT_VIRTUAL_PREV_REPT then upField()
--    elseif event == EVT_VIRTUAL_NEXT then downField()
--    elseif event == EVT_VIRTUAL_NEXT_REPT then downField()
    end
  else
      -- X9D
    if event == EVT_ENTER_BREAK then change()
--    elseif event == EVT_PAGE_BREAK then pageSwap(event)
--    elseif event == EVT_PAGE_LONG then pageBack(event)
--    elseif event == EVT_PLUS_FIRST then upField()
--    elseif event == EVT_PLUS_REPT then upField()
--    elseif event == EVT_MINUS_FIRST then downField()
--    elseif event == EVT_MINUS_REPT then downField()
      -- X10, X7
--    elseif event == EVT_PAGEDN_BREAK then pageSwap(event)
--    elseif event == EVT_PAGEDN_LONG then pageBack(event)
--    elseif event == EVT_ROT_LEFT then upField()
--    elseif event == EVT_ROT_RIGHT then downField()
      -- X-Lite
--    elseif event == 101 then pageSwap(event)
--    elseif event == 102 then pageBack(event)
--    elseif event == 100 then upField()
--    elseif event == 68 then upField()
--    elseif event == 99 then downField()
--    elseif event == 67 then downField()
    end
  end

  if start < splashTime then
    lcd.drawText(midpx-wfpx*4.8, hfpx,"SxR Setup", bigSiz)
    lcd.drawText(midpx-wfpx*3.2, hfpx*3, "(Version: " ..version ..")", smSiz)
    lcd.drawText(midpx-wfpx*6.4, hfpx*4.8,"for UNI-RX Firmware", txtSiz)
    lcd.drawText(xpos_L, hfpxLast, "Developer MikeBlandford", txtSiz)
    start = start + 1
  else
    refreshSetup()
  end

  return 0
end
return {run=run, init=init}