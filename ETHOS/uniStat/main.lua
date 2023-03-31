--[[
###################################################################################
#######															#######
#######		    					"UNIstat" 						#######
#######	  		an ETHOS lua widget to monitor UNI-ACCST Receivers			#######
#######															#######
#######	    		a Rx Firmware Project mainly driven by					#######
#######			 Mike Blandfort, Engel Modellbau and Aloft Hobby			#######
#######		   thanks to all who gave valuable information & inputs 		#######
#######															#######
#######															#######
#######															#######
#######	 Rev 1.1 RC1	20 Oct 2022 (changed X4r..)						#######
#######	 Rev 1.2		01 Nov 2022 (changed timing, X4r..)					#######
#######	 														#######
#######	 coded by Udo Nowakowski										#######
###################################################################################

		This program is free software: you can redistribute it and/or modify
		it under the terms of the GNU General Public License as published by
		the Free Software Foundation, either version 3 of the License, or
		(at your option) any later version.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program.  If not, see <https://www.gnu.org/licenses/>.
		
		Rev 1.0 RC1 		220510	first release candidate
		Rev 1.1 RC1		221020	(changed SPORT timing, X4r..)	
		Rev 1.2 			221104	more conservative timing
*************************************************************************************  							
]]





																			-- ************************************************
																			-- ***		      language handling				*** 
																			-- ************************************************
																			
local locale = system.getLocale()

local lan																			-- determine language
  if locale =="de" then
	lan = 1
  --  elseif locale == "fr" then lan = 3											-- to be expanded / more languages
  else
    lan = 2 																		-- not supported language, so has to be "en" 
  end

local translations = {de="UNI-Rx Statistik 1.2", en="UNI-Rx Statistics 1.2"}		-- header list
local	txtFields,optionLan,header = dofile("lang.lua")								-- get language file





																			-- ************************************************
																			-- ***		     name widget					*** 
																			-- ************************************************
local function name(widget)					-- name script
	 return translations[locale] or translations["en"]
end



																			-- ************************************************
																			-- ***		     some definitions				*** 
																			-- ************************************************

local debug0 <const> 		= false			-- debug level 0, basic
local debug1 <const> 		= false			-- monitor sport2form
local debug2 <const> 		= false			-- monitor sport
local debug3 <const> 		= false			-- paint
local debug4 <const> 		= true			-- sport timeout
local debug5 <const> 		= true			-- sport request
local debug6 <const> 		= true			-- sport answere
local debug7 <const> 		= false			-- write

local pushTime=0
local time_Out								-- timestamp timeout reading item
--local lan = 2								-- language


local UPD_Interval <const>			= 14			-- value update Interval in (sec)
local SPORT_TIMEOUT <const>			= 0.67		-- timeout after request was pushed  (sec)
-- local SPORT_REQUESTINTERVAL <const>		= 0.7		-- minimum Uni request interval (fix)
local APP_ID <const>					= 0x0C20	-- classic Rx type (Sx=0x0C30)
local READREQUEST <const>			= 0x30		-- SPort Read
local WRITEREQUEST <const>			= 0x31		-- SPort WRITE

local SPORT_REQUESTINTERVAL 			= SPORT_TIMEOUT + 0.05		-- minimum Uni request interval (fix)

local COLOR_STD <const>			= WHITE							-- standard text color
local COLOR_COL1 <const>		= lcd.RGB(100, 100, 100)		-- color: values outdated


local formtxt = {
	{name="Zeichengroesse"}
	}




																			-- ************************************************
																			-- ***		     yaapus getime workaround		*** 
																			-- ************************************************
local function getTime()
  return os.clock()		 
end



																			-- ************************************************
																			-- *****   workaround missing bit32 lib     *******
																			-- ************************************************
local function bitband_FF(value)
	--value = value-math.floor(value/256)*256
	value = value&0x00FF
	return value
end
																			-- ************************************************
																			-- ***		  map form txtsize to fontsize		*** 
																			-- ************************************************
