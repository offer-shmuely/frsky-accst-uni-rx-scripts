-- TNS|UNI Statistics v6|TNE

-- D8R-II, D8R-IIplus, D8R-XP or D4R-II configuration program for use with the firmware developed by Mike Blandford
-- Conversion from Basic D8rD16.bas (ErskyTx) to lua D8rD16.lua (OpenTx) code with Avionic78, Dean Church and dev.fred contributions
-- D8rD16v5.lua
-- V1  05.01.2020 - X10, X9D, X7, X-Lite dev.fred
-- V2  07.02.2020 - Invert SBUS (d8rii_rom050220)
-- V3  03.02.2020 - manage 8 lines max on X9D  & Xlite
-- V3a 18.03.2020 - fix button events on X9D, Larger text size on 480 screen, reorder setup options - MRC3742
-- V3b 18.03.2020 - add Splash Screen - Change value below to change duration (or 0 to bypass) - MRC3742
-- V4  31.03.2020 - convert extra page from bas script for unique ID's and the first few channel counts - MRC3742
-- V5  28.04.2020 - Add Channel-Map Page (converted map.bas), All 47 hopping channels(only 29 on 128 wide), rearrange options and pages - dev.fred, MRC3742
-- V5  24.02.2022 - DW Add Receiver Antenna Blocks for Horus 480 Pixel display
-- V5a 24.02.2022 - DW Naming of Blocks changed. Refresh Rate correction in Hopping Table.  PageSwitch modified
-- V5b 25.02.2022 - DW Bug in Receiver Type Display fixed
-- V5c 28.02.2022 - DW RX8R-PRO and RX8R added
-- V5d 28.02.2022 - DW 1 more  Page added
-- V5e 28.02.2022 - DW Page Back not working properly on Taranis
-- V6  26.02.2023 - New Receivers added, Remove useless code as setup now has a separate script, Title text centered on pages, Color added - MRC3742

local version = "6"
local splashTime = 40 --<< Change value for splash screen timeout at startup (value of 20 = 1 second)
local use_color = 1 --<< Changing value to 0 will disable color on 480 wide screens
local Statistics = {}
local StatRead = {}
local RxType = {}
local Mode = {}
local HopChannel = {}
local HopCount = {}
local txid = 0x17
local now = getTime() -- 50
local start = 0
local item = 0
local Hitem = 0
local Sitem = 0
local Page = 1
local NrOfPages = 3
local midpx = LCD_W / 2
local txtSiz = 0
local Uid0 = 0
local Uid1 = 0
local line = 0

local function displayStats(item, row)
  dSy = hfpx * (row -1)
  lcd.drawNumber(xpos_R, dSy+hfpx, Statistics[item], txtSiz_R + StatRead[item])
end

local function refreshStats()
  if getTime() - now > 40 then
    now = now + 40
    result = sportTelemetryPush(txid, 0x30, 0x0C20, (Sitem * 256) + 0x00FF)
    Sitem = Sitem + 1
    if Sitem > 11 then    --DW 9->11
      Sitem = 0
    end
  end

  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId ~= nil then
    if primId == 0x32 then
      if dataId == 0x0C20 then
        x = bit32.band(value, 0x00FF)
        if x == 0x00FF then
          value = value / 256
          x = bit32.band(value, 0x00FF)
          value = value / 256
          if x < 12 then     --DW 10->12
            Statistics[x] = value
            StatRead[0] = 0
            StatRead[1] = 0
            StatRead[2] = 0
            StatRead[3] = 0
            StatRead[4] = 0
            StatRead[5] = 0
            StatRead[6] = 0
            StatRead[7] = 0
            StatRead[8] = 0
            StatRead[9] = 0
            StatRead[10] = 0
            StatRead[11] = 0
            StatRead[x] = INVERS
          end
        end
      end
    end
    refreshState = 0
  end
end

