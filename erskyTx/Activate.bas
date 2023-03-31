array byte HexText[6]
array byte HexChars[18]
array byte Code[8]

if init = 0
 init = 1
 txid = 0x17
 now = gettime() - 50
 SelectedItem = 0
 keepAlive = 1
 strtoarray( HexChars[0], "0123456789ABCDEF" )
 strtoarray( Code[0], "\x08\x08\x08\x08\x08\x08" )
 Id0Read = 0
 Id1Read = 0
 Id2Read = 0
 Id3Read = 0
 Id4Read = 0
 Id0Value = 0
 Id1Value = 0
 Id2Value = 0
 Id3Value = 0
 Id4Value = 0
 ValidRead = 0
 ValidValue = 0
 SendingCode = 0
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

tohex:
 HexText[0] = HexChars[(hvalue/4096) & 0x0F]
 HexText[1] = HexChars[(hvalue/256) & 0x0F]
 HexText[2] = HexChars[(hvalue/16) & 0x0F]
 HexText[3] = HexChars[(hvalue) & 0x0F]
 HexText[4] = 0
return

upField:
if EditValue
 if (Event = EVT_UP_FIRST) & (sysflags() & 64)
  gosub downField
 else
  if SelectedItem < 6
   x = Code[SelectedItem]
   if x
    x -= 1
   end
   Code[SelectedItem] = x
 	end
 end
else
 if SelectedItem
  SelectedItem -= 1
 else
  SelectedItem = 6
 end
end
return

downField:
if EditValue
 if (Event = EVT_DOWN_FIRST) & (sysflags() & 64)
  gosub upField
 else
  if SelectedItem < 6
   x = Code[SelectedItem]
   if x < 15
    x += 1
   end
   Code[SelectedItem] = x
 	end
 end
else
 SelectedItem += 1
 if SelectedItem > 6
  SelectedItem = 0
 end
end
return

change:
 if SelectedItem = 6
  SendingCode = 3
 else
  if EditValue = 0
   EditValue = 1
  else
   EditValue = 0
  end
 end
return

sendWrite:
 result = sportTelemetrySend( txid, 0x31, 0x0C20, UpdateValue )
 return result
end

refresh:
 if gettime() - now > 60
  now += 60
	keepAlive = 0
	if Id0Read = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x0CFF )
	elseif Id1Read = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x0DFF )
	elseif Id2Read = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x0EFF )
	elseif Id3Read = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x0FFF )
	elseif Id4Read = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0x10FF )
	elseif ValidRead = 0
   result = sportTelemetrySend( txid, 0x30, 0x0C20, 0xEB )
  else
	 i = 0
	end
	if result = 0
   now -= 60
	end
 	if SendingCode > 0
 	 if SendingCode = 3
	  UpdateValue = Code[0] | Code[1] * 256
    UpdateValue *= 65536
	  UpdateValue |= 0xEB
    result = sportTelemetrySend( txid, 0x31, 0x0C20, UpdateValue )
    if result = 1
		 SendingCode = 2
		end
 	 elseif SendingCode = 2
	  UpdateValue = Code[2] | Code[3] * 256
    UpdateValue *= 65536
	  UpdateValue |= 0x01EB
    result = sportTelemetrySend( txid, 0x31, 0x0C20, UpdateValue )
    if result = 1
		 SendingCode = 1
		end
 	 elseif SendingCode = 1
	  UpdateValue = Code[4] | Code[5] * 256
    UpdateValue *= 65536
	  UpdateValue |= 0x02EB
    result = sportTelemetrySend( txid, 0x31, 0x0C20, UpdateValue )
    if result = 1
		 SendingCode = 0
		end
	 end
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
	  if ValidRead = 0 then keepAlive = 1
		x = value & 0x00FF
		if x = 0x00FF
		 temp = value
		 value &= 0x7FFFFFFF
     value /= 256
		 x = value & 0x00FF
     value /= 256
		 if temp & 0x80000000 then value |= 0x8000
		 if x = 12
      Id0Value = value
      Id0Read = 1
		 elseif x = 13
      Id1Value = value
      Id1Read = 1
		 elseif x = 14
      Id2Value = value
      Id2Read = 1
		 elseif x = 15
      Id3Value = value
      Id3Read = 1
		 elseif x = 16
      Id4Value = value
      Id4Read = 1
		 end
		elseif x = 0x00EB
		 value /= 256
		 ValidValue = value & 0x00FF
		 ValidRead = 1
    end
    now = gettime() - 55
   end
  end
  refreshState = 0
 end
return

page0:
 drawtext( 0, 0, "RX SETUP")
// if SelectedItem = 1 then attr = INVERS
// if Id0Read
//  hvalue = Id0Value
//	gosub tohex
//  drawtext( 0, 2*FH, HexText )
// end
 if Id1Read
  hvalue = Id1Value
	gosub tohex
  drawtext( 0*FW, 2*FH, HexText )
 end
 if Id2Read
  hvalue = Id2Value
	gosub tohex
  drawtext( 4*FW, 2*FH, HexText )
 end
 if Id3Read
  hvalue = Id3Value
	gosub tohex
  drawtext( 8*FW, 2*FH, HexText )
 end
// if Id4Read
//  hvalue = Id4Value
//	gosub tohex
//  drawtext( 16*FW, 2*FH, HexText )
// end
 drawtext( 0, 4*FH, "Code:" )

 i = 0
 while i < 6
  attr = 0
	if SelectedItem = i then attr = INVERS
  drawtext( FW*(i+6), 4*FH, HexChars[Code[i]], attr, 1 )
	i += 1
 end

 attr = 0
 if SelectedItem = 6 then attr = INVERS
 drawtext( 0, 6*FH, "Send", attr )

 if ValidRead = 1
  if ValidValue > 0
   drawtext( 0, 3*FH, "Activated", attr )
	else
   drawtext( 0, 3*FH, "Locked", attr )
	end
 end

return

main:
 drawclear()
 if Event = EVT_MENU_BREAK
  gosub change
 elseif Event = EVT_BTN_BREAK
 	gosub change
 end
 if Event = EVT_EXIT_BREAK then goto done
 if Event = EVT_UP_FIRST then gosub upField
 if Event = EVT_LEFT_FIRST then gosub upField
 if Event = EVT_DOWN_FIRST then gosub downField
 if Event = EVT_RIGHT_FIRST then gosub downField
 if Event = 0x81 then goto done
 
 gosub refresh
 gosub page0

stop
done:
finish

