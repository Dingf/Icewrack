--[[
    Icewrack Difficulties
	
	EASY
	  *1000 Starting Gold
	  *0% Friendly Fire
	  *NPCs have 1.0 AAM think rate
	  *Characters will revive after combat instead of dying permanently (TODO)
	  *Players have 25% all resistances (TODO)
	  *Players have 50% increased healing effectiveness (TODO)
	  *Players deal 25% increased damage (TODO)
	
	NORMAL
	  *500 Starting Gold
	  *50% Friendly Fire
	  *NPCs have 0.25 AAM think rate
	  *Characters will revive after combat instead of dying permanently (TODO)
	
	HARD
	  *250 Starting Gold
	  *100% Friendly Fire
	  *NPCs have 0.1 AAM think rate
	  *Improved NPC tactics (TODO)
	  *Additional spawns which exist only in Hard/Unthaw difficulty (TODO)
	  *Experience gain reduced by 25% (TODO)	--Note that this is to accomodate for the additional spawns, so there will be 4/3 times as many mobs
	  *Threat decays at a rate of .5% every 0.1s
	
	UNTHAW
	  *100 Starting Gold
	  *100% Friendly Fire
	  *NPCs have 0.03 AAM think rate
	  *Improved NPC tactics (TODO)
	  *Additional spawns which exist only in Unthaw difficulty (TODO)
	  *Experience gain reduced by 50% (TODO)	--Note that this is to accomodate for the additional spawns, so there will be 2 times as many mobs
	  *Party members can be shattered
	  *You may only save at an expedition base camp; quicksave/load is disabled (TODO)
	  *Threat decays at a rate of 1% every 0.1s
]]

IW_DIFFICULTY_EASY = 0
IW_DIFFICULTY_NORMAL = 1
IW_DIFFICULTY_HARD = 2
IW_DIFFICULTY_UNTHAW = 3

stFriendlyFireMultipliers =
{
	[IW_DIFFICULTY_EASY] = 0.0,
	[IW_DIFFICULTY_NORMAL] = 0.5, 
	[IW_DIFFICULTY_HARD] = 1.0,
	[IW_DIFFICULTY_UNTHAW] = 1.0,
}

stAAMNPCThinkRates =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 0.5,
	[IW_DIFFICULTY_HARD] = 0.25,
	[IW_DIFFICULTY_UNTHAW] = 0.1,
}

stNPCDetectionTime =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 3.0,
	[IW_DIFFICULTY_HARD] = 5.0,
	[IW_DIFFICULTY_UNTHAW] = 10.0
}

stNPCThreatDecayRate =
{
	[IW_DIFFICULTY_EASY] = 1.0,
	[IW_DIFFICULTY_NORMAL] = 1.0,
	[IW_DIFFICULTY_HARD] = 0.995,
	[IW_DIFFICULTY_UNTHAW] = 0.99,
}