local function evalFontsize(num)
	if num == 0 then
		return(FONT_XS)
	elseif num == 1 then
		return(FONT_S)
	elseif num == 2 then
		return(FONT_STD)
	elseif num == 3 then
		return(FONT_XL)
	else 
		return(FONT_XXL)
	end
end
																			-- ************************************************
																			-- ***		  eval pixel height of txt			*** 
																			-- ************************************************
local function evalPixel(num)
-- X20:  XS:9  S:11  Std:18  L:26  XL:34   XXL:44
  
	if num == 0 then			-- size XS
		return(9) --XS
	elseif num == 1 then			-- size S
		return(11)-- S
	elseif num == 2 then			-- size M
		return(18)--Std
	elseif num == 3 then			-- size XL
		return(34)--XL
		--return(26)-- L
	else					-- size XXL
		return(44)--XXL
	end
end
																			-- ************************************************
																			-- ***		  create bool formline				*** 
																			-- ************************************************
local function createBooleanField(widget, line, index)
	local field = form.addBooleanField(line, nil, function() return widget.stats[index].config end, function(value) widget.stats[index].config=value end)
	return field
end



																			-- ************************************************
																			-- ***	check antenna overflow condition		*** 
																			-- ************************************************
local function checkOverflow(widget,i,index)
		
	if ((widget.status.lastsign[index] and widget.callItem[i].val < 0) or (not(widget.status.lastsign[index]) and widget.callItem[i].val > 0))  then -- overflow detected
		widget.status.lastsign[index] = not(widget.status.lastsign[index])
		widget.status.baseval[index] = widget.status.baseval[index] + 32468	
	end

	if widget.status.lastsign[index] then																-- standard mode
		return( widget.status.baseval[index] + widget.callItem[i].val )  
	else																								-- overflow mode
		return(widget.status.baseval[index] + 32468 + widget.callItem[i].val  )
	end
end
																			-- ************************************************
																			-- ***		     "display handler"					*** 
																			-- ************************************************
local function paint(widget)
	local tmpRssi = system.getSource("RSSI")
	local txt_h																				-- height of a line
	local line 
	local dispValue
	local lcd_w, lcd_h = lcd.getWindowSize()
	
	local numLine = math.floor(lcd_h / widget.txtpixel)										-- eval number of lines
	if numLine > widget.config.numItems then numLine = widget.config.numItems end
	txt_h = math.floor(lcd_h / numLine)											
	line = 1																				-- display statistics
	lcd.font(widget.fontsize)

	
	
	for i = 1,widget.config.numItems do														-- loop all items
		lcd.color(widget.colTxt)															-- type item name
		lcd.drawText(0, (i-1)*txt_h, widget.callItem[i].name)	
		lcd.color(widget.colNum)
		
		if widget.callItem[i].kind == "Choice" then											--	special handling >> value "translation" etc
			local tmp=widget.callItem[i].val
			if widget.callItem[i].index == 9 then													-- item "9" without 0-value (only needed by program start)
				tmp=tmp+1
			end
			lcd.color(widget.colNum)
			if tmp==0 and widget.callItem[i].index==10 then											-- exeption handling
				lcd.drawText(lcd_w, (i-1)*txt_h, "NIL",RIGHT)	
			else																					-- print "choice translations" 
				lcd.drawText(lcd_w, (i-1)*txt_h, widget.stats[widget.callItem[i].index].options[tmp][1],RIGHT)
				if debug3 then print(widget.callItem[i].name, widget.stats[widget.callItem[i].index].options[tmp][1]) end
			end
		
		else
		
			dispValue = widget.callItem[i].val
			if widget.callItem[i].index == 11 or widget.callItem[i].index == 12 then			-- special handling >>ant counter (check overflow)
				dispValue = (checkOverflow(widget,i,(widget.callItem[i].index-10)))					-- widget, item#, ant#
			end
																								-- pure number (std mode)
			lcd.drawNumber(lcd_w, (i-1)*txt_h, dispValue,0,0,RIGHT)
			if debug3 then print(widget.callItem[i].name, dispValue) end
		end
		
		
	end
	
