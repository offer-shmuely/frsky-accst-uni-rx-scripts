array byte Bits[10]
array byte OnOff[7]
array Statistics[10]
array byte StatRead[10]
array byte Map[16]
array byte Names[68]
array byte Nindex[10]
array byte Mode[25]

if init = 0
 init = 1
 txid = 0x17
 now = gettime() - 50
 item = 0
 Sitem = 0
 Rate = -1
 Crates = 0
// SportOn = 0
 Chans9_16 = -1
// Sbus8Value = 0
 Sbus4Value = -1
 Sbus8Value = -1
 FbusValue = -1
 TuneValue = 0
 TuneOffset = -1
// InvertSbusValue = 0
 InvSbusValue = -1
 CratesRead = 0
// SPortRead = 0
// ChansRead = 0
// Sbus8Read = 0
 MapEnable = -1
// TuneOffRead = 0
// Sbus4Read = 0
 TuneRead = 0
 D8cppmValue = -1
 CppmValue = -1
// InvertSbusRead = 0
 Page = 0
 SelectedItem = 0
 keepAlive = 1
 strtoarray( Bits[0], "\x01\x02\x04\x08\x10\x20\x40\x80" )
 strtoarray( OnOff[0], "OFF ON" )
 strtoarray( Names[0], "D8R/D4R\0X8R/X6R\0X4R/X4R-SB\0RX8R-PRO\0RX8R\0RX4R/6 G-RX6\0XSR\0R-XSR" )
 strtoarray( Nindex[0], "\x00\x08\x10\x1b\x24\x29\x36\x3a" )
 strtoarray( Mode[0], "V1FCC V1EUV2FCC V2EU" )
 Hitem = 0
 Uid0 = 0
 Uid1 = 0
 Stat7Value = -1
 Stat8Value = -1
 Stat9Value = -1
 Resetting = 0
 Rxtype = 0
 FbusOK = 0
 i = 0
 while i < 16
  Map[i] = 0xFF
  i += 1
 end
 if LCD_W > 500
	FH = 32
	FW = 18
  EVT_MENU_BREAK = EVT_BTN_BREAK
  EVT_MENU_LONG = EVT_BTN_LONG
	XW = 42
 else
  if LCD_W > 220
	 FH = 16
	 FW = 12
	 XW = 28
   EVT_MENU_BREAK = EVT_BTN_BREAK
   EVT_MENU_LONG = EVT_BTN_LONG
  else
	 FH = 8
	 FW = 6
	 XW = 14
  end
 end
end

goto main

upField:
 if Page = 0
  limit = 6
	if FbusOK = 0 then limit = 5
	if Rxtype = 0 then limit = 7
  if SelectedItem
   SelectedItem -= 1
  else
   SelectedItem = limit
  end
 elseif Page = 1
  if SelectedItem
   SelectedItem -= 1
  else
   SelectedItem = 9
  end
 else
  if EditValue
   x = Map[SelectedItem-2]
   if x
    x -= 1
   end
   Map[SelectedItem-2] = x
  else
   if SelectedItem
    SelectedItem -= 1
   else
    SelectedItem = 17
   end
  end
 end
end
return

downField:
 if Page = 0
  limit = 6
	if FbusOK = 0 then limit = 5
	if Rxtype = 0 then limit = 7
  SelectedItem += 1
  if SelectedItem > limit
   SelectedItem = 0
  end
 elseif Page = 1
  SelectedItem += 1
  if SelectedItem > 9
   SelectedItem = 0
  end
 else
  if EditValue
   x = Map[SelectedItem-2]
   if x < 15
    x += 1
   end
   Map[SelectedItem-2] = x
  else
   SelectedItem += 1
   if SelectedItem > 17
    SelectedItem = 0
   end
  end
 end
end
return

