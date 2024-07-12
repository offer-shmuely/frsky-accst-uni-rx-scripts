// SxR, configuration program for use with the firmware developed by Mike Blandford


if init = 0
 init = 1
// version = "1"
 splashTime = 300
 txid = 0x17
 midpx = LCD_W / 2
 start = 0
 State = 0
 EnterPressed = 0
 Value = 0
 wfpx = 6
 if LCD_H = 64
  hfpx = 8
  hfpxLast = hfpx*7
 else
  hfpx = LCD_H/10
  hfpxLast = hfpx*9
 end
 if LCD_W >= 480
  posrep = LCD_W*425/1000
  if LCD_W = 800
   wfpx = 28
  else
   wfpx = 9
  end
 else
  posrep = 90
  wfpx = 8
 end
end

goto main

sendWrite:
 sportTelemetrySend( txid, 0x31, 0x0c30, Value)
return

refreshSetup:
 drawtext( midpx-wfpx*5, 0, "CALIBRATION" )
 if State = 0
  drawtext(midpx-wfpx*7, hfpx*2, "Place Horizontally")
  drawtext(1, hfpx*4, "Press Menu to start")
  if EnterPressed = 1
   EnterPressed = 0
   State = 1
	 Value = 0x01AF
	 gosub sendWrite
	end
 end
 if State = 1
  drawtext(midpx-wfpx*34/10, hfpx*2, "Calibrating")
  result = sportTelemetryReceive( physicalId, primId, dataId, value )
  if primId = 0x32
   if dataId = 0x0C30
    x = value & 0x00FF
    value /= 256
    if x = 0x00AF
     x = value & 0x00FF
     if x = 1
			 State = 2
     end
    end
   end
  end
 end
 if State = 2
  drawtext(midpx-wfpx*54/10, hfpx*2, "Place Vertically")
  drawtext(1, hfpx*4, "Press Menu")
  if EnterPressed = 1
	 EnterPressed = 0
   State = 3
	 Value = 0x02AF
	 gosub sendWrite
	end
 end
 if State = 3
  drawtext(midpx-wfpx*34/10, hfpx*2, "Calibrating")
  result = sportTelemetryReceive( physicalId, primId, dataId, value )
  if primId = 0x32
   if dataId = 0x0C30
    x = value & 0x00FF
    value /= 256
    if x = 0x00AF
      x = value & 0x00FF
      if x = 2
			 State = 4
	     Value = 0x03AF
	     gosub sendWrite
      end
     end
    end
   end
  end
 end
 if State = 4
  drawtext(midpx-wfpx*34/10, hfpx*2, "Centre Sticks")
  drawtext(1, hfpx*4, "Press Menu")
  if EnterPressed = 1
   EnterPressed = 0
   State = 5
	 Value = 0x04AF
	 gosub sendWrite
  end
 end
 if State = 5
  drawtext(midpx-wfpx*54/10, hfpx*2, "Calibrate Channels")
  drawtext(1, hfpx*3, "Move sticks to give")
  drawtext(1, hfpx*4, "Full Servo Deflection")
  drawtext(1, hfpx*6, "Press Menu")
  if EnterPressed = 1
   EnterPressed = 0
   State = 6
	 Value = 0x05AF
	 gosub sendWrite
  end
 end
 if State = 6
	drawtext(midpx-wfpx*3, hfpx*2, "Completed")
 end
return

change:
  EnterPressed = 1
return

main:
 drawclear()

//  local ver, radio, maj, minor, rev = getVersion()
//  if minor >= 3 then
//      -- All Radios - Virtual Events
// if Event = EVT_VIRTUAL_ENTER
//  gosub change
//    end
// else
//      -- X9D
  if Event = EVT_MENU_BREAK
   gosub change
	end
// end

 if start < splashTime
  drawtext(midpx-wfpx*48/10, hfpx,"SxR Setup")
  drawtext(midpx-wfpx*32/10, hfpx*3, "(Version: 1)")
  drawtext(midpx-wfpx*64/10, hfpx*48/10,"for UNI-RX Firmware")
  drawtext(xpos_L, hfpxLast, "Developer MikeBlandford")
  start += 1
 else
  gosub refreshSetup
 end

stop
done:
finish