end



																			-- ************************************************
																			-- ***		  read data item					*** 
																			-- ************************************************
local function refreshStats(widget)


		local item = widget.status.activeItem
		local frame	
		local nextStep=getTime()+SPORT_REQUESTINTERVAL
		if widget.status.ItemPush == false and getTime()>pushTime then										-- was item requested before ? if not ....
			local status = widget.sensor:pushFrame({primId=READREQUEST, appId=APP_ID, value=widget.callItem[item].d_item})	-- ... request (primId=0x31) item (widget.callItem[i].d_item)
			widget.status.ItemPush = true																	-- reset status
			time_Out = getTime() + SPORT_TIMEOUT															-- set timeout
			pushTime = getTime() + SPORT_REQUESTINTERVAL													-- next request
			if debug5 then print("SPort: request",widget.callItem[item].name," ",(pushTime-SPORT_REQUESTINTERVAL),"was",status) end	-- ... request (primId=0x31) item (widget.callItem[i].d_item)
		end		
		


		if 	widget.status.ItemPush then														-- detect "request was send"
			frame = widget.sensor:popFrame(widget)											-- read queue
			local readTime=getTime()
			if readTime < time_Out then
		  
				if frame ~= nil then															-- check valid data
					local value = frame:value()						
					local appl_id=frame:appId()	
					local fieldId 

					if appl_id == APP_ID then													-- check right app id
																								-- **** evaluate fieldID (d_item) ****																					
						if value % 256	== 0xFF then											-- extracted dataitem from package Rx "Stat" item
							fieldId = value&0xFFFF
							if value >  widget.callItem[item].d_item then						-- ditem rx Protocol/type  is 2 byte
								fieldId = value&0xFFFF
							end
							--if debug2 then print(" sport:   Frame got RawValue, fieldId, DataItem ", string.format("%X",value),string.format("%X",fieldId),string.format("%X",widget.callItem[item].d_item)) end
						else
							fieldId = value % 256
						end
				
																										-- **** eval Data in case you got right frame ****
								
						if fieldId == widget.callItem[item].d_item then									-- received dataItem = requested item ?
							local value2=value
							value = math.floor((value-widget.callItem[item].d_item)/(256*256))			-- extract value from package				
							widget.callItem[item].val = value
							widget.status.activeItem = widget.status.activeItem+1						-- prepare to get next item					
							widget.status.ItemPush = false	
						
							if debug6 then print("SPORT: readOK ",widget.callItem[item].name," ",readTime,"VAL:",value) end	
							if debug6 then print("----------") end	
							--if widget.callItem[item].index == 11 or widget.callItem[item].index == 12 thenein weni
							--	print(widget.callItem[item].index,widget.callItem[item].val)
							--end			
						end
		
		
					end
				end
			else																			-- **** timeout ?  >> reset request
				if debug4 then print("SPORT: ---   timeout  ----",widget.callItem[item].name,(pushTime-SPORT_REQUESTINTERVAL),getTime() ) end
				widget.status.ItemPush = false	
				widget.status.activeItem = widget.status.activeItem+1
			end

			if widget.status.activeItem > widget.config.numItems then				-- last item reached...
				widget.status.BlockInProgress = false								-- so reset "block request"
				widget.flag_outd = true
				--widget.sensor:idle()												-- deactivate sensor
				widget.status.activeItem = 1										-- startposition next run
				widget.colNum = COLOR_COL1											-- set "dark" color 
				widget.status.timeStamp1 = getTime()+0.5							-- set time /highlight values
				lcd.invalidate()													-- print values in "darkmode" (outdated values)												
			end
		end

		end


																			-- ************************************************
																			-- ***		    startup (onetime) routine		*** 
																			-- ***	       returns widget vars				*** 
																			-- ************************************************