local function RecStat()
  lcd.drawText(midpx-wfpx*5.1, 0, "RX  STATISTICS", txtSiz)
  lcd.drawText(xpos_L, hfpx*1, "Lost Pkts Total", txtSiz)
  lcd.drawText(xpos_L, hfpx*2, "CRC Errors Total", txtSiz)
  lcd.drawText(xpos_L, hfpx*3, "Lost Frames   %", txtSiz)
  lcd.drawText(xpos_L, hfpx*4, "LBT Blocks", txtSiz)
  lcd.drawText(xpos_L, hfpx*5, "Antenna Swaps", txtSiz)
  lcd.drawText(xpos_L, hfpx*6, "Valid Ant1 Pkts", txtSiz)
  lcd.drawText(xpos_L, hfpx*7, "Valid Ant2 Pkts", txtSiz)

  displayStats(0,1)     -- Lost Packets
  displayStats(1,2)     -- CRC Errors
  displayStats(2,3)     -- Lost Frames
  displayStats(6,4)     -- LBT Blocks
  displayStats(5,5)     -- Antenna Swaps
  displayStats(10,6)    -- Display Numeric Antenna1 Frames
  displayStats(11,7)    -- Display Numeric Antenna2 Frames

  lcd.drawText(LCD_W, 0, "1/3", smSiz_R)
end	-- END Statistics Page-1 --

local function RecInfo()
  lcd.drawText(midpx-wfpx*5.1, 0, "RECEIVER  INFO", txtSiz)
  lcd.drawText(xpos_L, hfpx*1, "RX Type", txtSiz)
  lcd.drawText(xpos_L, hfpx*2, "Bind Protocol", txtSiz)
  lcd.drawText(xpos_L, hfpx*3, "Firmware Version", txtSiz)
  lcd.drawText(xpos_L, hfpx*4, "Average Pkt Time", txtSiz)

  if Statistics[9] > 0.51 then
    if Statistics[9] < 10 then
      t = math.floor(Statistics[9]-0.5)
      lcd.drawText(xpos_R, hfpx, RxType[t], txtSiz_R + StatRead[9])
    end
  end

  if Statistics[8] ~= nil then     -- Display HF-Mode/Version String
    if Statistics[8] >= 0 then
      t = math.floor(Statistics[8]+0.5)
      lcd.drawText(xpos_R, hfpx*2, Mode[t], txtSiz_R + StatRead[8])
    end
  end
  displayStats(7,3)      -- Display Version
  displayStats(3,4)      -- Average Pkt Time

  lcd.drawText(xpos_R, hfpxLast, "script version: " ..version, smSiz_R)
  lcd.drawText(LCD_W, 0, "2/3", smSiz_R)
end	-- END Statistics Page-2 --

-- Page-3 Channel Hop Count --
local function displayHop(line)
  if LCD_W == 480 then
    dMx = posrep/5.5
    dMy = line + 4
    if line > 9 then
      dMx = posrep/1.3
      dMy = dMy -12
      if line > 21 then
        dMx = posrep*1.35
        dMy = dMy -12
        if line > 33 then
          dMx = posrep*1.95
          dMy = dMy -12
        end
      end
    end
    dMxa = dMx + posrep/5.9
    dMxb = dMx + posrep/2.9
    dMy = dMy * hfpx/1.41
  else
    dMx = posrep/10.5
    dMy = line + 2
    if line > 7 then
      dMx = posrep/1.7
      dMy = dMy -10
      if line > 17 then
        dMx = posrep*1.06
        dMy = dMy -10
        if line > 27 and LCD_W > 128 then
          dMx = posrep*1.54
          dMy = dMy -10
          if line > 37 and LCD_W > 128 then
            dMx = posrep*2.03
            dMy = dMy -8
          end
        end
      end
    end
    dMxa = dMx + posrep/6.5
    dMxb = dMx + posrep/3.1
    dMy = dMy * hfpx/1.23
  end
--	lcd.drawText(dMx,dMy,(line + 1)..")", smSiz_R)
  lcd.drawNumber(dMxa, dMy, HopChannel[i], smSiz_R)
  lcd.drawNumber(dMxb, dMy, HopCount[i], smSiz_R)
  i = i + 1
  if i > 46 then
    i = 0
  end
end