change:
 now = gettime()
 if Page = 0
  if SelectedItem = 0
   Resetting = 1
  elseif SelectedItem = 1
   if TuneValue
    newValue = 0x00E5
   else
    newValue = 0x01E5
   end
   TuneRead = 0
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
  elseif SelectedItem = 2
   if Chans9_16
    newValue = 0x00E0
   else
    newValue = 0x01E0
   end
	 Chans9_16 = -1
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )

  elseif SelectedItem = 3
   if Rxtype = 0
		if CppmValue
     newValue = 0x00E3
    else
     newValue = 0x01E3
    end
		CppmValue = -1
	 else
		if Sbus4Value
     newValue = 0x00E2
    else
     newValue = 0x01E2
    end
		Sbus4Value = -1
	 end		
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )

  elseif SelectedItem = 4
   if Rxtype = 0 | Rxtype = 3 | Rxtype = 5 | Rxtype = 7
    if InvSbusValue
     newValue = 0x00EA
    else
     newValue = 0x01EA
    end
 	 InvSbusValue = -1
    result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
   end
  elseif SelectedItem = 5
   if Rxtype = 0
    if D8cppmValue
     newValue = 0x00ED
    else
     newValue = 0x01ED
    end
  	 D8cppmValue = -1
	 elseif Rxtype = 2 | Rxtype = 7
    if CppmValue
     newValue = 0x00E3
    else
     newValue = 0x01E3
    end
  	 CppmValue = -1
   end
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
  elseif SelectedItem = 6
   if Rxtype = 0
		if Sbus4Value
     newValue = 0x00E2
    else
     newValue = 0x01E2
    end
		Sbus4Value = -1
    result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
	 elseif FbusOK
    if FbusValue
     newValue = 0x00EC
    else
     newValue = 0x01EC
    end
  	FbusValue = -1
    result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
	 end	
  elseif SelectedItem = 7
	 if Sbus8Value
    newValue = 0x00E1
   else
    newValue = 0x01E1
   end
	 Sbus8Value = -1
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
	end
 elseif Page = 1
	if SelectedItem = 0
   if Rate
    newValue = 0x00E6
   else
    newValue = 0x01E6
   end
   Rate = -1
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
  else
   if SelectedItem = 9
  	 bit = 0x100
	 else
    bit = Bits[SelectedItem-1]
   end
   newValue = Crates ^ bit
   newValue *= 256
   newValue |= 0xE7
   CratesRead = 0
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
	end
 else	
	if SelectedItem = 0
   if MapEnable & 1
		 MapEnable &= 2
		else
		 MapEnable |= 1
   end
   newValue = ( MapEnable * 256) | 0x00E8
	 MapEnable = -1
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
  elseif SelectedItem = 1
   if MapEnable & 2
		 MapEnable &= 1
		else
		 MapEnable |= 2
   end
   newValue = ( MapEnable * 256) | 0x00E8
	 MapEnable = -1
   result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
  else
   if EditValue = 0
	  EditValue = 1
	  OldValue = Map[SelectedItem-2]
	 else
    EditValue = 0
	  index = SelectedItem-2
	  if OldValue # Map[index]
     newValue = 0xE9 | (index*256)
     newValue |= Map[index] * 65536
		 Map[index] = 0xFF
     result = sportTelemetrySend( txid, 0x31, 0x0C20, newValue )
		end
   end
  end
 end
 now += 60
return

sendWrite:
 result = sportTelemetrySend( txid, 0x31, 0x0C20, UpdateValue )
 return result
end

refreshresetting:
 drawtext( 0, 0, "RX SETUP")
 drawtext( 0, FH, "Resetting")
 drawnumber( 3*FW, 3*FH, 28-Resetting)
 if gettime() - now > 60
	now += 60
	if Resetting = 5
	 Resetting = 6
	 UpdateValue = 0x01E5
	 gosub sendWrite
	elseif Resetting < 5
	 UpdateValue = 0x00DF + Resetting
	 Resetting += 1
	 gosub sendWrite
  elseif Resetting < 9
	 UpdateValue = 0x00E0 + Resetting
	 Resetting += 1
	 gosub sendWrite
  elseif Resetting = 9
   Resetting = 10
	 UpdateValue = 0x00EA
	 gosub sendWrite
  elseif Resetting = 10
   Resetting = 11
	 UpdateValue = 0x00ED
	 gosub sendWrite
	elseif Resetting < 27
	 ti = Resetting - 11
	 Resetting += 1
	 newValue = 0xE9
	 ti += ti * 256
 	 newValue |= ti * 256
	 UpdateValue = newValue
	 gosub sendWrite
	elseif Resetting = 27 & FbusOK
	 Resetting = 28
	 UpdateValue = 0x00EC
	 gosub sendWrite
	else	
	 Resetting = 0
	 Sbus4Value = -1
	 Sbus8Value = -1
	 TuneRead = 0
	 Chans9_16 = -1
   Rate = -1
	 CratesRead = 0
	 MapEnable = -1
   InvSbusValue = -1
	 TuneOffset = -1
   FbusValue = -1
   D8cppmValue = -1
   CppmValue = -1
	 i = 0
	 while i < 16
	  Map[i] = 0xFF
	  i += 1
	 end
	end
 end
