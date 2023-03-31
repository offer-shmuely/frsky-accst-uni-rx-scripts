																								--[[
###################################################################################
#######														#######
#######		    				"UNI Activate"						#######
#######	  		an ETHOS lua tool to configure UNI-ACCST Receivers		#######
#######														#######
#######	    		a Rx Firmware Project mainly driven by				#######
#######			   Mike Blandfort, Engel Modellbau 					#######
#######														#######
#######														#######
#######														#######
#######	 Rev 0.80												#######
#######	 21 Oct 2022											#######
#######	 coded by Udo Nowakowski									#######
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
		
		0.80	221021	1st roll out
		1.0  221104    tests OK
	
*************************************************************************************  								]]

local runOnce = true


local txlan
  	if system.getLocale() =="de" then
		txlan = 1
--  elseif locale == "fr" then txlan = 3					-- to be expanded
	else
		txlan = 2 								-- not supported language or en, so has to be "en" 
	end


local translations = {en="UNI-Activate 1.0"}

local function name(widget)						-- name script
  local locale = system.getLocale()
  	if locale =="de" then
		txlan = 1
--  elseif locale == "fr" then txlan = 3		-			- to be expanded
	else
		txlan = 2 								-- not supported language or en, so has to be "en" 
	end
  return translations[locale] or translations["en"]
end


-- constants


local SPORTtimeout <const>	= 1.3		--  timeout for sport push (sec)
local debug0 <const> 		= false			-- debug level 0, basic
local debug1 <const> 		= false			-- monitor check for poll
local debug2 <const> 		= true			-- monitor poll	
--ocal debug2 <const> 		= false			-- monitor poll	
local debug3 <const> 		= false			-- set variable
local debug4 <const> 		= false			-- get variable
local debug5 <const> 		= false			-- monitor UID finished
local debug6 <const> 		= false			-- true
local debug7 <const> 		= true			-- send to rx

local PageMaxValue  <const> 	= 1			-- max allowed pages

-- index names > widget.RxField entries (better human reading)

local TxID  <const> 		= 0x17				-- txid used by sport
local APP_ID <const>		= 0x0C20				-- classic Rx type (Sx=0x0C30)
local SENS_phyID <const>	= 0xBA

-- index names > widget.RxField entries (better human reading)
local RXuid <const> 		= 1
local RxStatus <const> 	= 2
local uniCode <const> 	= 3
local VALIDATION <const> 	= 4
local Save <const> 		= 5

-- dItem pointer in rxItem array
local BYTES1 <const> 		= 1
local BYTES2 <const> 		= 2
local BYTES3 <const> 		= 3
local LOCK <const> 		= 4


local IDLE <const>  		= 0
local POLL <const>  		= 1
local READ <const>  		= 2
local SENDRxMIN <const> 	= 101
local SENDRxITM3 <const> 	= 103
local SENDRxMAX <const> 	= 104

local PREFIX1 <const> 	= "           "	-- used by some txt fields to shift chars
local CodeSTD <const> 	= "000000"		-- Standard Code at begin
--local CodeSTD <const> 	= "DE72F9"

local frame = {}							-- Sport frame data items
local fields = {}							-- active formfield array

local SPLASHTIME = 3						-- intro duration in sec
local bit_mp = "engelmt.bmp"				-- later splash screen

local formPage = {}						-- form layout (simple line definitions by pointers, use this to dsign a formsheet page !)
local parameters = {}						-- raw array to built formsheet 
local flagWrite = false					-- used to control handler in case of save button was pressed
local updateForm = true					--used in paint to refresh formsheet


local function getTranlations()
	local Formline_name = {
	--		1=DE					2=EN
		{"Rx Kennung",		"RX unique ID"		},
		{"RX-UNI Status",	"RX-UNI status"		},
		{"Freischalt Code",	"Enter Code here:"	},
		{"Code Prüfung",	"Input validation"	},
		{"Rx Freischalten",	"Store Code into Rx"	}
	}
	
	local trans = {}
		trans.buttonStore  =	{"Code senden",				"Send Code to Rx"		}
		trans.rxReading  =	{"  Auslesen Rx",			"  Request Rx"			}
		trans.codewait =		{"warte auf Eingabe",		"waiting for Input"		}
		trans.codevalid =	{"Syntax OK",				"Syntax OK"				}	
		trans.codeInval =	{"falsche Eingabe",			"invalid Input"		}
		trans.rxLocked =		{"gesperrt",				"locked"				}
		trans.rxUnlocked =	{"Rx freigeschaltet",		"Active"				}
		
	return Formline_name,trans