local function create()

	local lastUpd = 0																					-- some timestamps
	local nextCol=0	
	local nextWhite = 09 
	
	
	local colTxt = COLOR_STD																					-- some text/num colors
	local colNum = COLOR_STD
	

	
	local config = {
		txtsize = 1,																								-- 1=initial value
		txtpixel=nil,
		numitems = nil
	} 
	
	local status = {
		BlockInProgress = false,		-- request all items
		ItemInProgress = false,			-- request dedicated item active?
		ItemPush = false,				-- was item requested on SPort ?
		activeItem = 0,					-- dedicated item
		timeStamp1 = 0,					-- highlight new values
		flag_outd = true,				-- value display was changed to "outdated"
		baseval = {0,0},
		overflow = {0,0},				-- last overflow timestamp (ant0/1)
		lastsign = {true,true}				-- last value was positive(ant0/1)
		}
															-- ********** complete set of SPORT items which could be monitored, "config="..initial values
	local stats = {				
		{name=txtFields[13][lan], 	d_item=0x00FF,	kind="Number",	SPortdefault=0x00FF	,config=true,	index = 1			},			-- 13 data 0
		{name=txtFields[14][lan], 	d_item=0x01FF,	kind="Number",	SPortdefault=0x00FF	,config=false,	index = 2			},			-- 14 data 1
		{name=txtFields[15][lan], 	d_item=0x02FF,	kind="Number",	SPortdefault=0x00FF	,config=true,	index = 3			},			-- 15 data 2
		{name=txtFields[16][lan], 	d_item=0x03FF,	kind="Number",	SPortdefault=0x00FF	,config=false,	index = 4			},			-- 16 data 3	
		{name=txtFields[17][lan], 	d_item=0x04FF,	kind="Number",	SPortdefault=0x00FF	,config=false,	index = 5			},			-- 17 data 4
		{name=txtFields[18][lan],	d_item=0x05FF,	kind="Number",	SPortdefault=0x00FF	,config=true,	index = 6			},			-- 18 data 5	
		{name=txtFields[19][lan],	d_item=0x06FF,	kind="Number",	SPortdefault=0x00FF	,config=false,	index = 7			},			-- 19 data 6
		{name=txtFields[20][lan], 	d_item=0x07FF,	kind="Number",	SPortdefault=0x00FF	,config=true,	index = 8			},			-- 20 data 7
		{name=txtFields[21][lan], 	d_item=0x08FF,	kind="Choice",	options={{"V1 FC", 0}, {"V1 EU", 1}, {"V2 FC", 2}, {"V2 EU"	, 3}},											SPortdefault=0x00FF	,config=nil,	index = 9	},			-- 21 data 8
		{name=txtFields[22][lan], 	d_item=0x09FF,	kind="Choice",	options={{"D8", 1}, {"X8R/X6R", 2}, {"X4R", 3}, {"Rx8Rpro", 4}, {"Rx8R", 5}, {"Rx4R/Rx6R", 6}		},	SPortdefault=0x00FF	,config=nil,	index = 10		},			-- 22 data 9
		{name=txtFields[23][lan], 	d_item=0x0AFF,	kind="Number",	SPortdefault=0x00FF	,config=false,	disable=false,	index = 11			},			-- 23 data10
		{name=txtFields[24][lan], 	d_item=0x0BFF,	kind="Number",	SPortdefault=0x00FF	,config=false,	disable=false,	index = 12			},			-- 24 data11
	}
 
															-- ********** net set of SPORT items which are configured to be monitored 
	local callItem= {}
	for i = 1,20 do											-- init array, max 20 items
		callItem[i]= {name="", d_item=nil, kind=nil, index=nil, sport=nil, val=0}		
	end
	sensor={} 																		-- SPORT
	sensor = sport.getSensor({appId=APP_ID});
	--print("sensor state:",sensor:idle())
	--sensor:idle(false)
	
  return{stats=stats, callItem=callItem, config=config, sensor=sensor, fontsize = "FONT_STD", lastUpd=lastUpd, status=status,nextCol=nextCol, nextWhite=nextWhite, colTxt=colTxt, colNum=colNum}
end


																			-- ************************************************
																			-- ***		     configure widget				*** 
																			-- ************************************************