end
return

displayPage:
 drawtext( 19*FW, 0, "/3" )
 drawnumber( 19*FW, 0, Page+1)
return

display9_18:
 svalue = 18
 if item = 9
  bit = 0x100
 else
  bit = Bits[item-1]
 end
 if Crates & bit then svalue = 9
 attr = 0
 if SelectedItem = item then attr = INVERS
 drawnumber( item*2*FW, FH*3, svalue, attr )
return

displayName:
 item = Nindex[item]
 drawtext( x, y, Names[item], 0x8000 )
return

refresh:
 if gettime() - now > 60
  now += 60
	keepAlive = 0
	if Stat8Value = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x08FF )
  elseif Stat7Value = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x07FF )
	elseif Stat9Value = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x09FF )
	elseif Rate = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE6 )
	elseif CratesRead = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE7 )
  elseif Chans9_16 = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE0 )
	elseif Sbus4Value = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE2 )
	elseif Sbus8Value = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE1 )
	elseif TuneOffset = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE4 )
  elseif CppmValue = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE3 )
	elseif TuneRead = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE5 )
	elseif MapEnable = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE8 )
	elseif InvSbusValue = -1
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xEA)
  else
	 if Rxtype = 0 & D8cppmValue = -1
     result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xED)
   elseif FbusValue = -1 & FbusOK
     result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xEC)
	 else
 	  i = 0
loop1:
	  if Map[i] = 0xFF
     result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xE9 | (i*256) )
		 goto break1
	  end
	  i += 1
	  if i < 16 then goto loop1
break1:
	 end
	end
	
	if result = 0
   now -= 60
	end
 else
 	if keepAlive
   result = sportTelemetrySend( txid, 0, 0, 0 )
  end
 end
 result = sportTelemetryReceive( physicalId, primId, dataId, value )
 if result > 0
  if primId = 0x32
   if dataId = 0x0C20
	  if TuneRead = 0 then keepAlive = 1
		x = value & 0x00FF
		if x = 0x00FF
		 temp = value
		 value &= 0x7FFFFFFF
     value /= 256
		 x = value & 0x00FF
     value /= 256
		 if temp & 0x80000000 then value |= 0x800000
		 if x = 8
			Stat8Value = value
		 elseif x = 9
		  Stat9Value = value
		 elseif x = 7
      Stat7Value = value
		 end
		elseif x = 0x00E6
		 value /= 256
		 Rate = value & 0x00FF
		elseif x = 0x00E7
     value /= 256
		 Crates = value & 0x01FF
     CratesRead = 1
		elseif x = 0x00E0
  	 value /= 256
	   Chans9_16 = value & 0x00FF
		elseif x = 0x00E2
  	 value /= 256
	   Sbus4Value = value & 0x00FF
		elseif x = 0x00E1
  	 value /= 256
	   Sbus8Value = value & 0x00FF
		elseif x = 0x00E3
  	 value /= 256
	   CppmValue = value & 0x00FF
		elseif x = 0x00E4
  	 value /= 256
		 TuneOffset = value & 0x00FF
		elseif x = 0x00E5
  	 value /= 256
	   TuneValue = value & 0x00FF
		 TuneRead = 1
		elseif x = 0x00E8
  	 value /= 256
		 MapEnable = value & 0x00FF
		elseif x = 0x00EA
  	 value /= 256
		 InvSbusValue = value & 0x00FF
		elseif x = 0x00ED
  	 value /= 256
		 D8cppmValue = value & 0x00FF
		elseif x = 0x00EC
  	 value /= 256
		 FbusValue = value & 0x00FF
		else
		 if x = 0x00E9
  	  value /= 256
		  x = value & 0x00FF
      value /= 256
			if x < 16
			 Map[x] = value
			end
		 end
    end
    now = gettime() - 55
   end
  end
  refreshState = 0
 end
// drawtext( 0, 0, "Enable Rate 9 mS     " )
return