end

local RowName,txt =  getTranlations()
--RowName = dofile("lang.lua")												-- get language file		-- initialize (1.3.3 >> ethos bug, load from wrong directory, to be investigated !)




-- 		"generic" form  array ; a bunch of possible formlines which could be spread over several form pages; ignore "compatibility" columns
-- 		line name (form)				type of field				field:enable	"editable" value	default value at start							compatibility			index		

local FormLine = {														
		{name= RowName[1][txlan],	kind="TextStat",		write_=1,	value= nil,		default="    XXXX XXXX XXXX"	,			disable=false,	index = RXuid	},		
		{name= RowName[2][txlan],	kind="TextStat",		write_=1,	value= nil,		default=PREFIX1   .. txt.rxReading[txlan],		disable=false,	index = RxStatus	},
		{name= RowName[3][txlan],	kind="TextEdit",		write_=1,	value= nil,		default=CodeSTD 	,							disable=false,	index = uniCode	},			
		{name= RowName[4][txlan],	kind="TextStat",		write_=1,	value= nil,		default= PREFIX1  .. txt.codewait[txlan],		disable=false,	index = VALIDATION},
		{name= RowName[5][txlan],	kind="TxtButton",		write_=1,	value= nil,		default="SAVE"	,							disable=false,	index = Save 		}
	}


-- here we define the "real" pages
-- >> only one page
local formPage = {}
  formPage[1] = {						-- form page1
	{pointer =	RXuid		},		-- read UID
	{pointer =	RxStatus	},		-- reading from rx ?
	{pointer =	uniCode		},		-- enterCode
	{pointer =	VALIDATION	},		-- parsing code result
	{pointer =	Save}				-- Save Code
	}
	

																			-- ************************************************
																			-- *****   workaround missing bit32 lib     *******
																			-- ************************************************
local function xband(rawdata)
		local dataAdress  = rawdata&0x00FF
		local x = math.floor((rawdata-dataAdress)/256)
		return(x)
end

local function bitband_FF(value)
	value = value&0x00FF
	return value
end

local function bitband_FFFF(value)
	value = value&0xFFFF
	return value
end
																			-- ************************************************
																			-- *****   		workaround get time     	*******
																			-- ************************************************
local function getTime()
  return os.clock()		 -- 1/100th resolution
end


local function wait(pause)
	local endTime = getTime()+pause 
	repeat
	until getTime() > endTime
end


																			-- *****************************************************************
																			-- ***********  evaluate FormLine-array  related index from line
																			-- ***********  needed  for write enabled fields
																			-- *****************************************************************
local function rxIndex(parameter)											
	local rxPointer =0
	local j=0
	for j = 1,#parameter do
		if parameter[1] == RowName[j][txlan] then	rxPointer = j end
	end
	return(rxPointer)
end
																			-- *****************************************************************
																			-- ***********  prepare widget to show a splash screen, not implemented yet
																			-- *****************************************************************

local function splash(widget)

		if not(widget.intro.bmp_flag)then			--if bmp never was shown:
			widget.intro.bmp = lcd.loadBitmap(bit_mp)	
			widget.intro.bmp_flag = true			
		end
		local bmp = widget.intro.bmp
		local lcd_w, lcd_h = lcd.getWindowSize()
		local bitmp_w = Bitmap.width(bmp)
		local bitmp_h = Bitmap.height(bmp)		
		local scale = bitmp_w/lcd_w
		local heightY = bitmp_h/scale
		local posY = (lcd_h-heightY)/2
		lcd.drawBitmap(0, posY, bmp, lcd_w, heightY)							-- >> paint image
end



local function runIntro(widget)
		if getTime() > widget.intro.startTime +SPLASHTIME then							--check within intro time, if not:
			print("END INTRO")												-- >> finish intro
			widget.intro.active = false
			updateForm  = true
		end
end
	



																			-- *****************************************************************
																			-- ***********  function called in in order to get new value in form
																			-- *****************************************************************