local function hoptable()
  if getTime() - now > 40 then
    now = now + 40
    result = sportTelemetryPush(txid, 0x30, 0x0C20, (Hitem * 256) + 0x00FE)
    Hitem = Hitem + 1
    if Hitem > 47 then
      Hitem = 0
    end
  end

  local physicalId, primId, dataId, value = sportTelemetryPop()
  if primId ~= nil then
    if primId == 0x32 then
      if dataId == 0x0C20 then
        svalue = value
        x = bit32.band(value, 0x00FF)
        if x == 0x00FE then
          --value = bit32.band(value, 0x7FFFFFFF)
          value = value / 256
          x = bit32.band(value, 0x00FF)
          value = value / 256
          if x == 0 then
            Uid0 = bit32.band(value, 0x00FF)
            value = value / 256
            Uid1 = bit32.band(value, 0x00FF)
          elseif x < 48 then
            HopChannel[x-1] = bit32.band(value, 0x00FF)
            value = value / 256
            HopCount[x-1] = bit32.band(value, 0x00FF)
          end
        end
      end
    end
  end

  if LCD_W == 480 then
    lcd.drawText(wfpx*4, 0, "CHANNEL HOPPING TABLE", txtSiz)
    lcd.drawText(1, (hfpx/1.41)*2, "  UID               ", smSiz + INVERS)
    lcd.drawNumber(posrep/2.9, (hfpx/1.41)*2, Uid0, smSiz + INVERS + RIGHT)
    lcd.drawNumber(posrep/1.9, (hfpx/1.41)*2, Uid1, smSiz + INVERS + RIGHT)
  else
    lcd.drawText(1, 0, "ID           ", smSiz + INVERS)
    lcd.drawNumber(posrep/4, 0, Uid0, smSiz + INVERS + RIGHT)
    lcd.drawNumber(posrep/2.4, 0, Uid1, smSiz + INVERS + RIGHT)
  end
  i= 0
  for line = -1, 45 do
    displayHop(line)
  end

  if LCD_W > 128 then
    lcd.drawText(LCD_W, 0, "3/3", smSiz_R)
  end
end	-- END Channel Hop Count Page-3 --

local function splash()
  lcd.drawText(midpx-wfpx*5.8, hfpx,"UNI RX Statistics", bigSiz)
  lcd.drawText(midpx-wfpx*3.2, hfpx*3, "(Version: " ..version ..")", smSiz)
  lcd.drawText(midpx-wfpx*6.4, hfpx*4.8,"for UNI-RX Firmware", txtSiz)
  lcd.drawText(xpos_L, hfpxLast, "Dev's Mike Blandford/DW", txtSiz)
  start = start + 1
end

local function pageSwap(event)
  if Page < NrOfPages then
    Page = Page + 1
  else
    Page = 1
  end
end

local function pageBack(event)
  if Page > 1 then
    Page = Page - 1
  else
    Page = NrOfPages
  end
  killEvents(event)
end

-- Initialization table --
local function init()
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

  Mode[0] = "V1-FCC"
  Mode[1] = "V1-EU"
  Mode[2] = "V2-FCC"
  Mode[3] = "V2-EU"

  for i = 0, 11 do    --DW 9->11
    Statistics[i] = 0
    StatRead[i] = 0
  end
  Statistics[8] = -1   -- HF-Mode/Version String

  for i = 0, 46 do
    HopChannel[i] = 0
    HopCount[i] = 0
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
  smSiz_R = smSiz + RIGHT
end

local function run(event)
  lcd.clear()
  if LCD_W == 480 and use_color ~= 0 then
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
      lcd.setColor(CUSTOM_COLOR, BLUE1)
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
      lcd.setColor(CUSTOM_COLOR, BLUE1)
      lcd.drawFilledRectangle(0, 0, LCD_W, 25, CUSTOM_COLOR)        --Title Bar
      lcd.setColor(CUSTOM_COLOR, BLACK)
      lcd.drawRectangle(0, 25, LCD_W, 2, CUSTOM_COLOR, 2)           --Separator Line
    end
  end

  local ver, radio, maj, minor, rev = getVersion()
  if minor >= 3 then
      -- All Radios - Virtual Events
    if event == EVT_VIRTUAL_NEXT_PAGE then pageSwap(event)
    elseif event == EVT_VIRTUAL_PREV_PAGE then pageBack(event)
    end
  else
      -- X9D
    if event == EVT_PAGE_BREAK then pageSwap(event)
    elseif event == EVT_PAGE_LONG then pageBack(event)
      -- X10, X7
    elseif event == EVT_PAGEDN_BREAK then pageSwap(event)
    elseif event == EVT_PAGEDN_LONG then pageBack(event)
      -- X-Lite
    elseif event == 101 then pageSwap(event)
    elseif event == 102 then pageBack(event)
    end
  end

  if start < splashTime then
    splash()
  elseif Page == 1 then
    refreshStats()
    RecStat()
  elseif Page == 2 then
    refreshStats()
    RecInfo()
  elseif Page == 3 then
    hoptable()
  end

  return 0
end
return {run=run, init=init}