page0:
 drawtext( 0, 0, "RX SETUP")
 gosub displayPage
 FbusOK = 0
 if Rxtype & Stat7Value >= 80 then FbusOK = 1
 attr = 0
 if SelectedItem = 0
	attr = INVERS
 end
 drawtext( 10*FW, 0, "RESET", attr )

 if Stat9Value > 0
  x = 0
	y = FH
	item = Stat9Value - 1
	Rxtype = item
  gosub displayName
 end

 if Stat7Value > 2
  drawtext( 18*FW, FH, "v", 0 )
  drawnumber( 21*FW, FH, Stat7Value, 0 )
 end

 if Stat8Value # -1
  drawtext( 12*FW, FH, Mode[Stat8Value*5], 0, 5)
 end

 drawtext( 0, 2*FH, "Auto Tuning" )
 attr = 0
 if SelectedItem = 1 then attr = INVERS
 if TuneRead
  drawtext( 18*FW, 2*FH, OnOff[TuneValue*3], attr, 3)
 end
 if TuneOffset # -1
	tvalue = TuneOffset
	if tvalue > 128
	 tvalue -= 256
	end
	drawnumber(15*FW, 2*FH, tvalue, 0)
 end

 attr = 0
 if SelectedItem = 2 then attr = INVERS
 drawtext( 0, 3*FH, "Servo Outputs" )
 if Chans9_16 # -1
  drawtext( 17*FW, 3*FH, " 1-89-16"[Chans9_16*4], attr, 4)
 end

 attr = 0
 if SelectedItem = 3 then attr = INVERS
 if Rxtype = 0
  drawtext( 0, 4*FH, "Enable SPort" )
  if CppmValue # -1
    drawtext( 18*FW, 4*FH, OnOff[CppmValue*3], attr, 3)
	end
 else
  drawtext( 0, 4*FH, "Servo on SBUS" )
  if Sbus4Value # -1
   drawtext( 18*FW, 4*FH, OnOff[Sbus4Value*3], attr, 3)
	end
 end			

 attr = 0
 if SelectedItem = 4 then attr = INVERS
 drawtext( 0, 5*FH, "Invert SBUS" )
 if Rxtype = 0 | Rxtype = 3 | Rxtype = 5 | Rxtype = 7
  if InvSbusValue # -1
   drawtext( 18*FW, 5*FH, OnOff[InvSbusValue*3], attr, 3)
  end
 else
  drawtext( 18*FW, 5*FH, "N/A", attr)
 end
 
 attr = 0
 if SelectedItem = 5 then attr = INVERS
 drawtext( 0, 6*FH, "CPPM Enable" )
 if Rxtype = 0
  if D8cppmValue # -1
   drawtext( 18*FW, 6*FH, OnOff[D8cppmValue*3], attr, 3)
  end
 elseif Rxtype = 2 | Rxtype = 7
  if CppmValue # -1
   drawtext( 18*FW, 6*FH, OnOff[CppmValue*3], attr, 3)
  end
 else
  drawtext( 18*FW, 6*FH, "N/A", attr)
 end
 
 attr = 0
 if SelectedItem = 6 then attr = INVERS
 if Rxtype = 0
  drawtext( 0, 7*FH, "SBUS on C4     C8" )
  if Sbus4Value # -1
   drawtext( 11*FW, 7*FH, OnOff[Sbus4Value*3], attr, 3)
  end
  if Sbus8Value # -1
   attr = 0
   if SelectedItem = 7 then attr = INVERS
   drawtext( 18*FW, 7*FH, OnOff[Sbus8Value*3], attr, 3)
  end
 elseif FbusOK
  drawtext( 0, 7*FH, "FBUS" )
  if FbusValue # -1
   drawtext( 18*FW, 7*FH, OnOff[FbusValue*3], attr, 3)
  end
 end 
return

displayMap:
 x = item+1
 y = 4*FH
 if item > 7
  y = 6*FH
	x -= 8
 end
 x *= XW
 attr = 0
 if SelectedItem - 2 = item
  attr = INVERS
  if EditValue
   attr |= BLINK
	end
 end
 drawtext( x-XW, y, "  " )
 if Map[item] # 0xFF
  drawnumber( x, y, Map[item]+1, attr )
 end
return

page1
 drawtext( 0, 0, "RX SETUP")
 gosub displayPage
 drawtext( 0, FH, "9mS Enable           " )
 drawtext( 1, 2*FH, " 1 2 3 4 5 6 7 8 9 " )
 attr = 0
 if SelectedItem = 0 then attr = INVERS
  if Rate # -1
   drawtext( 17*FW, FH, OnOff[Rate*3], attr, 3)
  end
 if CratesRead
  item = 1
  gosub display9_18
  item = 2
  gosub display9_18
  item = 3
  gosub display9_18
  item = 4
  gosub display9_18
  item = 5
  gosub display9_18
  item = 6
  gosub display9_18
  item = 7
  gosub display9_18
  item = 8
  gosub display9_18
  item = 9
  gosub display9_18
 else
  drawtext( 0, 2*FH, "                     " )
 end