local function getValue(parameter)
	local rxPointer = rxIndex(parameter)
																				-- standard handling
		if parameter[4] == nil then												-- if value = nil then default
			if debug4 then print ("get returns default") end
			return FormLine[rxPointer].default			
		else
			if debug4 then print ("get returns",FormLine[rxPointer].value) end
			return FormLine[rxPointer].value
		end							

end


																			-- ************************************************
																			-- ***		        create new form     		*** 
																			-- ***            Input: parameters array		***
																			-- ***            Output: fields array			***
																			-- ************************************************

local function refreshPage()
	local rxPointer
	local parameter ={}	
	for i=0,20 do																		-- init fields array
		fields[i]=nil
	end
	
	form.clear()
	for index = 1, #parameters do	
		parameter = parameters[index]													-- get parameters "line"
		local line = form.addLine(parameter[1])											-- add empty lineinto form
		local field = parameter[2](line, parameter)										-- create field entry using corresponding method
		fields[#fields + 1] = field	

	end
	return(true)
end



																			-- ********************************************************************
																			-- ***		  function called in case new value set in form	***   
																			-- ***		        by using modifications array       		***																			
																			-- ***		            returns form Value      				***
																			-- ********************************************************************


local function setValue(parameter, value)													-- corresponding MB "changesetup" function
	local newValue
	local newFormValue
	local rxPointer = rxIndex(parameter)
	
	if debug3 then print("POINTER (set)",rxPointer)end
		FormLine[rxPointer].value = value												-- cache value in case of page up/dwn
		if rxPointer == uniCode then
			local len =string.len(value)
			if  not(len==6)   or  (string.match( value, "^%x%x%x%x%x%x$" ) == nil) then
				if debug3 then print("invalid code")end
				--newFormValue = "AAAAAA"
				newFormValue = value
				parameters[VALIDATION ][3] = PREFIX1..txt.codeInval[txlan]	
				parameter[4] = newFormValue
				updateForm = true

			else
				parameters[VALIDATION ][3] = PREFIX1..txt.codevalid[txlan]
				parameter[4]=value	
				FormLine[uniCode ].value = value				
				if debug3 then print ("Code OK",value) end		
				updateForm = true				
			end		
		elseif rxPointer == Save then
			flagWrite = true
			if debug3 then print ("press save detected",value) end		
	end		
	
	return(FormLine[rxPointer].value)
end

																			-- ************************************************
																			-- ***		    create new form line   	*** 
																			-- ***         return new "field line"		***
																			-- ************************************************
															
local function createNumberField(line, parameter)
	local field = form.addNumberField(line, nil, parameter[7], parameter[8], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
	field:enableInstantChange(false)
	if parameter[5] ~= 0 then 									-- if write enabled >>
		field:enable(true)
	else
		field:enable(false)
	end
	return field
end



local function createBooleanField(line, parameter)
	local field = form.addBooleanField(line, nil, function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
	if parameter[5] ~= 0  then 									-- if write enabled >>
		field:enable(true)
	else
		field:enable(false)
	end
	return field
end



local function createChoiceField(line, parameter)
   local field = form.addChoiceField(line, nil, parameter[7], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
	if parameter[5] ~= 0  then 									-- if write enabled >>
		field:enable(true)
	else
		field:enable(false)
	end
  return field
end



local function createTextButton(line, parameter)
 -- local field = form.addTextButton(line, nil, parameter[4], function() return setValue(parameter, 0) end)
  local field = form.addTextButton(line, nil, "Save", function() return setValue(parameter, "Save") end)
  return field
end

local function createTextEdit(line,parameter,inx)
  local field = form.addTextField(line, nil,  function() return parameter[4] end, function(newValue) setValue(parameter, newValue) end)
  return field
end

local function createTextStat(line,parameter,inx)
	local txt = parameter[3]
	field = form.addStaticText(line, nil,txt,RIGHT)
  return field
end





																			-- ************************************************
																			-- ***		       "wrapper" function     	*** 
																			-- ***           inspired by "Servo script"	***
																			-- ***          builts an array "parameters"	***
																			-- ***          sourced by FormLine definitions***
																			-- ************************************************



local function built_para(Fields,PageActual)						-- wrapper: transform simple FormLine description into page dependent "parameters" array including form class parameters 
  parameters = {}													-- clear artefacts

  for index = 1, #formPage[PageActual] do
	local kind 	= Fields[formPage[PageActual][index].pointer].kind
	local name	= Fields[formPage[PageActual][index].pointer].name
	local dItem	= Fields[formPage[PageActual][index].pointer].d_item
	local value 	= Fields[formPage[PageActual][index].pointer].default
	
	if kind == "Number" then
		parameters[index] =	{name,	createNumberField,	dItem,	nil,Fields[formPage[PageActual][index].pointer].write_	,Fields[formPage[PageActual][index].pointer].disable	,	Fields[formPage[PageActual][index].pointer].minimum,		Fields[formPage[PageActual][index].pointer].maximum}

	elseif kind == "Choice" then
		parameters[index] =	{name,	createChoiceField,	dItem,	Fields[formPage[PageActual][index].pointer].value ,Fields[formPage[PageActual][index].pointer].write_	,Fields[formPage[PageActual][index].pointer].disable	,	Fields[formPage[PageActual][index].pointer].options}	

	elseif kind == "Boolean" then
		parameters[index] =	{name,	createBooleanField,	dItem,	Fields[formPage[PageActual][index].pointer].value,Fields[formPage[PageActual][index].pointer].write_	,Fields[formPage[PageActual][index].pointer].disable	,	Fields[formPage[PageActual][index].pointer].options}	

	elseif kind == "Channel" then
		parameters[index] =	{"Ch "..tostring(formPage[PageActual][index].chNum),	createChannelField,	dItem,	nil,Fields[formPage[PageActual][index].pointer].write_	,widget.Fields[formPage[PageActual][index].pointer].disable		}	

	elseif kind == "TxtButton" then	
			parameters[index] =	{name,	createTextButton,	dItem,	value,"dummy"}	
			
	elseif kind == "TextStat" then
		parameters[index] =	{name,	createTextStat,	value}
		
	elseif kind == "TextEdit" then
		parameters[index] =	{name,	createTextEdit,	dItem,	value}


	end
  end

end

																			-- ************************************************
																			-- ***		        main routine paint  	*** 
																			-- ************************************************
local function paint(widget)

	if widget.intro.active  then													-- prep for splash screen / intro
		splash(widget)	
	else
		if updateForm then
			print("finished print new form")	-- new page ?
			if refreshPage() == false then													-- channel mapping disabled				-- if not, dependencies encountert, so no channel mapping
				widget.var.PageMax = 2																-- disable mapping pages
				if PageLast == 1 then														-- refresh
					widget.var.PageActual =2														
				else
					widget.var.PageActual = 1
				end
				refreshPage()															-- built next page
			end
		end
		updateForm = false																-- reset update flag
		if debug0 then print("finished print new form") end
	end
end





local function get_sens()
	sensor={} 																	-- SPORT sensor
	sensor = sport.getSensor({module=0, band=0, physId=SENS_phyID ,  rxIdx=0, appId=APP_ID})
	--sensor = sport.getSensor({module=0, band=0 , appId=APP_ID})
	sensor:idle()
	--runOnce = true
end


																			-- ************************************************
																			-- ***		        start routine 	   	*** 
																			-- ************************************************
local function create()
	updateForm 		= false														-- enforce a new form on 1st start (fsalse = splash screen)
	
	local var = {}																-- some widget vars
		var.PageMax 			= PageMaxValue										-- number of pages (formsheets)
		var.PageActual 		= 1													-- page which is displayed
		var.PageNext		= var.PageActual										-- page which should be displayed next
		var.PageLast		= 1													-- last shown display
		
	local activate = {}															-- widget specific "global" vars
		--activate.telemetryPopTimeout = 0
		activate.readRequest = true												-- reading initiated		
		activate.requestInProgress = false										-- waiting for right for frame
		activate.pollRequest = true												-- polling initiated
		activate.lastPoll = getTime()-100										-- timestamp last poll (preset to activate polling at start)
	
															
	local intro = {}
		intro.active = true	
		intro.startTime = getTime()
		intro.bmp_flag= false
		intro.bmp = nil
	
	local rxItem = {
		{ditem = 0x0DFF, pollRequest = false, readStatus = 0, value = 0, timeOut = SPORTtimeout, pointer= BYTES1},
		{ditem = 0x0EFF, pollRequest = false, readStatus = 0, value = 0, timeOut = SPORTtimeout, pointer= BYTES2},
		{ditem = 0x0FFF, pollRequest = false, readStatus = 0, value = 0, timeOut = SPORTtimeout, pointer= BYTES3},
		{ditem = 0x00EB, pollRequest = false, readStatus = 0, value = 0, timeOut = SPORTtimeout, pointer= LOCK}
		}	
	
	local activeReq = {} 
		activeReq.dItem= 0
		activeReq. pollRequest = nil
		activeReq.readStatus= nil		
		activeReq.value = 0
		activeReq.timeOut = 0
		activeReq.pointer = 0
		
	local errCounter 	= 0														-- counter during write sequence
	local pollRequest 	= false													-- flag new poll request
	local readRequest 	= false													-- flag new read request
	local handler		= IDLE													-- handler
	local UID 			= false													-- Rx UID read finished ?

	if updateForm then															-- disable splash functionality
		intro.active = false	
	end

	
	 built_para(FormLine,1)														-- built form page
		
 	get_sens()
		
	return {sensor=sensor,intro = intro, rxItem = rxItem, activeReq=activeReq, errCounter = errCounter, var = var, txt=txt, UID = UID, handler = handler, readRequest = readRequest, pollRequest = pollRequest,activate = activate }
end




local function dItemVal(value)
	local datItem = bitband_FFFF(value)
	local tmp = bitband_FF(datItem)
	
	if  tmp == 0xEB then													-- exception for 2 Byte dItem											-- exception for 2 Byte dItem
		if debug2 then print("found eb",string.format("%04X",datItem) ) end
		datItem = tmp
		value = bitband_FF((value-tmp)/(256))
		if debug2 then print("output",string.format("%02X",datItem),string.format("%02X",value) ) end
	else																-- typical 4Byte dItem
		value = bitband_FFFF((value-datItem)/(256*256))
	end
	return value,datItem
end


																			-- *************************************************************
																			-- ************   		SPORT queue handling 	    *********
																			-- *************************************************************

local function sportTelemetryPop(widget)
  local frame = widget.sensor:popFrame()
  if frame == nil then
    return nil, nil, nil, nil
  end
  return frame:physId(), frame:primId(), frame:appId(), frame:value()
end




local function check4PollItem(widget)

									
	if not (widget.UID) then											-- check which UID-item must be polled
			local j =0																											
			repeat			
				j=j+1
				--print("filter DI pre ifstate",j,widget.rxItem[j].readStatus ,string.format("%04X",widget.rxItem[j].ditem) )
				if  widget.rxItem[j].readStatus == 0 and not(widget.rxItem[j].pollRequest)  then										-- search for uid data never read and item is not in "wait after poll"
					if debug1 then print("prep 4 poll",j,widget.rxItem[j].readStatus ,string.format("%04X",widget.rxItem[j].ditem) ) end
					widget.rxItem[j].pollRequest 	= true									
					widget.activeReq.dItem			= widget.rxItem[j].ditem														-- prepare temp. DataItem
					widget.activeReq.pointer 		= j

					widget.handler = POLL																							-- switch mode to "poll item"
					widget.readRequest = false
					widget.pollRequest = true
					
				end
				
				 if j == (#widget.rxItem -1) and not(widget.pollRequest) then 														-- check if UID is complete
					widget.UID = true																							-- set UID-Reading to finished
					parameters[RXuid ][3] ="           ".. string.format("%04X",widget.rxItem[BYTES1].value) .. "  " .. string.format("%04X",widget.rxItem[BYTES2].value) .. "  " .. string.format("%04X",widget.rxItem[BYTES3].value )
					if debug5 then print("finished UID",parameters[RXuid ][3]) end
					updateForm = true
				end			
			until (widget.pollRequest or widget.UID or j== #widget.rxItem )
			
	elseif widget.rxItem[#widget.rxItem].readStatus==0 then				
			local j = #widget.rxItem
			if debug1 then print("prep 4 poll",j,widget.rxItem[j].readStatus ,string.format("%04X",widget.rxItem[j].ditem) ) end					-- check for poll lock-status request
				widget.rxItem[j].pollRequest = true																				-- flag dataItem
				
				widget.activeReq.dItem = widget.rxItem[j].ditem																	-- prepare temp. DataItem
				widget.activeReq.pointer = j
				
				widget.handler = POLL																								-- switch mode to "poll item"
				widget.readRequest = false
				widget.pollRequest = true
				
	elseif flagWrite then
			flagWrite = false
			print("execute SAVE")
			widget.handler = SENDRxITM3
		
	end

end

local function pollItem(widget)
	local dItem = widget.activeReq.dItem
	local handler = READ 																			-- next step would be read
	if widget.sensor:pushFrame({primId=0x30, band=0, physId=SENS_phyID ,  rxIdx=0, appId=APP_ID,value= dItem }) == true then				-- send read request
--	if widget.sensor:pushFrame({primId=0x30, band=0 , appId=APP_ID,value= dItem }) == true then	
		--timeOut = getTime() + SPORTtimeout
		widget.activeReq.timeOut=getTime() + SPORTtimeout
		if debug2 then print("polled Item :    ",string.format("%04X",dItem),getTime(),widget.activeReq.timeOut) end																										-- switch mode to "read item"
		widget.pollRequest = false
		widget.readRequest = true	
	else
		handler = 0
		if debug2 then print(" poll returned false ",string.format("%04X",dItem)) end
	end

	widget.activate.lastPoll = getTime() 
	if debug2 then print("  poll returned",handler) end
	return handler
end




local function readPolledItem(widget)

local handler = 2																				-- standard mode: loop until data was read
	frame = widget.sensor:popFrame()
	if frame ~= nil then
		local value = frame:value()						
		local appl_id=frame:appId()						
				
		local data_Item
		value, data_Item = dItemVal(value)
		--print(" got DataItem:"," ",string.format("%04X",data_Item) ,getTime()," ","    got Value", string.format("%04X",value))
		if debug6 then print(" got DataItem:"," ",string.format("%04X",data_Item) ,getTime()," ","    got Value", string.format("%04X",value),"phy:",frame:physId()) end
		if data_Item == widget.activeReq.dItem then											-- hurra, received dataItem = requested item ?:
			if debug2 then print(" got DataItem:"," ",string.format("%04X",data_Item) ,getTime()," ","    got Value", string.format("%04X",value),"phy: "..frame:physId()) end
			widget.rxItem[widget.activeReq.pointer].value  		= value						-- store value
			widget.rxItem[widget.activeReq.pointer].readStatus  	= 1							-- flag "read was successful"
			widget.rxItem[widget.activeReq.pointer].pollRequest  = false						-- disable poll request	

			handler = 0																-- switch mode back to idle
			widget.activeReq.dItem= 0														-- reset active item
			widget.activeReq.value = 0
			widget.activeReq.pointer = 0
			widget.activeReq.timeOut = 0

			if data_Item  == 0xEB then															-- exception handler lock status
				print("lock value received",value)
				if value == 0 then
					parameters[RxStatus  ][3] = "            " .. txt.rxLocked[txlan]			-- change statusinfo text
				else
					parameters[RxStatus ][3] = "            " .. txt.rxUnlocked[txlan]
				end
				updateForm = true
			end
			return handler																	-- exit readloop
		end												
	end
	
	
	if getTime() > widget.activeReq.timeOut then															-- timeout ?  >> reset request
		if debug2 then print(" readLoop  --- SPort timeout  --------",widget.activeReq.dItem ) end
		widget.rxItem[widget.activeReq.pointer].pollRequest  = false
		handler = 0																-- switch mode back to idle																		-- switch mode back to idle																-- switch mode back to idle
	end	
	return handler

end


local function write_Unlock(unlockCode,widget)
		local SendingCode = widget.handler
		local Code = {}
		local UpdateValue
		local result = nil

		for i = 0,string.len(unlockCode)-1 do
			local tmp = string.sub(unlockCode,i+1,i+1)
			Code[i] =tonumber(tmp,16 )						-- get one value out of Hex-unlock string
			if debug7 then print("CODE",Code[i])  end
		end
		
		if widget.errCounter < 10 then
	 		if SendingCode == 103 then
				UpdateValue = Code[0] + Code[1] * 256
				UpdateValue = UpdateValue * 65536
				UpdateValue = UpdateValue + 0xEB
				result = widget.sensor:pushFrame({primId=0x31,  band=0, physId=SENS_phyID ,  rxIdx=0, appId=APP_ID,value= UpdateValue})
				if result ~= 0 then
					SendingCode = 102
					widget.errCounter = 0									-- reset counter			
					if debug7 then print("lock1",UpdateValue) end
				else
					widget.errCounter = widget.errCounter+1
				end
 	 		elseif SendingCode == 102 then
				UpdateValue = Code[2] + Code[3] * 256
				UpdateValue = UpdateValue * 65536
				UpdateValue = UpdateValue + 0x1EB
				result = widget.sensor:pushFrame({primId=0x31, band=0, physId=SENS_phyID ,  rxIdx=0, appId=APP_ID,value= UpdateValue})
				if result ~= 0 then
					SendingCode = 101
					widget.errCounter = 0									-- reset counter	
					if debug7 then print("lock2",UpdateValue) end
				else
					widget.errCounter = widget.errCounter+1
				end
 	 		elseif SendingCode == 101 then
				UpdateValue = Code[4] + Code[5] * 256
				UpdateValue = UpdateValue * 65536
				UpdateValue = UpdateValue + 0x2EB
				result = widget.sensor:pushFrame({primId=0x31,  band=0 , physId=SENS_phyID,  rxIdx=0, appId=APP_ID,value= UpdateValue})
				if result ~= 0 then											-- init read status item
					if debug7 then print("lock3",UpdateValue) end
					SendingCode = 1
					widget.errCounter = 0									-- reset counter	
					local j = #widget.rxItem
					widget.rxItem[j].pollRequest = true																				-- flag dataItem "lock status"  >> to read
				
					widget.activeReq.dItem = widget.rxItem[j].ditem																	-- prepare temp. DataItem
					widget.activeReq.pointer = j
				
					widget.readRequest = false
					widget.pollRequest = true
				else
					widget.errCounter = widget.errCounter+1	
				end
			end
		else
			print("too much send errors")
			SendingCode = 0
		end
			
		return SendingCode
end


																			-- ************************************************
																			-- ***		     "background" routine 	   		*** 
																			-- ************************************************

local function wakeup(widget)
--if  runOnce then
--	get_sens()
--end
	if widget.intro.active then 
		runIntro(widget)
	else

		if widget.handler == IDLE then																				-- idle mode
			check4PollItem(widget)																				-- check if an item must be polled

		elseif widget.handler == POLL then																			-- if so: poll requested item
			widget.handler = pollItem(widget)	
			
		elseif widget.handler == READ then																			-- wait 4 Rx answere		
			widget.handler= readPolledItem(widget)
			
		elseif widget.handler >= SENDRxMIN and widget.handler < SENDRxMAX	 then									-- write unlock Code		
			if parameters[VALIDATION ][3] == PREFIX1..txt.codeInval[txlan]	then									-- wrong Syntax (use same strings as in setvalue !!)
				print("sorry, no code was send due to wrong syntax")
				widget.handler =  IDLE
			else
				if FormLine[uniCode].value == nil then FormLine[uniCode].value = FormLine[uniCode].default end		-- prevent nil
				widget.handler = write_Unlock(FormLine[uniCode].value ,widget)
			end	
		end
		lcd.invalidate()
	end

	
end



	
local function event(widget, category, value, x, y)
	if debug0 then print("Event received:", category, value, x, y) end
	if category == EVT_KEY and value == KEY_EXIT_BREAK then
		print("exit")
		FormLine[uniCode].value=FormLine[uniCode].default
	end
  
	if value == KEY_PAGE_UP then											--  page up button
		PageNext = widget.var.PageActual+1
			if PageNext > widget.var.PageMax then
				PageNext = 1
			end
		PageLast = widget.var.PageActual
		widget.var.PageActual = PageNext
		updateForm = true
		refreshIndex = 0
		built_para(FormLine,widget.var.PageActual)														-- built page dependent parameters array
		if debug0 then print("UP, goto next Page:",widget.var.PageActual) end
		
	elseif value == KEY_PAGE_DOWN then								    	--  page down button
		PageNext = widget.var.PageActual-1
		if PageNext == 0 then
			PageNext = widget.var.PageMax
		end
		PageLast = widget.var.PageActual
		widget.var.PageActual = PageNext
		updateForm = true
		refreshIndex = 0
		built_para(FormLine,widget.var.PageActual)														-- built page dependent parameters array
		if debug0 then print("DOWN, goto next Page:",widget.var.PageActual) end
	end

  
	return false
end



local icon = lcd.loadMask("main.png")

local function init()
	system.registerSystemTool({name=name, icon=icon, create=create, paint = paint,  wakeup=wakeup, event=event})
end

return {init=init}