local function configure(widget)
	line = form.addLine(formtxt[1].name)
	local field = form.addChoiceField(line, nil, {{"XS", 0}, {"S", 1}, {"M", 2}, {"L", 3}, {"XL", 4}}, function() return widget.config.txtsize end, function(value) widget.config.txtsize = value end)

																			-- on/off statistic items
	for index = 1, #widget.stats do
		line = form.addLine(widget.stats[index].name)
		local field = createBooleanField(widget, line, index)
	end
	
end

																			-- ************************************************
																			-- ***		     "background loop"				*** 
																			-- ************************************************

local function wakeup(widget)


	if getTime() > widget.lastUpd + UPD_Interval then						-- detect new startpoint for block requests
		widget.lastUpd = getTime()											-- init vars
		widget.status.BlockInProgress = true								-- block request is active
		widget.status.activeItem = 1										-- start with first item
		widget.status.ItemPush = false										-- until now no request was pushed

	end
	if widget.status.BlockInProgress then										-- check if "all items request" = block request is active
		refreshStats(widget)
	elseif getTime() > widget.status.timeStamp1 and widget.flag_outd  then			--"inbetween" action: highlight new values
				widget.flag_outd = false
				widget.colNum = COLOR_STD 											-- signaling "oudated" values 
				--widget.colNum = COLOR_COL1
				lcd.invalidate()
				--print("Go White")
				--paint(widget)		
	end
end




																			-- ************************************************
																			-- ***		     write widget config 	   		*** 
																			-- ************************************************
local function write(widget)

	if debug7 then print("*********   write tele config **********") end
	
	widget.config.numItems=num	
	storage.write("txtsize", widget.config.txtsize)
	widget.fontsize	= evalFontsize(widget.config.txtsize)
	widget.txtpixel = evalPixel(widget.config.txtsize)	
	
	local num =0
	for index = 1,#widget.stats do
		storage.write("stat_val"..tostring(index), widget.stats[index].config)
		if widget.stats[index].config == true then 
			num=num+1 
			widget.callItem[num].name	= widget.stats[index].name
			widget.callItem[num].d_item	= widget.stats[index].d_item
			widget.callItem[num].sport	= widget.stats[index].sport	
			widget.callItem[num].index	= widget.stats[index].index	
			widget.callItem[num].kind	= widget.stats[index].kind			
		end
	end
	widget.config.numItems=num

end

																			-- ************************************************
																			-- ***		     read widget config 	   		*** 
																			-- ************************************************
local function read(widget)


	--name(widget)
	widget.config.txtsize =storage.read("txtsize")									-- fontsize
	widget.fontsize	= evalFontsize(widget.config.txtsize)
	widget.txtpixel = evalPixel(widget.config.txtsize)	
	
	local num =0																	-- on/off Stat items
	for index = 1,#widget.stats do
		widget.stats[index].config=storage.read("stat_val"..tostring(index))
		if widget.stats[index].config == true then 
			num=num+1 
			widget.callItem[num].name	= widget.stats[index].name
			widget.callItem[num].d_item	= widget.stats[index].d_item
			widget.callItem[num].sport	= widget.stats[index].sport
			widget.callItem[num].index	= widget.stats[index].index	
			widget.callItem[num].kind	= widget.stats[index].kind
		end

	end
	widget.config.numItems=num														-- you want to know number of items to be displayed !
	
end



																			-- ************************************************
																			-- ***		     monitor events		 	   		*** 
																			-- ************************************************
local function event(widget, category, value, x, y)
	if debug0 then print("Event received:", category, value, x, y) end	
	if category == EVT_KEY and value == KEY_EXIT_BREAK then
				print("BREAK")
				--widget.sensor:idle(false)
	end
	return false
end
																			-- ************************************************
																			-- ***		     init widget		 	   		*** 
																			-- ************************************************
local function init()
 system.registerWidget({key="unow02", name=name, create=create, paint = paint, wakeup=wakeup, configure=configure, event=event ,  read=read, write=write})
end

return {init=init}