return

page2:
 gosub displayPage
 drawtext( 0, FH, "Enable Servo Map     " )
 drawtext( 0, 2*FH, "Enable SBUS Map      " )

 attr = 0
 if SelectedItem = 0 then attr = INVERS
 if MapEnable # -1
  drawtext( 17*FW, FH, OnOff[(MapEnable & 1)*3], attr, 3)
 end

 attr = 0
 if SelectedItem = 1 then attr = INVERS
 if MapEnable # -1
  temp = MapEnable / 2
  drawtext( 17*FW, 2*FH, OnOff[temp*3], attr, 3)
 end

 drawtext( FW/2, 3*FH, " 1" )
 drawtext( 3*FW-1, 3*FH, " 2" )
 drawtext( 5*FW+1, 3*FH, " 3" )
 drawtext( 15*FW/2, 3*FH, " 4" )
 drawtext( 10*FW-1, 3*FH, " 5" )
 drawtext( 12*FW+1, 3*FH, " 6" )
 drawtext( 29*FW/2, 3*FH, " 7" )
 drawtext( 17*FW-1, 3*FH, " 8" )
 drawtext( FW/2, 5*FH, " 9" )
 drawtext( 3*FW-1, 5*FH, "10" )
 drawtext( 5*FW+1, 5*FH, "11" )
 drawtext( 15*FW/2, 5*FH, "12" )
 drawtext( 10*FW-1, 5*FH, "13" )
 drawtext( 12*FW+1, 5*FH, "14" )
 drawtext( 29*FW/2, 5*FH, "15" )
 drawtext( 17*FW-1, 5*FH, "16" )

 item = 0
 gosub displayMap
 item = 1
 gosub displayMap
 item = 2
 gosub displayMap
 item = 3
 gosub displayMap
 item = 4
 gosub displayMap
 item = 5
 gosub displayMap
 item = 6
 gosub displayMap
 item = 7
 gosub displayMap

 item = 8
 gosub displayMap
 item = 9
 gosub displayMap
 item = 10
 gosub displayMap
 item = 11
 gosub displayMap
 item = 12
 gosub displayMap
 item = 13
 gosub displayMap
 item = 14
 gosub displayMap
 item = 15
 gosub displayMap

return


pageSwap:
 Page += 1
 if Page > 2
  Page = 0
 end
 killevents(Event)
 Event = 0
 drawclear()
 SelectedItem = 0
return

main:
 drawclear()
 if Event = EVT_MENU_LONG
  gosub pageSwap
 elseif Event = EVT_BTN_LONG
 	gosub pageSwap
 elseif Event = EVT_PAGE_BREAK 
  if Event then gosub pageSwap
 end
 if Event = EVT_MENU_BREAK
  gosub change
 elseif Event = EVT_BTN_BREAK
 	gosub change
 end
 if Event = EVT_EXIT_BREAK then goto done
 if Event = EVT_UP_FIRST then gosub upField
 if Event = EVT_LEFT_FIRST
  if EVT_PAGE_FIRST = 0 then gosub upField
 end
 if Event = EVT_DOWN_FIRST then gosub downField
 if Event = EVT_RIGHT_FIRST then gosub downField
 if Event = EVT_ROT_LEFT then gosub upField
 if Event = EVT_ROT_RIGHT then gosub downField
 if Event = 0x81 then goto done
 
 if Resetting > 0
  gosub refreshresetting
 else 
 	if Page = 0
   gosub refresh
	 gosub page0
	elseif Page = 1
   gosub refresh
	 gosub page1
	else
   gosub refresh
	 gosub page2
	end
 end

 rssi = getvalue("RSSI")
 if rssi = 0
	Resetting = 0
  Stat7Value = -1
	Stat9Value = -1
	Sbus4Value = -1
	Sbus8Value = -1
	TuneRead = 0
	Chans9_16 = -1
  Rate = -1
	CratesRead = 0
	MapEnable = -1
  InvSbusValue = -1
  TuneOffset = -1
  CppmValue = -1
  D8cppmValue = -1
	i = 0
	while i < 16
	 Map[i] = 0xFF
	 i += 1
	end
 end

stop
done:
finish

// Rx setup 1/3
// status
//Default Settings
//Auto Tuning
// Servo Ouptuts
//Servo on SBUS
// Invert SBUS
//CPPM Output Enable
