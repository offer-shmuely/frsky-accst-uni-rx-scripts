-- language file for Uniaccst Rx settings
-- udo nowakowski
-- 8.april.2022

local txt_Fields = {

--		de								en

{"CH1-8 / CH9-16",				"CH1-8 / CH9-16"			}, -- 1
{"dummy SBUS-ch8",				"dummy SBUS-ch8"			}, -- 2
{"Servo am SBUS",				"Servo on SBUS"				}, -- 3
{"dummy D8 only",				"dummy D8 only"				}, -- 4
{"Feinabgleich: Offset", 		"Tuning offset"				}, -- 5
{"Abgleich Mittenfrequenz",		"Tuning enabled"			}, -- 6
{"Servo Framerate", 			"Rate"						}, -- 7
{"dummy CRate", 				"dummy CRate"				}, -- 8
{"indiv. Servoausgaenge",		"Enable map on PWM"			}, -- 9
{".. auch auf SBUS",			"Enable map on SBUS"		}, --10
{"Kanalzuordnung", 				"Channel mapping"			}, --11
{"SBus Polung",					"SBus non inverted"			}, --12
{"Paketverluste",		 		"Total dropped packets"		}, --13
{"CRC Fehler", 					"CRC Errors"				}, --14
{"Verluste (%)",				"Drop Percent"				}, --15
{"durchschn. Laufzeit",			"Ave Packet time"			}, --16
{"Telemetrie Resets",			"Telemetry resets"			}, --17
{"Antennen Umschaltungen",		"Antenna swaps"				}, --18
{"Telemetrie nicht gesendet",	"Telemetry not sent (times)"}, --19
{"Software Vers.", 				"Software Rev"				}, --20
{"Rx Protokoll", 				"Rx Protocol"				}, --21
{"Rx Typ", 						"Rx Type"					}, --22
{"Antenne0 (Anzahl)", 			"Antenna count[0]"			}, --23
{"Antenne1 (Anzahl)", 			"Antenna count[1]"			}, --24
{"Rx Reset",					"Rx Reset"					}  --25
}


local optionLan = {
{{{"Aus", 0}, {"freie Zuordnung", 1}},			{{"Off", 0}, {"free Choice", 1}}			},	-- map on PWM
{{{"Standard", 0}, {"nicht invertiert", 1}},	{{"standard", 0}, {"non inverted", 1}}		}	-- Sbus inverted
}

local headers = {

{"Parameter 1"	,			"Parameter 1"		},
{"Parameter 2"	,			"Parameter 2"		},
{"Kanalzuordnung 1"	,		"Channel mapping 1"	},
{"Kanalzuordnung 2"	,		"Channel mapping 2"	},
{"Kanalzuordnung 3"	,		"Channel mapping 3"	},
{"Kanalzuordnung 4"	,		"Channel mapping 4"	},
{"dedizierte Servo 18ms",	"dedicated 18ms"	}
}

return txt_Fields,optionLan,headers